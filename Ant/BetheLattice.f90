!**********************************************************
!*********************  ANT.G-2.4.1  **********************
!**********************************************************
!*                                                        *
!*  Copyright (c) by                                      *
!*                                                        *
!*  Juan Jose Palacios (1)                                *
!*  David Jacob (2)                                       *
!*  Maria Soriano (1)                                     *
!*  Angel J. Perez-Jimenez (3)                            *
!*  Emilio SanFabian (3)                                  *
!*  Jose Antonio Antonio Verges (4)                       *
!*  Enrique Louis (5)                                     *
!*                                                        *
!* (1) Departamento de Fisica de la Materia Condensada    *
!*     Universidad Autonoma de Madrid                     *      
!*     28049 Madrid (SPAIN)                               *
!* (2) Theory Department                                  *
!*     Max-Planck-Institute for Microstructure Physics    *
!*     Halle, 06120 (GERMANY)                             *
!* (3) Departamento de Quimica Fisica                     *
!*     Universidad de Alicante                            *
!*     03690 Alicante (SPAIN)                             *
!* (4) Insto. de Ciencias de Materiales de Madrid (ICMM)  *
!*     Consejo Superior de Investigacion y Ciencia (CSIC) *
!*     28049 Madrid (SPAIN)                               *
!* (5) Departamento de Fisica Aplicada                    *
!*     Universidad de Alicante                            *      
!*     03690 Alicante (SPAIN)                             *
!*                                                        *
!**********************************************************
MODULE BetheLattice
!**********************************************************
!* Module for description of the metal                    *
!* leads by means of a Bethe lattice model                *
!**********************************************************
  use ANTCommon  
  use parameters, only: Debug, DebugBethe, DebugDyson
  use util, only: PrintCMatrix
  implicit none
  save

  ! Array dimensions
  integer, parameter, private :: MaxDim = 100, MaxSh = 10, MaxDir = 12

  !*************************************
  !********** Type for shells **********
  !*************************************
  type Shell_def_t
    integer*8 :: ntypeshell
    integer*8 :: norbsinshell
  end type
  !*************************************
  !* Type for Bethe lattice parameters *
  !*************************************
  type TBetheLattice
     private   
     ! current Lead 
     integer :: LeadNo
     ! conventional atomic number of material
     integer :: AtmNo          
     ! Number of atomic orbitals 
     integer :: NAOrbs         
     ! Number of nearest neigghbours
     integer :: NNeighbs     
     ! Number of nondegenerate spin channels
     integer :: NSpin
     ! Number of electrons, number of core electrons
     integer :: NElectrons, NCore
     ! Whether to take into account overlap 
     logical :: Overlap
     ! 
     logical :: Matrix
     !
     ! Type of an atomic orbital 
     ! Key: 
     ! s = 0
     ! p_x = 1 
     ! p_y = 2
     ! p_z = 3
     ! d_{3z^2-r^2} = 4
     ! d_{xz}       = 5
     ! d_{yz}       = 6
     ! d_{x^2-y^2}  = 7
     ! d_{xy}       = 8
     ! f_{z^3}           = 9
     ! f_{xz^2}          = 10
     ! f_{yz^2}          = 11
     ! f_{xyz}           = 12
     ! f_{z(x^2-y^2)}    = 13
     ! f_{x(x^2-3y^2)}   = 14
     ! f_{y(3x^2-y^2)}   = 15

     integer, dimension(MaxDim) :: AOT 
     integer, dimension(MaxDim) :: SHT
     
     ! number of s-orbitals in atomic basis-set
     integer :: nso
     ! number of p-orbitals
     integer :: npo
     ! number of d-orbitals
     integer :: ndo
     ! number of f-orbitals
     integer :: nfo

     ! On-site energies (spin-up/down)
     real, dimension(2) :: es, ep, edd, edt, ef

     ! Inter-site hoppings (spin-up/down)
     real, dimension(2) :: sss, sps, pps, ppp, sds, pds, pdp, dds, ddp, ddd, vf
!     real, dimension(2) :: sss0, sps0, pps0, ppp0, sds0, pds0, pdp0, dds0, ddp0, ddd0, vf0

     ! Inter-site overlaps 
     real :: S_sss, S_sps, S_pps, S_ppp, S_sds, S_pds, S_pdp, S_dds, S_ddp, S_ddd, S_f
!     real :: S_sss0, S_sps0, S_pps0, S_ppp0, S_sds0, S_pds0, S_pdp0, S_dds0, S_ddp0, S_ddd0, S_f0

     ! On-site Hamiltonian
     complex*16, dimension(2,MaxDim,MaxDim)   :: H0
     ! On-site  Overlap
     complex*16, dimension(MaxDim,MaxDim)   :: S0
     ! Direction dependent inter-site hoppings
     complex*16, dimension(2,MaxDir,MaxDim,MaxDim) :: Vk
     ! Direction dependent inter-site overlaps
     complex*16, dimension(MaxDir,MaxDim,MaxDim) :: Sk
     ! Directional self energies     
     complex*16, dimension(2,MaxDir,MaxDim,MaxDim) :: Sigmak 

     ! Lower and upper bound for non-zero DOS
     real :: EMin, EMax
     ! FermiStart to search Fermi Level for each Lead (+- BiasVoltage)
     real :: FermiStart = 0.0d0
  end type TBetheLattice


  !*******************************************
  !* Bethe lattice parameters for both leads *
  !*    LeadBL(1) = left lead                *
  !*    LeadBL(2) = right lead               *
  !*******************************************
  type(TBetheLattice), dimension(2) :: LeadBL

  !**************************** 
  !* Public module procedures *
  !****************************
  ! Routine to initialize Bethe lattice
  public :: InitBetheLattice
  ! Routine to deallocate dynamic memory occupied by TBethelattice variable
  public :: CleanUpBL
  ! Access functions to read out values of some TBethelattice data
  public :: BL_AtmNo, BL_NAOrbs, BL_NNeighbs, BL_NSpin, BL_NElectrons, BL_EMin, BL_EMax

  
  !*****************************
  !* Private module procedures *
  !*****************************
  ! Solver for Dyson equation
  private :: SolveDysonBL
  ! Spin-resolved DOS of bulk atom
  private :: BulkSDOS
  ! Routine to comp. bulk Green's function 
  private :: CompGreensFunc
  ! Charge integrated up to a certain energy
  private :: TotCharge
  ! Adjusts parameters so that E_F = 0
  private :: AdjustFermi
  ! computes rotation matrix for BL direction
  private :: getRotMat
  ! Routines to read Bethe lattice parameters from file
  private :: ReadBLParameters, readline, FindKeyWord

  !******************************
  !* Internal variables used by *
  !* private function TotCharge *
  !******************************
  real, private :: ChargeOffSet 
  integer, private :: WhichLead
  real, private :: E0

  integer, parameter, private :: MaxCycle = 500

  ! Extended Hamiltonian and Overlap matrix 
  ! for cluster of BL atoms + NNN BL atoms
  integer, private :: nx
  complex*16, dimension(:,:,:), allocatable, private :: H0X
  complex*16, dimension(:,:), allocatable, private :: S0X
!$OMP  THREADPRIVATE(E0)
contains

  ! 
  ! *** Initialize Bethe lattice ***
  ! 
  subroutine InitBetheLattice( BL, LeadNo )
    use util, only: PrintCMatrix
    use cluster, only: LeadAtmNo, LeadNAOrbs, NNeigBL, vpb, NConnect
    use constants, only: c_zero, ui
    use Parameters, only : leaddos, estep, Overlap, ANT1DInp, eta
    use numeric, only:  ctrace
    use ANTCommon
     USE g09Common, ONLY: GetAN, GetNAtoms

    implicit none

    type(TBetheLattice),intent(INOUT) :: BL
    integer, intent(IN) :: LeadNo

    integer :: ispin, k, AllocErr, i, j, l, n, nso1, npo1, ndo1, nso2, npo2, ndo2, nps1, nds1, nps2, nds2, nj, nnn
    complex*16, dimension(:,:), allocatable :: temp, TR
    complex*16 :: zenergy 
    real :: energy, q, hij
    
    print *
    print *,          "-----------------------------------------------------"
    print ('(A,I1)'), " Inititalizing Bethe lattice for electrode No. ", LeadNo
    print *,          "-----------------------------------------------------"
    print *
    BL%LeadNo   = LeadNo
    BL%AtmNo    = LeadAtmNo(LeadNo)
    BL%NAOrbs   = LeadNAOrbs(LeadNo)
    BL%NNeighbs = NNeigBL(LeadNo)

    n = BL%NAOrbs
    
    call ReadBLParameters( BL )

    allocate( temp(n,n), TR(n,n), STAT = AllocErr )
    if( AllocErr /= 0 ) then
       print *, "InitBetheLattice/Program could not allocate memory for temp, TR, AOT"
       stop
    end if

    if( BL%Matrix )then
  
       ! *** Hamiltonian and overlap Matrix must be rotated
       ! *** to match standard orientation for hoppings
       ! NOT IMPLEMENTED YET

       !!norm = dsqrt(BL%Rk(1)**2+BL%Rk(2)**2+BL%Rk(3)**2)

       !!Rk1=BL%Rk(1)/norm
       !!Rk2=BL%Rk(2)/norm
       !!Rk3=BL%Rk(3)/norm
         
       !!call cmatr(n,BL%AOT,Rk1,Rk2,Rk3,TR)
       !!call inv( TRR )
     
       !!do k=1,BL%NNeighbs
       !!end do

    else
       ! *** Initializing on-site Hamiltonian H0 and overlap S0
       
       BL%H0 = c_zero
       BL%S0 = c_zero
       do i=1, n
          BL%S0(i,i) = 1.0d0
          do ispin=1,BL%NSpin
             select case( BL%AOT(i) )
             case( 0 )     
                ! s-orbital
                BL%H0( ispin, i, i )=BL%es ( ispin )
             case( 1,2,3 ) 
                ! p-orbital
                BL%H0( ispin, i, i )=BL%ep ( ispin ) 
             case( 4,7 )   
                ! d_{3z^2-r2}, d_{x2-y2} : d-doublet
                BL%H0( ispin, i, i )=BL%edd( ispin )
             case( 5,6,8 ) 
                ! d_{xz}, d_{yz}, d_{xy} : d-triplet
                BL%H0( ispin, i, i )=BL%edt( ispin )
             case( 9,10,11,12,13,14,15 )
                ! all f orbitals
                BL%H0( ispin, i, i )=BL%ef ( ispin )
             end select
          end do
       end do

       ! Initializing inter-site interaction
       BL%Vk = c_zero
       BL%Sk = c_zero
       do ispin=1, BL%NSpin
          Write(*,'(A,I2)')"BL%NNeighbs = ",BL%NNeighbs
          !if(DebugBethe)Pause
          do k=1, BL%NNeighbs
             ! *** get coupling from bethe parameters
             do i=1, n
                do j=1, n
                   if( BL%AOT(i)==0 .and.  BL%AOT(j)==0 ) then
                      BL%Vk(ispin, k, i, j) = BL%sss( ispin )
                      BL%Sk(       k, i, j) = BL%S_sss
                      !
                   elseif( BL%AOT(i)==1 .and. BL%AOT(j)==1 ) then 
                      ! px-px hopping
                      BL%Vk(ispin, k, i, j) = BL%ppp( ispin )
                      BL%Sk(       k, i, j) = BL%S_ppp
                      !
                   elseif( BL%AOT(i)==2 .and. BL%AOT(j)==2 ) then 
                      BL%Vk(ispin, k, i, j) = BL%ppp( ispin )
                      BL%Sk(       k, i, j) = BL%S_ppp
                      !
                   elseif( BL%AOT(i)==3 .and. BL%AOT(j)==3 ) then 
                      ! pz-pz hopping
                      BL%Vk(ispin, k, i, j) = BL%pps( ispin )
                      BL%Sk(       k, i, j) = BL%S_pps
                      !
                   elseif( BL%AOT(i)==4 .and. BL%AOT(j)==4 ) then 
                      ! d_{3z2-r2}-d_{3z2-r2} hopping
                      BL%Vk(ispin, k, i, j) = BL%dds( ispin )
                      BL%Sk(       k, i, j) = BL%S_dds
                      ! 
                   elseif( BL%AOT(i)==5 .and. BL%AOT(j)==5 ) then 
                      ! d_{xz}-d_{xz} hopping
                      BL%Vk(ispin, k, i, j) = BL%ddp( ispin )
                      BL%Sk(       k, i, j) = BL%S_ddp
                      !
                   elseif( BL%AOT(i)==6 .and. BL%AOT(j)==6 ) then 
                      ! d_{yz}-d_{yz} hopping
                      BL%Vk(ispin, k, i, j) = BL%ddp( ispin )
                      BL%Sk(       k, i, j) = BL%S_ddp
                      !
                   elseif( BL%AOT(i)==7 .and. BL%AOT(j)==7 ) then 
                      ! d_{x2-y2}-d_{x2-y2} hopping
                      BL%Vk(ispin, k, i, j) = BL%ddd( ispin )
                      BL%Sk(       k, i, j) = BL%S_ddd
                      !
                   elseif( BL%AOT(i)==8 .and. BL%AOT(j)==8 ) then
                      ! d_{xy}-d_{xy} hopping
                      BL%Vk(ispin, k, i, j) = BL%ddd( ispin )
                      BL%Sk(       k, i, j) = BL%S_ddd
                      !
                   elseif( BL%AOT(i)==0 .and. BL%AOT(j)==3 ) then 
                      ! s-pz hopping
                      BL%Vk(ispin, k, i, j) = BL%sps( ispin )
                      BL%Sk(       k, i, j) = BL%S_sps
                      !
                   elseif( BL%AOT(i)==3 .and. BL%AOT(j)==0 ) then 
                      ! pz-s hopping
                      BL%Vk(ispin, k, i, j) = -BL%sps( ispin )
                      BL%Sk(       k, i, j) = -BL%S_sps
                      !
                   elseif( BL%AOT(i)==0 .and. BL%AOT(j)==4 ) then 
                      ! s-d_{3z2-r2} hopping
                      BL%Vk(ispin, k, i, j) = BL%sds( ispin )
                      BL%Sk(       k, i, j) = BL%S_sds
                      ! 
                   elseif( BL%AOT(i)==4 .and. BL%AOT(j)==0 ) then 
                      ! d_{3z2-r2}-s hopping
                      BL%Vk(ispin, k, i, j) = BL%sds( ispin )
                      BL%Sk(       k, i, j) = BL%S_sds
                      !
                   elseif( BL%AOT(i)==1 .and. BL%AOT(j)==5 ) then 
                      ! px-d_{xz} hopping
                      BL%Vk(ispin, k, i, j) = BL%pdp( ispin )
                      BL%Sk(       k, i, j) = BL%S_pdp
                      !
                   elseif( BL%AOT(i)==5 .and. BL%AOT(j)==1 ) then 
                      ! d_{xz}-px hopping
                      BL%Vk(ispin, k, i, j) = -BL%pdp( ispin )
                      BL%Sk(       k, i, j) = -BL%S_pdp
                      ! 
                   elseif( BL%AOT(i)==2 .and. BL%AOT(j)==6 ) then 
                      ! py-d_{yz} hopping
                      BL%Vk(ispin, k, i, j) = BL%pdp( ispin )
                      BL%Sk(       k, i, j) = BL%S_pdp
                      !
                   elseif( BL%AOT(i)==6 .and. BL%AOT(j)==2 ) then 
                      !  d_{yz}-py hopping
                      BL%Vk(ispin, k, i, j) = -BL%pdp( ispin )
                      BL%Sk(       k, i, j) = -BL%S_pdp
                      !
                   elseif( BL%AOT(i)==3 .and. BL%AOT(j)==4 ) then 
                      ! pz-d_{3z2-r2} hopping
                      BL%Vk(ispin, k, i, j) = BL%pds( ispin )
                      BL%Sk(       k, i, j) = BL%S_pds
                      !
                   elseif( BL%AOT(i)==4 .and. BL%AOT(j)==3 ) then 
                      ! d_{3z2-r2}-pz hopping
                      BL%Vk(ispin, k, i, j) = -BL%pds( ispin )
                      BL%Sk(       k, i, j) = -BL%S_pds
                      !
                   elseif( BL%AOT(i)==9 .and. BL%AOT(j)==9 ) then 
                      ! f-f hopping
                      BL%Vk(ispin, k, i, j) = BL%vf( ispin )
                      BL%Sk(       k, i, j) = BL%S_f
                   elseif( BL%AOT(i)==10 .and. BL%AOT(j)==10 ) then 
                      ! f-f hopping
                      BL%Vk(ispin, k, i, j) = BL%vf( ispin )
                      BL%Sk(       k, i, j) = BL%S_f
                   elseif( BL%AOT(i)==11 .and. BL%AOT(j)==11 ) then 
                      ! f-f hopping
                      BL%Vk(ispin, k, i, j) = BL%vf( ispin )
                      BL%Sk(       k, i, j) = BL%S_f
                   elseif( BL%AOT(i)==12 .and. BL%AOT(j)==12 ) then 
                      ! f-f hopping
                      BL%Vk(ispin, k, i, j) = BL%vf( ispin )
                      BL%Sk(       k, i, j) = BL%S_f
                   elseif( BL%AOT(i)==13 .and. BL%AOT(j)==13 ) then 
                      ! f-f hopping
                      BL%Vk(ispin, k, i, j) = BL%vf( ispin )
                      BL%Sk(       k, i, j) = BL%S_f
                   elseif( BL%AOT(i)==14 .and. BL%AOT(j)==14 ) then 
                      ! f-f hopping
                      BL%Vk(ispin, k, i, j) = BL%vf( ispin )
                      BL%Sk(       k, i, j) = BL%S_f
                   elseif( BL%AOT(i)==15 .and. BL%AOT(j)==15 ) then 
                      ! f-f hopping
                      BL%Vk(ispin, k, i, j) = BL%vf( ispin )
                      BL%Sk(       k, i, j) = BL%S_f
                   else
                      !
                      BL%Vk(ispin, k, i, j) = 0.0d0
                      BL%Sk(k, i, j) = 0.0d0
                      !
                   endif
                   ! write(ifu_log,*)k,i,j,BL%Vk(ispin, k,i,j)
                end do
             end do
             if(DebugBethe)Write(*,'(A,I2,A,I2,A)')"BL%Vk(",ispin,",", k,", :, :) in InitBetheLattice"
             if(DebugBethe)call PrintCMatrix(BL%Vk(ispin, k, 1:n, 1:n))
             if(DebugBethe)Pause
          end do
       end do
    end if
    if(DebugBethe)then
      Write(*,'(A)')"(BL%Vk(ispin, k, 1:n, 1:n))"
      do iSpin=1,BL%NSpin
        do k=1,BL%NNeighbs
          do i=1,n
            do j=1,n
              Write(*,'(A,I2,A,I2,A,I2,A,I2,A,g15.5,A,g15.5,A)')"(",ispin,",",k,",",i,",",j,",",REAL(BL%Vk(ispin, k, i, j)),",",AIMAG(BL%Vk(ispin, k, i, j)),")"
              if(DebugBethe)pause
            end do
          end do
        end do
      end do

      Write(*,'(A)')"(BL%Sk(ispin, k, 1:n, 1:n))"
        do k=1,BL%NNeighbs
          do i=1,n
            do j=1,n
              Write(*,'(A,I2,A,I2,A,I2,A,g15.5,A,g15.5,A)')"(",k,",",i,",",j,",",REAL(BL%Sk(k, i, j)),",",AIMAG(BL%Sk(k, i, j)),")"
              if(DebugBethe)pause
            end do
          end do
        end do
    end if

    !
    ! Rotate hoppings and overlaps
    !
    do k=1, BL%NNeighbs
       call getRotMat( BL, k, TR )
       do ispin=1, BL%NSpin
          if(DebugBethe)Write(*,'(A)')"TR(:, :) in InitBetheLattice Rotation"
          if(DebugBethe)call PrintCMatrix(TR(1:n, 1:n))
          temp = matmul( TR, BL%Vk(ispin, k,1:n,1:n) )
          if(DebugBethe)Write(*,'(A)')"temp(:, :) in InitBetheLattice Rotation"
          if(DebugBethe)call PrintCMatrix(temp(1:n, 1:n))
          BL%Vk(ispin, k,1:n,1:n) = matmul( temp, transpose( TR ) )
          if(DebugBethe)Write(*,'(A,I2,A,I2,A)')"BL%Vk(",ispin,",", k,", :, :) in InitBetheLattice Rotation"
          if(DebugBethe)call PrintCMatrix(BL%Vk(ispin, k, 1:n, 1:n))
          if(DebugBethe)pause
       end do
       temp = matmul( TR, BL%Sk( k,1:n,1:n) )
       BL%Sk(k,1:n,1:n) = matmul( temp, transpose( TR ) )
    end do

    !
    ! Reducing overlap in case of problems
    !
    if (Overlap > 0.01) then 
        BL%Sk=BL%Sk*Overlap
    else 
        BL%Sk=0.0
    end if


    deallocate( temp, TR )

     if ( BL%NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) == 6) then
          nj=2
     else if ( BL%NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) == 6) then
          nj=2
     else
          nj=1
     end if


    !
    ! For non-orthogonal basis set
    !
    if( BL%Overlap ) then
       nx = n*(BL%NNeighbs/nj+1)

       print *, "Overlap present in parameters set: Using extended Hamiltonian since Overlap > 0"
       print *, "N  = ", n
       print *, "NX = ", nx

       allocate( H0X(2,nx,nx), S0X(nx,nx) , Stat=AllocErr )
       if( AllocErr /= 0 ) then
          print *, "InitBetheLattice/Program could not allocate memory for H0X and S0X matrices"
          stop
       end if

       H0X = c_zero
       S0X = c_zero

       do k=0, BL%NNeighbs/nj
          do i=1,n
             do j=1,n
                do ispin=1,BL%NSpin
                   H0X(ispin, k*n+i, k*n+j) = BL%H0(ispin,i,j)
                   if( k>0 )then
                      H0X(ispin, i,     k*n+j) = conjg(BL%Vk(ispin,nj*k,i,j))                   
                      H0X(ispin, k*n+i, j    ) = BL%Vk(ispin,nj*k,j,i)
                   end if
                end do
                S0X(k*n+i, k*n+j) = BL%S0(i,j)
                if( k>0)then
                   S0X(i,     k*n+j) = conjg(BL%Sk(nj*k,i,j))
                   S0X(k*n+i, j    ) = BL%Sk(nj*k,j,i)
                end if
             end do
          end do
       end do

    end if

      !print *, "S0 = "
       do i=1,n
         !write (*,'(150(F7.3))'), (real(BL%S0(i,j)),j=1,n)
       end do

      !print *, "S0X = "
       do i=1,nx
         !write (*,'(150(F7.3))'), (real(S0X(i,j)),j=1,nx)
       end do

      !print *, "H0 = "
       do i=1,n
         !write (*,'(150(F7.3))'), (real(BL%H0(1,i,j)),j=1,n)
       end do

      !print *, "H0X = "
       do i=1,nx
         !write (*,'(150(F7.3))'), (real(H0X(1,i,j)),j=1,nx)
       end do

    !
    ! Adjust parameters such that EFermi = 0
    !
    call AdjustFermi( BL )

    if( ANT1DInp )then

       if(LeadNo==1) open(unit=ifu_ant,file='bl1.'//trim(ant1dname)//'.dat',status='unknown')
       if(LeadNo==2) open(unit=ifu_ant,file='bl2.'//trim(ant1dname)//'.dat',status='unknown')

       n = BL%NAOrbs
       nnn = BL%NNeighbs

       write(ifu_ant,'(A)') '&BLParams'
       write(ifu_ant,'(A,I3)') 'NAOBL= ', BL%NAOrbs
       write(ifu_ant,'(A,I1)') 'NSpinBL= ', BL%NSpin
       write(ifu_ant,'(A,I2)') 'NNNBL= ', BL%NNeighbs
       write(ifu_ant,'(A,I3)') 'NConnect = ', NConnect(LeadNo) 
 
       do k=1,nnn
          write(ifu_ant,'(A,I2,A,3(F10.5))') 'VNN(', k,',:) = ', VPB( LeadNo, 1, k ), VPB( LeadNo, 2, k ), VPB( LeadNo, 3, k )
       end do

       write(ifu_ant,'(A)') '/'
       write(ifu_ant,*) 

       do ispin=1,BL%NSpin
          if( BL%NSpin == 2 .and. ispin == 1 ) write(ifu_ant,'(A)') "! spin-up "
          if( BL%NSpin == 2 .and. ispin == 2 ) write(ifu_ant,'(A)') "! spin-down "
          do k=0,nnn
             if( k == 0 ) write(ifu_ant,'(A)') "! H0 = "
             if( k /= 0 ) write(ifu_ant,'(A,I2,A)') "! V(k=", k, ") = "
             do i=1,n
                do j=1,n
                   if( k == 0 ) hij = real(BL%H0(ispin,i,j))
                   if( k /= 0 ) hij = real(BL%Vk(ispin,k,i,j))
                   if( abs(hij) > eta ) write(ifu_ant,'(I6,I6,ES20.8)'), i, j, hij
                end do
             end do
             write(ifu_ant,'(I6,I6,ES20.8)'), 0, 0, 0.0d0
             write(ifu_ant,*) 
          end do
          write(ifu_ant,*) 
       end do
       close(ifu_ant)
    end if


    if (.not.LeadDOS) return

    ! Write electrode bulk DOS to file
    if(LeadNo==1)then 
       open(UNIT=ifu_bl,FILE="Lead1DOS.dat",STATUS="UNKNOWN")
    else
       open(UNIT=ifu_bl,FILE="Lead2DOS.dat",STATUS="UNKNOWN")
    end if
    do ispin=1,BL%NSpin
       do energy=BL%EMin, BL%EMax, estep*10.0
          zenergy=energy+ui*0.001d0
          write(ifu_bl,'(100(E15.7))') energy, (3.0-BL%NSpin)*BulkSDOS(BL,ispin,zenergy)*(-1)**(ispin+1) !, & 
          call flush(ifu_bl)
       end do
       write(ifu_bl,*) 
    end do
    close(ifu_bl)

    if( BL%Overlap )then
       deallocate( H0X, S0X )
    end if

    if( BL%Matrix )then
       print *, "Not fully implmented yet: "
       print *, "Calculation of Self-energies for Bethe Lattice with more than minimal basis set."
       !stop
    endif

  end subroutine InitBetheLattice


  !
  ! *** Cleanup routine: deallocate dynamic arrays       ***
  ! *** Nothing to do now since we use static arrays now ***
  !
  subroutine CleanUpBL( BL )
    implicit none
    type(TBetheLattice) :: BL
    integer :: AllocErr
  end subroutine CleanUpBL


  !
  ! *** Conventional atomic number of lead atoms *** 
  !
  integer function BL_AtmNo( BL )
    implicit none
    type(TBetheLattice),intent(IN) :: BL
    BL_AtmNo = BL%AtmNo
  end function BL_AtmNo


  ! *** Number of atomic orbitals per lattice site
  integer function BL_NAOrbs( BL )
    implicit none
    type(TBetheLattice),intent(IN) :: BL
    BL_NAOrbs = BL%NAOrbs
  end function BL_NAOrbs


  !
  ! *** Number of nearest neighbours in lattice ***
  !
  integer function BL_NNeighbs( BL )
    implicit none
    type(TBetheLattice),intent(IN) :: BL
    BL_NNeighbs = BL%NNeighbs
  end function BL_NNeighbs


  !
  ! *** Number of non-degenerate spin channels ***
  !
  integer function BL_NSpin( BL )
    implicit none
    type(TBetheLattice),intent(IN) :: BL
    BL_NSpin = BL%NSpin
  end function BL_NSpin


  !
  ! *** Number of non-degenerate spin channels ***
  !
  integer function BL_NElectrons( BL )
    implicit none
    type(TBetheLattice),intent(IN) :: BL
    BL_NElectrons = BL%NElectrons
  end function BL_NElectrons


  !
  ! *** Lower energy bound of Bethe lattice DOS ***
  !
  real function BL_EMin( BL )
    implicit none
    type(TBetheLattice),intent(IN) :: BL
    BL_EMin = BL%EMin
  end function BL_EMin


  !
  ! *** Upper energy bound of Bethe lattice DOS ***
  !
  real function BL_EMax( BL )
    implicit none
    type(TBetheLattice),intent(IN) :: BL
    BL_EMax = BL%EMax
  end function BL_EMax


  !
  ! *** Compute self-energy matrix ***
  !
  subroutine CompSelfEnergyBL( BL, spin, cenergy, Sigma_n )
   use g09Common, only: GetNAtoms

    use cluster, only: AreConnected, LoAOrbNo, NDirections, GetDir
    use constants, only: c_zero
    implicit none

    type(TBetheLattice), intent(inout) :: BL
    integer, intent(in) :: spin
    complex*16, intent(in) :: cenergy
    complex*16, dimension(:,:), intent(inout) :: Sigma_n
    complex*16, dimension(BL%NNeighbs,BL%NAOrbs,BL%NAOrbs) :: Sigmak
    integer :: ia, i, j, nk, li, lj, ispin, k, NAO, NNeighbs
    integer :: omp_get_thread_num

    if(DebugBethe)Write(*,'(A)')"ENTERED BetheLattice/CompSelfEnergyBL"

    ispin=spin
    if( BL%NSpin==1 .and. spin == 2 )ispin=1

    NAO = BL%NAOrbs
    NNeighbs=BL%NNeighbs

    !Sigmak = c_zero

    !call SolveDysonBL( BL%Sigmak(ispin,1:NNeighbs,1:NAO,1:NAO), cenergy, BL%H0(ispin,1:NAO,1:NAO), &
    !call SolveDysonBL( BL%LeadNo, Sigmak, cenergy, BL%H0(ispin,1:NAO,1:NAO), & ! ORIGINAL CODE.
    !     BL%Vk(ispin,1:NNeighbs,1:NAO,1:NAO), BL%S0(1:NAO,1:NAO), BL%Sk(1:NNeighbs,1:NAO,1:NAO) ) ! ORIGINAL CODE.
    if(.not.DebugDyson)then
      call SolveDysonBL( BL%LeadNo, Sigmak, cenergy, BL%H0(ispin,1:NAO,1:NAO), & ! ORIGINAL CODE.
           BL%Vk(ispin,1:NNeighbs,1:NAO,1:NAO), BL%S0(1:NAO,1:NAO), BL%Sk(1:NNeighbs,1:NAO,1:NAO) ) ! ORIGINAL CODE.
    else
      call SolveDysonBLDebug( BL%LeadNo, Sigmak, cenergy, BL%H0(ispin,1:NAO,1:NAO), & ! FOR DEBUGDYSON.
           BL%Vk(ispin,1:NNeighbs,1:NAO,1:NAO), BL%S0(1:NAO,1:NAO), BL%Sk(1:NNeighbs,1:NAO,1:NAO) ) ! FOR DEBUGDYSON.
    end if

    !Sigma_n = c_zero
    do ia = 1,GetNAtoms()
       if( AreConnected( ia, BL%LeadNo ) ) then
          do i=1,BL%NAOrbs
             do j=1,BL%NAOrbs
                li=LoAOrbNo(ia)+i-1
                lj=LoAOrbNo(ia)+j-1
                do nk=1,NDirections(ia)
                   !Sigma_n(li,lj)=Sigma_n(li,lj)+BL%SigmaK(ispin,GetDir(ia,nk),i,j)
                   Sigma_n(li,lj)=Sigma_n(li,lj)+Sigmak(GetDir(ia,nk),i,j)
                end do
             end do
          end do
       end if
    end do
  end subroutine CompSelfEnergyBL


  !
  ! *** Self-consistent solver of Dyson equation for Bethe lattice ***
  !
  !subroutine SolveDysonBL( LeadNo, Sigmak, Energy, H0, Vk, S0, Sk, NNeighbs, NAOrbs )
  subroutine SolveDysonBL( LeadNo, Sigmak, Energy, H0, Vk, S0, Sk )
    use util, only: PrintCMatrix
    use constants, only: c_zero, ui, c_one
    use parameters, only: eta,selfacc,NEmbed,NAtomEl
   !use lapack_blas, only: zgemm,zgetri,zgetrf
   !use lapack95, only: zgetri,zgetrf
   !use blas95, only: zgemm
   !use lapack95
   !use blas95
    use ANTCommon
    use G09Common, only: GetNAtoms, GetAN
    implicit none

    external zgemm,zgetri,zgetrf
    
!    integer, intent(in) :: NNeighbs, NAOrbs
    complex*16, dimension(:,:,:),intent(out) :: Sigmak
    complex*16, dimension(:,:,:),intent(in) :: Vk
    !complex, dimension(NNeighbs,NAOrbs,NAOrbs),intent(in) :: Vk
    complex*16, dimension(:,:),intent(in) :: H0
    complex*16, dimension(:,:,:),intent(in) :: Sk
    complex*16, dimension(:,:),intent(in) :: S0
    complex*16, intent(in) :: Energy
    
    integer :: k, i, j, NAOrbs, NNeighbs, ncycle, ipiv(size( SigmaK, 3 )), info, AllocErr
!    integer :: k, i, j, ncycle, ipiv(size( Vk, 3 )), info, AllocErr
    integer, intent(in) :: LeadNo
    
    ! auxiliary directional self energy for self-consistent calculation
    complex*16, dimension( size(SigmaK,1), size(SigmaK,2), size(SigmaK,2) ) :: Sigma_aux
!    complex*16, dimension( size(Vk,1), size(Vk,2), size(Vk,2) ) :: Sigma_aux
    !complex*16, dimension( size(Vk,2), size(Vk,2) ) :: Sigma_aux_aux
    complex*16, dimension( size(SigmaK,2), size(SigmaK,2) ) :: Sigma_aux_aux
    ! temporary matrix for multiplication and Energy matrix E(i,j) = ( energy + ui*eta )*delta(i,j)
    ! and Total self-energy 
    complex*16, dimension( size(SigmaK,2), size(SigmaK,2) ) :: temp, E, Sigma_T, G0, Vkeff, Sigma_TA, Sigma_TB
!    complex*16, dimension( size(Vk,2), size(Vk,2) ) :: temp, E, Sigma_T, G0, Vkeff, Sigma_TA, Sigma_TB
    ! work array for inversion
    complex*16, dimension( 4*size(SigmaK,2) ) :: work
!    complex*16, dimension( 4*size(Vk,2) ) :: work

    real :: error

    if(DebugBethe)Write(*,'(A)')"ENTERED BetheLattice/SolveDysonBL"

    NNeighbs = size( SigmaK, 1 ) ! ORIGINAL CODE. 1ST DIMENSION SEEMS TO BE SPIN.
    NAOrbs   = size( SigmaK, 2 ) ! ORIGINAL CODE. 1ST DIMENSION SEEMS TO BE SPIN.
    !NNeighbs = size( SigmaK, 2 )
    !NAOrbs   = size( SigmaK, 3 )

    ! Initialize directional self-energies and energy matrix
    !E = S0*energy ! ORIGINAL CODE.
    E = S0*(energy+ui*eta) ! ADDED THIS TO AVOID THE CRASH ON Energy=0.0+i*0.0 OCCURRING FOR 1DBL
    Sigmak = c_zero

    do i=1,NAOrbs
       do k=1,NNeighbs
          Sigmak(k,i,i)=-1.0d0*ui
       enddo
    end do

    error = 1.0d0
    ncycle = 0

    IF (NNeighbs == 12 .OR. NNeighbs == 8 .or. NNeighbs == 4 .or. (NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) /=6) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) /=6)) then
      !Write(*,'(A)')"1st case: (NNeighbs == 12 .OR. NNeighbs == 8 .or. NNeighbs == 4 .or. (NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) /=6) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) /=6))"
      ! Selfconsistency
      do while (error.gt.selfacc) !ncycle=1,MaxCycle
        ncycle = ncycle + 1
        ! Compute total self-energy
        !  = sum of directional self-energies
        do i=1,NAOrbs
          do j=1,NAOrbs
             Sigma_T(i,j)= c_zero
             do k=1,NNeighbs
                Sigma_T(i,j)=Sigma_T(i,j)+Sigmak(k,i,j)
             enddo
          enddo
        enddo
        do k=1, NNeighbs
          ! Computing Self energy for direction k

!!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(i,j)
!!$OMP DO SCHEDULE(STATIC,1)
          do i=1,NAOrbs
          !write(ifu_log,*)omp_get_thread_num()
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigma_T(i,j) + Sigmak(k-(-1)**k,i,j)
             enddo
          enddo
!!$OMP END DO
!!$OMP END PARALLEL
          ! Inverting to obtain (E-H-(Sigma_T-Sigma_(-k)))^-1
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          !
          ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
          !
          Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
          !
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,&
               c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Vkeff,NAOrbs,temp,NAOrbs, &
               c_zero,Sigma_aux(k,:,:),NAOrbs )
          ! Mixing with old self-energy matrix 50:50
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = 0.5d0*(Sigma_aux(k,i,j)+Sigmak(k,i,j))
                error=error+abs(Sigma_aux(k,i,j)-Sigmak(k,i,j))
             end do
          end do
       enddo ! End of k-Loop
       ! Actualization of dir. self-energies
       Sigmak=Sigma_aux
       error=error/(NAOrbs*NAOrbs*NNeighbs)
    enddo ! End of self-consistency loop

  else if ((NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) == 6 ) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) ==6)) then
    !Write(*,'(A)')"2nd case: ((NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) == 6 ) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) ==6))"
    !Selfconsistency
    do while (error.gt.selfacc) !ncycle=1,MaxCycle
       ncycle = ncycle + 1
       ! Compute total self-energy
       !  = sum of partial directional self-energies
       do i=1,NAOrbs
          do j=1,NAOrbs
             Sigma_TA(i,j)= c_zero
             Sigma_TB(i,j)= c_zero
             do k=1,NNeighbs,2
                Sigma_TA(i,j)=Sigma_TA(i,j)+Sigmak(k,i,j)
                Sigma_TB(i,j)=Sigma_TB(i,j)+Sigmak(k+1,i,j)
             enddo
          enddo
       enddo
       do k=1, NNeighbs,2
          ! Computing Self energy for direction k
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigma_TB(i,j) + Sigmak(k+1,i,j)
                Sigma_aux(k+1,i,j) = E(i,j) - H0(i,j) - Sigma_TA(i,j) + Sigmak(k,i,j)
             enddo
          enddo
          ! Inverting to obtain (E-H-(Sigma_T-Sigma_(-k)))^-1
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k+1,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k+1,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          !
          ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
          !
          Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs,c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs,c_one,Vkeff,NAOrbs,temp,NAOrbs,c_zero,Sigma_aux(k,:,:),NAOrbs )
          Vkeff = Vk(k+1,:,:)-Energy*Sk(k+1,:,:)
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs,c_one,Sigma_aux(k+1,:,:),NAOrbs,Vkeff, NAOrbs,c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs,c_one,Vkeff,NAOrbs,temp,NAOrbs,c_zero,Sigma_aux(k+1,:,:),NAOrbs )
          ! Mixing with old self-energy matrix 50:50
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = 0.5d0*(Sigma_aux(k,i,j)+Sigmak(k,i,j))
                error=error+abs(Sigma_aux(k,i,j)-Sigmak(k,i,j))
             end do
          end do
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k+1,i,j) = 0.5d0*(Sigma_aux(k+1,i,j)+Sigmak(k+1,i,j))
                error=error+abs(Sigma_aux(k+1,i,j)-Sigmak(k+1,i,j))
             end do
          end do
       enddo ! End of k-Loop
       ! Actualization of dir. self-energies
       Sigmak=Sigma_aux
       error=error/(NAOrbs*NAOrbs*NNeighbs)
    enddo ! End of self-consistency loop

  ELSE IF(Nembed(LeadNo)==1)THEN
    !Write(*,'(A)')"3rd case: (Nembed(LeadNo)==1)"
      ! Write(ifu_log,'(A,I2)')"1D BL for LeadNo = ",LeadNo
      !Write(*,'(A)') "Computing 1D Bethe Lattice."
      !Write(*,'(A)') "Press any key to continue..."
      !if(DebugBethe)Pause
      ! Selfconsistency NOT NECESSARY IN THE 1D CASE.
      Sigmak = c_zero
      Sigma_T = c_zero
    if(.false.)then
      ! ADDED ONLY FOR 1DBL BEACUSE SELF-CONSISTENCY NOT NECESSARY.
      do k=1, NNeighbs
        Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
        do i=1,NAOrbs
          do j=1,NAOrbs
            Sigma_aux_aux(i,j) = E(i,j) - H0(i,j) - Vk(k,i,j)
          end do
        end do
      ! Inverting to obtain (E-H-(Vkeff(-k)))^-1
      !call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
      !call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
      call zgetrf(NAOrbs,NAOrbs,Sigma_aux_aux,NAOrbs,ipiv,info)
      call zgetri(NAOrbs,Sigma_aux_aux,NAOrbs,ipiv,work,4*NAOrbs,info)
      !
      ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
      !
      !Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
      !
      !Sigma_aux_aux(:,:)=Sigma_aux(k,:,:)
      call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs, &
           !c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,&
           c_one,Sigma_aux_aux,NAOrbs,Vkeff, NAOrbs,&
           c_zero,temp,NAOrbs )
      call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs, &
           c_one,Vkeff,NAOrbs,temp,NAOrbs, &
           c_zero,Sigma_aux(k,:,:),NAOrbs )

        !call PrintCMatrix(Sigma_aux_aux)
        do i=1,NAOrbs
          do j=1,NAOrbs
            Sigmak(k,i,j)=Sigma_aux_aux(i,j)
          end do
        end do
      end do
      return ! EXIT FROM IF BECAUSE Sigmak(k,i,j) IS CORRECT.
    end if
      !NNeighbs = 2
      do while (error.gt.selfacc) !ncycle=1,MaxCycle
        ncycle = ncycle + 1
        ! Compute total self-energy
        !  = sum of directional self-energies
        do i=1,NAOrbs
          do j=1,NAOrbs
             Sigma_T(i,j)= c_zero
             do k=1,NNeighbs
                Sigma_T(i,j)=Sigma_T(i,j)+Sigmak(k,i,j)
             enddo
          enddo
        enddo
        do k=1, NNeighbs
          ! Computing Self energy for direction k

!!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(i,j)
!!$OMP DO SCHEDULE(STATIC,1)
          do i=1,NAOrbs
          !write(ifu_log,*)omp_get_thread_num()
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigma_T(i,j) + Sigmak(k-(-1)**k,i,j)
                !Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigmak(k,i,j)
             enddo
          enddo
!!$OMP END DO
!!$OMP END PARALLEL
          ! Inverting to obtain (E-H-(Sigma_T-Sigma_(-k)))^-1
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          !
          ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
          !
          Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
          !
          !Sigma_aux_aux(:,:)=Sigma_aux(k,:,:)
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,&
               !c_one,Sigma_aux_aux,NAOrbs,Vkeff, NAOrbs,&
               c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Vkeff,NAOrbs,temp,NAOrbs, &
               c_zero,Sigma_aux(k,:,:),NAOrbs )
               !c_zero,Sigma_aux_aux,NAOrbs )
          !Sigma_aux(k,:,:)=Sigma_aux_aux(:,:)
          ! Mixing with old self-energy matrix 50:50
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = 0.5d0*(Sigma_aux(k,i,j)+Sigmak(k,i,j))
                error=error+abs(Sigma_aux(k,i,j)-Sigmak(k,i,j))
             end do
          end do
       enddo ! End of k-Loop
       ! Actualization of dir. self-energies
       Sigmak=Sigma_aux
       error=error/(NAOrbs*NAOrbs*NNeighbs)
    enddo ! End of self-consistency loop

  ELSE
    !Write(*,'(A)')"4th case: else..."
      WRITE(ifu_log,*)' Number of directions incorrect in Bethelattice'
      STOP
  END IF

  !Write(*,'(A)')"EXIT SolveDysonBL"
  !if(DebugBethe)Pause

  end subroutine SolveDysonBL

    !
  ! *** Self-consistent solver of Dyson equation for Bethe lattice ***
  !
  !subroutine SolveDysonBL( LeadNo, Sigmak, Energy, H0, Vk, S0, Sk, NNeighbs, NAOrbs )
  subroutine SolveDysonBLDebug( LeadNo, Sigmak, Energy, H0, Vk, S0, Sk )
    use util, only: PrintCMatrix
    use constants, only: c_zero, ui, c_one
    use parameters, only: eta,selfacc,NEmbed,NAtomEl
   !use lapack_blas, only: zgemm,zgetri,zgetrf
   !use lapack95, only: zgetri,zgetrf
   !use blas95, only: zgemm
   !use lapack95
   !use blas95
    use ANTCommon
    use G09Common, only: GetNAtoms, GetAN
    implicit none

    external zgemm,zgetri,zgetrf

!    integer, intent(in) :: NNeighbs, NAOrbs
    complex*16, dimension(:,:,:),intent(out) :: Sigmak
    complex*16, dimension(:,:,:),intent(in) :: Vk
    !complex, dimension(NNeighbs,NAOrbs,NAOrbs),intent(in) :: Vk
    complex*16, dimension(:,:),intent(in) :: H0
    complex*16, dimension(:,:,:),intent(in) :: Sk
    complex*16, dimension(:,:),intent(in) :: S0
    complex*16, intent(in) :: Energy

    integer :: k, i, j, NAOrbs, NNeighbs, ncycle, ipiv(size( SigmaK, 3 )), info, AllocErr
!    integer :: k, i, j, ncycle, ipiv(size( Vk, 3 )), info, AllocErr
    integer, intent(in) :: LeadNo

    ! auxiliary directional self energy for self-consistent calculation
    complex*16, dimension( size(SigmaK,1), size(SigmaK,2), size(SigmaK,2) ) :: Sigma_aux
!    complex*16, dimension( size(Vk,1), size(Vk,2), size(Vk,2) ) :: Sigma_aux
    !complex*16, dimension( size(Vk,2), size(Vk,2) ) :: Sigma_aux_aux
    complex*16, dimension( size(SigmaK,2), size(SigmaK,2) ) :: Sigma_aux_aux
    ! temporary matrix for multiplication and Energy matrix E(i,j) = ( energy + ui*eta )*delta(i,j)
    ! and Total self-energy
    complex*16, dimension( size(SigmaK,2), size(SigmaK,2) ) :: temp, E, Sigma_T, G0, Vkeff, Sigma_TA, Sigma_TB
!    complex*16, dimension( size(Vk,2), size(Vk,2) ) :: temp, E, Sigma_T, G0, Vkeff, Sigma_TA, Sigma_TB
    ! work array for inversion
    complex*16, dimension( 4*size(SigmaK,2) ) :: work
!    complex*16, dimension( 4*size(Vk,2) ) :: work

    real :: error

    if(DebugBethe)Write(*,'(A)')"ENTERED BetheLattice/SolveDysonBLDebug"


    NNeighbs = size( SigmaK, 1 ) ! ORIGINAL CODE. 1ST DIMENSION SEEMS TO BE SPIN.
    NAOrbs   = size( SigmaK, 2 ) ! ORIGINAL CODE. 1ST DIMENSION SEEMS TO BE SPIN.
    !NNeighbs = size( SigmaK, 2 )
    !NAOrbs   = size( SigmaK, 3 )
    if(DebugDyson)then
      Write(*,'(A,I4,A,I4,A,I4)')"LeadNo =",LeadNo,"; NNeighbs",NNeighbs,"; NAOrbs",NAOrbs
      do k=1,NNeighbs
        Write(*,'(A,I2,A,I2,A)')"Vk(",k,",1:NAOrbs,1:NAOrbs) as input at start SolveDysonBethelattice"
        call PrintCMatrix(Vk(k,1:NAOrbs,1:NAOrbs))
      end do
    end if

    ! Initialize directional self-energies and energy matrix
    !E = S0*energy ! ORIGINAL CODE.
    E = S0*(energy+ui*eta) ! ADDED THIS TO AVOID THE CRASH ON Energy=0.0+i*0.0 OCCURRING FOR 1DBL
    Sigmak = c_zero
    
    do i=1,NAOrbs
       do k=1,NNeighbs
          Sigmak(k,i,i)=-1.0d0*ui
       enddo
    end do

    error = 1.0d0
    ncycle = 0

    IF (NNeighbs == 12 .OR. NNeighbs == 8 .or. NNeighbs == 4 .or. (NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) /=6) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) /=6)) then
      !Write(*,'(A)')"1st case: (NNeighbs == 12 .OR. NNeighbs == 8 .or. NNeighbs == 4 .or. (NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) /=6) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) /=6))"
      ! Selfconsistency
      do while (error.gt.selfacc) !ncycle=1,MaxCycle
        ncycle = ncycle + 1
        ! Compute total self-energy
        !  = sum of directional self-energies
        do i=1,NAOrbs
          do j=1,NAOrbs
             Sigma_T(i,j)= c_zero
             do k=1,NNeighbs
                Sigma_T(i,j)=Sigma_T(i,j)+Sigmak(k,i,j)
             enddo
          enddo
        enddo
        do k=1, NNeighbs
          ! Computing Self energy for direction k 
        
!!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(i,j)
!!$OMP DO SCHEDULE(STATIC,1)
          do i=1,NAOrbs
          !write(ifu_log,*)omp_get_thread_num()
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigma_T(i,j) + Sigmak(k-(-1)**k,i,j)
             enddo
          enddo
!!$OMP END DO
!!$OMP END PARALLEL
          ! Inverting to obtain (E-H-(Sigma_T-Sigma_(-k)))^-1
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          !
          ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
          !
          Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
          !
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,&
               c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Vkeff,NAOrbs,temp,NAOrbs, &
               c_zero,Sigma_aux(k,:,:),NAOrbs )
          ! Mixing with old self-energy matrix 50:50
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = 0.5d0*(Sigma_aux(k,i,j)+Sigmak(k,i,j))
                error=error+abs(Sigma_aux(k,i,j)-Sigmak(k,i,j))
             end do
          end do
       enddo ! End of k-Loop
       ! Actualization of dir. self-energies
       Sigmak=Sigma_aux
       error=error/(NAOrbs*NAOrbs*NNeighbs)
    enddo ! End of self-consistency loop

  else if ((NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) == 6 ) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) ==6)) then
    !Write(*,'(A)')"2nd case: ((NNeighbs == 6 .and. LeadNo == 1 .and. GetAN(1) == 6 ) .or. (NNeighbs == 6 .and. LeadNo == 2 .and. GetAN(GetNAtoms()) ==6))"
    !Selfconsistency
    do while (error.gt.selfacc) !ncycle=1,MaxCycle
       ncycle = ncycle + 1
       ! Compute total self-energy         
       !  = sum of partial directional self-energies 
       do i=1,NAOrbs
          do j=1,NAOrbs
             Sigma_TA(i,j)= c_zero
             Sigma_TB(i,j)= c_zero
             do k=1,NNeighbs,2
                Sigma_TA(i,j)=Sigma_TA(i,j)+Sigmak(k,i,j)
                Sigma_TB(i,j)=Sigma_TB(i,j)+Sigmak(k+1,i,j)
             enddo
          enddo
       enddo
       do k=1, NNeighbs,2
          ! Computing Self energy for direction k 
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigma_TB(i,j) + Sigmak(k+1,i,j)
                Sigma_aux(k+1,i,j) = E(i,j) - H0(i,j) - Sigma_TA(i,j) + Sigmak(k,i,j)
             enddo
          enddo
          ! Inverting to obtain (E-H-(Sigma_T-Sigma_(-k)))^-1
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k+1,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k+1,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          !
          ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
          !
          Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs,c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs,c_one,Vkeff,NAOrbs,temp,NAOrbs,c_zero,Sigma_aux(k,:,:),NAOrbs )
          Vkeff = Vk(k+1,:,:)-Energy*Sk(k+1,:,:)
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs,c_one,Sigma_aux(k+1,:,:),NAOrbs,Vkeff, NAOrbs,c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs,c_one,Vkeff,NAOrbs,temp,NAOrbs,c_zero,Sigma_aux(k+1,:,:),NAOrbs )
          ! Mixing with old self-energy matrix 50:50
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = 0.5d0*(Sigma_aux(k,i,j)+Sigmak(k,i,j))
                error=error+abs(Sigma_aux(k,i,j)-Sigmak(k,i,j))
             end do
          end do
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k+1,i,j) = 0.5d0*(Sigma_aux(k+1,i,j)+Sigmak(k+1,i,j))
                error=error+abs(Sigma_aux(k+1,i,j)-Sigmak(k+1,i,j))
             end do
          end do
       enddo ! End of k-Loop
       ! Actualization of dir. self-energies
       Sigmak=Sigma_aux
       error=error/(NAOrbs*NAOrbs*NNeighbs)
    enddo ! End of self-consistency loop

  ELSE IF(Nembed(LeadNo)==1)THEN
    !Write(*,'(A)')"3rd case: (Nembed(LeadNo)==1)"
      ! Write(ifu_log,'(A,I2)')"1D BL for LeadNo = ",LeadNo
      !Write(*,'(A)') "Computing 1D Bethe Lattice."
      !Write(*,'(A)') "Press any key to continue..."
      !if(DebugBethe)Pause
      ! Selfconsistency NOT NECESSARY IN THE 1D CASE.
      Sigmak = c_zero
      Sigma_T = c_zero
    if(.false.)then
      ! ADDED ONLY FOR 1DBL BEACUSE SELF-CONSISTENCY NOT NECESSARY.
      do k=1, NNeighbs
        Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
        do i=1,NAOrbs
          do j=1,NAOrbs
            Sigma_aux_aux(i,j) = E(i,j) - H0(i,j) - Vk(k,i,j)
          end do
        end do
      ! Inverting to obtain (E-H-(Vkeff(-k)))^-1
      !call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
      !call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
      call zgetrf(NAOrbs,NAOrbs,Sigma_aux_aux,NAOrbs,ipiv,info)
      call zgetri(NAOrbs,Sigma_aux_aux,NAOrbs,ipiv,work,4*NAOrbs,info)
      !
      ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
      !
      !Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
      !
      !Sigma_aux_aux(:,:)=Sigma_aux(k,:,:)
      call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs, &
           !c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,&
           c_one,Sigma_aux_aux,NAOrbs,Vkeff, NAOrbs,&
           c_zero,temp,NAOrbs )
      call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs, &
           c_one,Vkeff,NAOrbs,temp,NAOrbs, &
           c_zero,Sigma_aux(k,:,:),NAOrbs )

        call PrintCMatrix(Sigma_aux_aux)
        do i=1,NAOrbs
          do j=1,NAOrbs
            Sigmak(k,i,j)=Sigma_aux_aux(i,j)
          end do
        end do
      end do
      return ! EXIT FROM IF BECAUSE Sigmak(k,i,j) IS CORRECT.
    end if
      !NNeighbs = 2
      if(DebugDyson)Write(*,'(A,g15.5,A,g15.5,A)')"Energy = ",REAL(Energy),"+i(",AIMAG(Energy),")"
      do while (error.gt.selfacc) !ncycle=1,MaxCycle
        ncycle = ncycle + 1
        ! Compute total self-energy
        !  = sum of directional self-energies
        do i=1,NAOrbs
          do j=1,NAOrbs
             Sigma_T(i,j)= c_zero
             do k=1,NNeighbs
                Sigma_T(i,j)=Sigma_T(i,j)+Sigmak(k,i,j)
             enddo
          enddo
        enddo
        do k=1, NNeighbs
          ! Computing Self energy for direction k

!!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(i,j)
!!$OMP DO SCHEDULE(STATIC,1)
          do i=1,NAOrbs
          !write(ifu_log,*)omp_get_thread_num()
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigma_T(i,j) + Sigmak(k-(-1)**k,i,j)
                !Sigma_aux(k,i,j) = E(i,j) - H0(i,j) - Sigmak(k,i,j)
             enddo
          enddo
!!$OMP END DO
!!$OMP END PARALLEL
          ! Inverting to obtain (E-H-(Sigma_T-Sigma_(-k)))^-1
          call zgetrf(NAOrbs,NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,info)
          call zgetri(NAOrbs,Sigma_aux(k,:,:),NAOrbs,ipiv,work,4*NAOrbs,info)
          !
          ! Matrix multiplication: V_k * (E-H-(Sigma_T-Sigma_(-k)))^-1 * V_k^*
          !
          Vkeff = Vk(k,:,:)-Energy*Sk(k,:,:)
          !
          !Sigma_aux_aux(:,:)=Sigma_aux(k,:,:)
          call zgemm('N','C',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Sigma_aux(k,:,:),NAOrbs,Vkeff, NAOrbs,&
               !c_one,Sigma_aux_aux,NAOrbs,Vkeff, NAOrbs,&
               c_zero,temp,NAOrbs )
          call zgemm('N','N',NAOrbs,NAOrbs,NAOrbs, &
               c_one,Vkeff,NAOrbs,temp,NAOrbs, &
               c_zero,Sigma_aux(k,:,:),NAOrbs )
               !c_zero,Sigma_aux_aux,NAOrbs )
          !Sigma_aux(k,:,:)=Sigma_aux_aux(:,:)
          ! Mixing with old self-energy matrix 50:50
          do i=1,NAOrbs
             do j=1,NAOrbs
                Sigma_aux(k,i,j) = 0.5d0*(Sigma_aux(k,i,j)+Sigmak(k,i,j)) ! ORIGINAL CODE.
                !Sigma_aux(k,i,j) = (0.01d0*Sigma_aux(k,i,j)+0.99d0*Sigmak(k,i,j)) ! SLOWER. NO EFFECT. SOLVED BY ADDING ui*eta
                error=error+abs(Sigma_aux(k,i,j)-Sigmak(k,i,j))
             end do
          end do
       enddo ! End of k-Loop
       ! Actualization of dir. self-energies
       Sigmak=Sigma_aux

       error=error/(NAOrbs*NAOrbs*NNeighbs)
       if(DebugDyson)Write(*,'(A,g15.5,A,g15.5,A)')"error = ",error," > ",selfacc," = selfacc"
     enddo ! End of self-consistency loop
     if(DebugDyson)then
       do k=1,NNeighbs
         Write(*,'(A,I2,A)')"Sigmak(",k,",:,:)"
         call PrintCMatrix(Sigmak(k,:,:))
       end do
     end if

  ELSE
    !Write(*,'(A)')"4th case: else..."
      WRITE(ifu_log,*)' Number of directions incorrect in Bethelattice'
      STOP
  END IF

  !Write(*,'(A)')"EXIT SolveDysonBL"
  !if(DebugBethe)Pause

  end subroutine SolveDysonBLDebug


  ! 
  ! *** Spin-resolved Bulk DOS of Bethe lattice ***
  ! 
  real function BulkSDOS( BL, spin, energy )
    use constants, only: d_zero, d_pi
    use parameters, only: Overlap
    implicit none
    
    type(TBetheLattice), intent(inout) :: BL
    integer, intent(in) :: spin
    complex*16, intent(in) :: energy

    complex*16, dimension( BL%NAOrbs, BL%NAOrbs ) :: G0
    complex*16, dimension( nx, nx ) :: G0X, GS0X

    integer :: i

    if( BL%Overlap )then
       call CompG0X( BL, spin, energy, G0X )
       GS0X = MATMUL( G0X, S0X )
    else 
       call CompGreensFunc( BL, spin, energy, G0 )
    end if

    BulkSDOS = d_zero
    do i=1,BL%NAOrbs
       if( BL%Overlap )then
          BulkSDOS = BulkSDOS + DIMAG(GS0X(i,i))
       else
          BulkSDOS = BulkSDOS + DIMAG(G0(i,i))
       end if
    end do
    BulkSDOS = -BulkSDOS/d_pi
  end function BulkSDOS


  ! 
  ! *** Computes Bulk Green's function G0 ***
  ! 
  subroutine CompGreensFunc( BL, Spin, energy, G0 )
    use util, only: PrintCMatrix
    use constants, only: c_zero, ui
    use parameters, only: eta, DD, UD, DU, Nembed
   !use lapack_blas, only: zgetri,zgetrf
   !use lapack95, only: zgetri,zgetrf
   !use lapack95
   !use blas95
    implicit none

    external  zgetri,zgetrf

    type(TBetheLattice), intent(inout) :: BL
    integer, intent(in) :: Spin
    complex*16, intent(in) :: energy
    complex*16, dimension( BL%NAOrbs, BL%NAOrbs ),intent(out) :: G0
    complex*16, dimension( BL%NSpin,BL%NNeighbs,BL%NAOrbs, BL%NAOrbs ) :: BLSigmak
    complex*16, dimension( BL%NNeighbs,BL%NAOrbs, BL%NAOrbs ) :: Vk_aux
    integer :: n, k, ipiv(BL%NAOrbs), info, i, j, ispin,nj,NNeighbs
    complex*16, dimension( 4*BL%NAOrbs  ) :: work
    !real :: dos

    if(Debug)then
      Write(*,'(A)')"ENTER CompGreensFunc"
      Write(*,'(A,I4)')"n = ",n
      Write(*,'(A,I4)')"BL%NSpin = ",BL%NSpin
      Write(*,'(A,I4)')"BL%NNeighbs = ",BL%NNeighbs
      Write(*,'(A,I4)')"BL%NAorbs = ",BL%NAOrbs
    end if

    !do k=1,BL%NNeighbs
    !  Write(*,'(A,I2,A,I2,A)')"BLSigmak(",spin,",",k,",:,:)"
    !  call PrintCMatrix(BLSigmak(spin,k,:,:))
    !end do

    ispin = spin
    if( ispin < 1 .or. ispin > 2 ) then
       print *, "Undefined value for Spin: ", ispin
       stop
    end if

    if (BL%LeadNo == 1 .and. spin == 1 .and. (DU.or.DD)) ispin = 2
    if (BL%LeadNo == 1 .and. spin == 2 .and. (DU.or.DD)) ispin = 1
    if (BL%LeadNo == 2 .and. spin == 1 .and. (UD.or.DD)) ispin = 2
    if (BL%LeadNo == 2 .and. spin == 2 .and. (UD.or.DD)) ispin = 1
    if( spin == 2 .and. BL%NSpin == 1 ) ispin = 1
    NNeighbs = BL%NNeighbs
    n=BL%NAOrbs

    if(Debug)then
      do k=1,NNeighbs
        Write(*,'(A,I2,A,I2,A)')"BL%Vk(",ispin,",",k,",:,:) before call SolveDysonBL"
        call PrintCMatrix(BL%Vk(ispin,k,1:n,1:n))
      end do
    end if

    !Vk_aux(k,:,:) = BL%Vk(ispin,k,:,:)


    call SolveDysonBL( BL%LeadNo, BLSigmak(spin,1:NNeighbs,1:n,1:n), energy, BL%H0(ispin,1:n,1:n), BL%Vk(ispin,1:NNeighbs,1:n,1:n), &
         BL%S0(1:n,1:n), BL%Sk(1:NNeighbs,1:n,1:n))
    !call SolveDysonBL( BL%LeadNo, BLSigmak(spin,1:NNeighbs,1:n,1:n), energy, BL%H0(ispin,1:n,1:n), Vk_aux, &
    !     BL%S0(1:n,1:n), BL%Sk(1:NNeighbs,1:n,1:n), NNeighbs, n )

    if(Debug)then
      do k=1,BL%NNeighbs
        Write(*,'(A,I2,A,I2,A)')"BLSigmak(",spin,",",k,",:,:)"
        call PrintCMatrix(BLSigmak(spin,k,:,:))
      end do
    end if

    G0=c_zero

    if (NNeighbs == 6) then
        nj=2
    else if (NNeighbs == 12 .OR. NNeighbs == 8 .or. NNeighbs == 4 .or. NNeighbs == 2) then
        nj=1
    else if (Nembed(BL%LeadNo)==1) then
        !Write(ifu_log,'(A,I1)')"1D BL in electrode BL%LeadNo=",BL%LeadNo
        nj=1
    else
        print *,"Incorrect number of directions: Error n. 1"
        stop
    end if

    do i=1,n
       do j=1,n
          G0(i,j)=(energy+ui*1.0d-10)*BL%S0(i,j)-BL%H0(ispin,i,j)
          do k=nj,NNeighbs,nj
             G0(i,j)=G0(i,j)-BLSigmak(ispin,k,i,j)
          enddo
       enddo
    enddo
    
    call zgetrf(n,n,G0,n,ipiv,info)
    call zgetri(n,G0,n,ipiv,work,4*n,info)
    !Write(ifu_log,'(A,F12.6,A,F12.6,A,F12.6,A)')"Energy=",Real(energy),"; G0=(",REAL(G0(1,1)),",",DIMAG(G0(1,1)),")"

    if(Debug)Write(*,'(A)')"PrintCMatrix(G0)"
    if(Debug)call PrintCMatrix(G0)

  end subroutine CompGreensFunc


  ! 
  ! *** Computes Bulk Green's function G0 for extended cluster ***
  ! 
  subroutine CompG0X( BL, Spin, energy, G0X )
    use util, only: PrintCMatrix
    use constants, only: c_zero, ui
    use parameters, only: eta, DU, UD, DD
   !use lapack_blas, only: zgetri,zgetrf
   !use lapack95, only: zgetri,zgetrf
   !use lapack95
   !use blas95  
    implicit none

    external  zgetri,zgetrf

    type(TBetheLattice), intent(inout) :: BL
    integer, intent(in) :: Spin
    complex*16, intent(in) :: energy
    complex*16, dimension( BL%NSpin,BL%NNeighbs,BL%NAOrbs, BL%NAOrbs ) :: BLSigmak
    complex*16, dimension( BL%NNeighbs,BL%NAOrbs, BL%NAOrbs ) :: Vk_aux
    complex*16, dimension( nx, nx ),intent(out) :: G0X
    integer :: n, k1, k2, ipiv(nx), info, i, j, k, ispin, NNeighbs
    complex*16, dimension( 4*nx  ) :: work
    real :: dos

    Write(*,'(A)')"ENTER CompG0X"
    Write(*,'(A,I4)')"nx = ",nx

    ispin = spin
    if( ispin < 1 .or. ispin > 2 ) then
       print *, "Undefined value for Spin: ", ispin
       stop
    end if

    if (BL%LeadNo == 1 .and. spin == 1 .and. (DU.or.DD)) ispin = 2
    if (BL%LeadNo == 1 .and. spin == 2 .and. (DU.or.DD)) ispin = 1
    if (BL%LeadNo == 2 .and. spin == 1 .and. (UD.or.DD)) ispin = 2
    if (BL%LeadNo == 2 .and. spin == 2 .and. (UD.or.DD)) ispin = 1
    if( spin == 2 .and. BL%NSpin == 1 ) ispin = 1
    NNeighbs = BL%NNeighbs
    n=BL%NAOrbs

    if(Debug)then
      do k=1,NNeighbs
        Write(*,'(A,I2,A,I2,A)')"BL%Vk(",ispin,",",k,",:,:) before call SolveDysonBL"
        call PrintCMatrix(BL%Vk(ispin,k,1:n,1:n))
      end do
    end if

    !Vk_aux = BL%Vk(ispin,1:NNeighbs,1:n,1:n)


    call SolveDysonBL( BL%LeadNo, BLSigmak(ispin,1:NNeighbs,1:n,1:n), energy, BL%H0(ispin,1:n,1:n), BL%Vk(ispin,1:NNeighbs,1:n,1:n), &
         BL%S0(1:n,1:n), BL%Sk(1:NNeighbs,1:n,1:n) )
    !call SolveDysonBL( BL%LeadNo, BLSigmak(ispin,1:NNeighbs,1:n,1:n), energy, BL%H0(ispin,1:n,1:n), Vk_aux, &
    !     BL%S0(1:n,1:n), BL%Sk(1:NNeighbs,1:n,1:n), NNeighbs, n )

    G0X = c_zero

    do i=1,nx
       do j=1,nx
          G0X(i,j)=(energy+ui*1.0d-10)*S0X(i,j)-H0X(ispin,i,j)
       enddo
    enddo
    
    !
    ! Add directional self-energies to outer cluster atoms
    !

    IF (NNeighbs == 6) THEN

    do k1=1,NNeighbs/2  ! Loop over outer cluster atoms
       do k2=1, NNeighbs,2 ! Loop over all BL directions connected to that atom
          if( 2*k1-1 /= k2 )then
          do i=1,n
             do j=1,n
                G0X(k1*n+i,k1*n+j) = G0X(k1*n+i,k1*n+j)-BLSigmak(ispin,k2,i,j)
             end do
          end do
          end if
       end do
    enddo

    ELSE IF (NNeighbs == 12 .OR. NNeighbs == 8 .or. NNeighbs == 4 .or. NNeighbs == 2 ) THEN

    do k1=1,NNeighbs  ! Loop over outer cluster atoms
       do k2=1,NNeighbs ! Loop over all BL directions connected to that atom
          if( k2 /= k1-(-1)**k1 )then
             do i=1,n
                do j=1,n
                   G0X(k1*n+i,k1*n+j) = G0X(k1*n+i,k1*n+j)-BLSigmak(ispin,k2,i,j)
                end do
             end do
          end if
       end do
    enddo

    ELSE 

    PRINT *, "Incorrect number of directions in Bethe lattice: Error n.2"
    STOP

    END IF
    
    call zgetrf(nx,nx,G0X,nx,ipiv,info)
    call zgetri(nx,G0X,nx,ipiv,work,4*nx,info)

    if(Debug)Write(*,'(A)')"PrintCMatrix(G0X)"
    if(Debug)call PrintCMatrix(G0X)
 
  end subroutine CompG0X



  ! 
  ! *** Total charge up to energy E ***
  ! 
  ! Integrates Green's function along imaginary
  ! axis so that no lower energy bound is needed.
  ! Uses routine qromo of Num. Rec. with midpnt
  ! rule up to some point on the path and midinf 
  ! rule for the tail.
  !
  real function TotCharge( E )
    use constants, only: d_pi
    use numeric, only: midpnt, midinf, qromo
    implicit none
    
    real, intent(in) :: E
    integer omp_get_thread_num
    real :: s, q, y0

    E0 = E
    !write(ifu_log,*)omp_get_thread_num(),'in TotCharge',E0

    ! integration from [0:y0] with midpnt rule
    ! and from [y0:inf] with midinf rule 
    ! (assumes integrand decaying approx. ~1/x)
    y0=20.0d0
    
    !s = 0.0d0
    s = 1.0d-30
    call qromo( ReTrG0,0.0d0,y0,s,midpnt)
    q = s/d_pi

    !s = 0.0d0
    s = 1.0d-30
    call qromo( ReTrG0,y0,1.d30,s,midinf)
    q = q + s/d_pi

    q = q + LeadBL(WhichLead)%NAOrbs

    !!print *, "Whichlead = ", WhichLead
    !PRINT *, " E=", E, "    TotCharge=", q

    TotCharge = q-ChargeOffSet
    Write(*,'(A,g15.5,A,g15.5)')"E = ",E,"; TotCharge = ",TotCharge
  end function TotCharge

  ! 
  ! *** Total charge up to energy E ***
  ! 
  ! Integrates Green's function along imaginary
  ! axis so that no lower energy bound is needed.
  ! Uses routine qromo of Num. Rec. with midpnt
  ! rule up to some point on the path and midinf 
  ! rule for the tail.
  !
  real function TotCharge1DBL( E )
    use constants, only: d_pi
    use numeric, only: midpnt, midinf, qromo1DBL
    implicit none
    
    real, intent(in) :: E
    integer omp_get_thread_num
    real :: s, q, y0

    E0 = E
    !write(ifu_log,*)omp_get_thread_num(),'in TotCharge',E0

    ! integration from [0:y0] with midpnt rule
    ! and from [y0:inf] with midinf rule 
    ! (assumes integrand decaying approx. ~1/x)
    y0=20.0d0
    
    s = 0.0d0
!    s = 1.0d-16
    Write(*,'(A,g12.4,A,g15.5,A,g18.6,A)')"call qromo1DBL(ReTrG0,",0.0d0,",",y0,",",s,",midpnt)"
    call qromo1DBL( ReTrG0,0.0d0,y0,s,midpnt)
    q = s/d_pi

    s = 0.0d0
!    s = 1.0d-16
    call qromo1DBL( ReTrG0,y0,1.d30,s,midinf)
    q = q + s/d_pi

    q = q + LeadBL(WhichLead)%NAOrbs

    !!print *, "Whichlead = ", WhichLead
    !PRINT *, " E=", E, "    TotCharge=", q

    TotCharge1DBL = q-ChargeOffSet
    Write(*,'(A,g15.5,A,g15.5)')"E = ",E,"; TotCharge1DBL = ",TotCharge1DBL
  end function TotCharge1DBL


  ! *************************************
  ! Routine to adjust Fermi-level to zero
  ! 1. Estimates upper/lower energy 
  !    boundary of lead DOS EMin/EMax,
  !    above/below which DOS is gauranteed 
  !    to be zero
  ! 2. Searches Fermi level
  ! 3. Shifts on-site Hamiltonian H0 to
  !    adjust Fermi level to zero
  ! *************************************
  subroutine AdjustFermi( BL )
    use parameters, only: ChargeAcc, FermiAcc, BiasVoltage, Glue, Overlap, Nembed
    use constants, only: d_zero
    use numeric, only: bisec, muller_omp, secant_omp, secant, muller
    implicit none

    type(TBetheLattice), intent(inout) :: BL

    integer :: ispin, i, j, cond, max,k 
    real :: DE, EFermi, Q, bias
    real :: E00,E1,E2,E3,Z, Delta, Epsilon

    print *, "Setting Fermi level to zero for Lead ", BL%LeadNo

    ChargeOffSet = d_zero

    WhichLead = BL%LeadNo

    print *, "Searching boundaries [EMin, EMax] such that Int[EMin, EMax] DOS(E) =", 2*BL%NAOrbs, " ( Number of spin orbitals )."

    DE = 10.0d0

    Write(*,'(A)')"*******************************************"
    Write(*,'(A)')"********** Fine tuning for EMin ***********"
    Write(*,'(A)')"*******************************************"
    ! Fine tuning for EMin ...
    do
       BL%EMin = BL%EMin - DE
!       Q = TotCharge( BL%EMin ) ! ORIGINAL CODE.
       if(Nembed(Whichlead)==1)then
         Q = TotCharge1DBL( BL%EMin )
         !Q = TotCharge( BL%EMin )
       else
         Q = TotCharge( BL%EMin )
       end if
       !if( abs(Q) <  ChargeAcc .or. Q < 0.0d0 ) exit       
       !if( abs(Q-BL%NCore) <  0.1d0 .or. Q < 0.0d0 ) exit       
       if( abs(Q-BL%NCore) <  ChargeAcc*2*BL%NAOrbs .or. Q < 0.0d0 ) exit ! ORIGINAL CODE.
       !if( abs(Q-BL%NCore) <  5.0d+0*ChargeAcc*2*BL%NAOrbs .or. Q < 0.0d0 ) exit
       !print *, "EMin=", BL%EMin, "  Charge=", Q
    end do
    print *, "EMin=", BL%EMin, "  Charge=", Q

    Write(*,'(A)')"*******************************************"
    Write(*,'(A)')"********** Fine tuning for EMax ***********"
    Write(*,'(A)')"*******************************************"
    ! Fine tuning for EMax ...
    do
       BL%EMax = BL%EMax + DE
!       Q = TotCharge( BL%EMax ) ! ORIGINAL CODE.
       if(Nembed(Whichlead)==1)then
         Q = TotCharge1DBL( BL%EMax )
         !Q = TotCharge( BL%EMax )
       else
         Q = TotCharge( BL%EMax )
       end if
       !if( abs(Q - 2*BL%NAOrbs) <  ChargeAcc ) exit       
       !if( abs(Q - 2*BL%NAOrbs) <  0.1d0 ) exit       
       if( abs(Q - 2*BL%NAOrbs) <  ChargeAcc*2*BL%NAOrbs ) exit ! ORIGINAL CODE.
       !if( abs(Q - 2*BL%NAOrbs) <  5.0d+0*ChargeAcc*2*BL%NAOrbs ) exit
       !if( BL%Overlap .and. Q > BL%NElectrons .and. Q > 1.8*BL%NAOrbs) exit
       !print *, "EMax=", BL%EMax , "  Charge=", Q
    end do
    print *, "EMax=", BL%EMax , "  Charge=", Q

    Write(*,'(A)')"**************************************************"
    Write(*,'(A,I1,A)')"*********** SEARCH LEAD ",BL%LeadNo," FERMI ENERGY ***********"
    Write(*,'(A)')"**************************************************"
    print *, "Now searching for Fermi energy..."

    ChargeOffSet = BL%NElectrons

    ! First use bisection method to loacalize
    ! the Fermi level very roughly (0.1 eV)
    ! so that the following Muller method
    ! does not get stuck within a band gap
    E1 = BL%EMin+5
    E2 = BL%EMax-5
!    Delta = 0.1d0

    Write(*,'(A)')"*******************************************"
    Write(*,'(A)')"********* 1st estimate with Bisec *********"
    Write(*,'(A)')"************* 1000 iterations *************"
    Write(*,'(A)')"*******************************************"
!    EFermi = Bisec(TotCharge,E1,E2,Delta,100,K) ! ORIGINAL CODE 100 ITERATIONS.
    if(Nembed(Whichlead)==1)then
      Delta = 0.1d0 ! ORIGINAL CODE.
      !Delta = 1.0d-5
      !Delta = 1.0d+1
      EFermi = Bisec(TotCharge1DBL,E1,E2,Delta,1000,K)
      !EFermi = Bisec(TotCharge,E1,E2,Delta,100,K)
    else
      Delta = 0.1d0
      EFermi = Bisec(TotCharge,E1,E2,Delta,100,K) 
    end if

    Write(*,'(A)')"*******************************************"
    Write(*,'(A)')"**** Exact determination Muller/Secant ****"
    Write(*,'(A)')"*******************************************"
    ! Now use Muller or Secant method to determine Fermi level exactly
    E00 = EFermi
    E1 = EFermi-Delta
    E2 = EFermi+Delta    
    Max = 25
    Delta=FermiAcc
    Epsilon=ChargeAcc*BL%NElectrons
    
    !PRINT *, "Muller method:"
    !CALL MULLER_OMP(TotCharge,E00,E1,E2,Delta,Epsilon,Max,EFermi,Z,K,Cond)
     PRINT *, "Secant method:"
     !call SECANT_OMP(TotCharge,E1,E2,Delta,Epsilon,Max,EFermi,DE,Cond,K)
     !call SECANT(TotCharge,E1,E2,Delta,Epsilon,Max,EFermi,DE,Cond,K) ! ORIGINAL CODE.
    if(Nembed(Whichlead)==1)then
      !Delta = 5.0d+1*Delta
      !Epsilon = 5.0d+1*Epsilon
      call SECANT(TotCharge1DBL,E1,E2,Delta,Epsilon,Max,EFermi,DE,Cond,K)
      !call SECANT(TotCharge,E1,E2,Delta,Epsilon,Max,EFermi,DE,Cond,K)
    else
      call SECANT(TotCharge,E1,E2,Delta,Epsilon,Max,EFermi,DE,Cond,K)
    end if
    ChargeOffset = d_zero
    print *, "Bethe lattice Fermi energy = ", EFermi

    bias=0.0d0
    ! Shift on-site Hamiltonian H0 so that EFermi = 0
     if (glue == 1.0)  then
     if (BL%LeadNo == 1) bias=biasvoltage/2.0
     if (BL%LeadNo == 2) bias=-biasvoltage/2.0
     end if

    do ispin=1,BL%NSpin
       do i=1,BL%NAOrbs
          do j=1,BL%NAOrbs
             BL%H0(ispin,i,j)=BL%H0(ispin,i,j)-(EFermi-bias)*BL%S0(i,j)
          end do
       end do
    end do
    if( BL%Overlap )then
       do ispin=1,BL%NSpin
          do i=1,BL%NAOrbs
             do j=1,BL%NAOrbs
                do k=1,BL%NNeighbs
                   BL%Vk(ispin,k,i,j)=BL%Vk(ispin,k,i,j)-(EFermi-bias)*BL%Sk(k,i,j)
                end do
             end do
          end do
          do i=1,nx
             do j=1,nx
                H0X(ispin,i,j)=H0X(ispin,i,j)-(EFermi-bias)*S0X(i,j)
             end do
          end do
       end do
    end if

    ! Also shift EMin, EMax
    BL%EMin = BL%EMin - EFermi + bias
    BL%EMax = BL%EMax - EFermi + bias

  end subroutine AdjustFermi


  ! *************************************************************
  ! Real part of trace of Bulk Green's function on imaginary axis
  ! - For charge integration along imaginary axis
  ! *************************************************************
  real function ReTrG0( ImE )
    use constants, only: ui, d_zero
    use numeric, only: ctrace
    implicit none

    real, intent(in) :: ImE

    complex*16 :: zenergy 
    complex*16, dimension(LeadBL(WhichLead)%NAOrbs,LeadBL(WhichLead)%NAOrbs) :: G0
    complex*16, dimension(nx,nx) :: G0X, GS0X

    integer :: ispin, NSpin, NAO
    
    NAO = LeadBL(WhichLead)%NAOrbs
    NSpin = LeadBL(WhichLead)%NSpin

    zenergy = E0 + ui*ImE

    ReTrG0 = d_zero
    do ispin = 1, NSpin
       if( LeadBL(WhichLead)%Overlap )then
          call CompG0X( LeadBL(WhichLead), ispin, zenergy, G0X ) 
          GS0X = MATMUL( G0X, S0X )
          ReTrG0 = ReTrG0 + real(CTrace(GS0X(1:NAO,1:NAO)))          
       else
          call CompGreensFunc( LeadBL(WhichLead), ispin, zenergy, G0 ) 
          ReTrG0 = ReTrG0 + real(CTrace(G0))
       end if
    end do
    if(NSpin==1) ReTrG0=2d0*ReTrG0
    if(Debug)Write(*,'(A,g15.5)')"ReTrG0 = ",ReTrG0
  end function ReTrG0

  ! *************************************************************
  ! Real part of trace of Bulk Green's function on imaginary axis
  ! - For charge integration along imaginary axis
  ! *************************************************************
  real function ReTrG01DBL( ImE ) ! NOT USED NOW FOR 1DBL. DUPLICATE ImE MAKES INTEGRATION OF LEAD CHARGE EASIER.
    use constants, only: ui, d_zero
    use numeric, only: ctrace
    implicit none

    real, intent(in) :: ImE

    complex*16 :: zenergy
    complex*16, dimension(LeadBL(WhichLead)%NAOrbs,LeadBL(WhichLead)%NAOrbs) :: G0
    complex*16, dimension(nx,nx) :: G0X, GS0X

    integer :: ispin, NSpin, NAO

    NAO = LeadBL(WhichLead)%NAOrbs
    NSpin = LeadBL(WhichLead)%NSpin

!    zenergy = E0 + ui*ImE ! ORIGINAL CODE.
    zenergy = E0 + ui*2.0d0*ImE ! DUPLICATE ImE MAKES INTEGRATION OF LEAD CHARGE EASIER.

    ReTrG01DBL = d_zero
    do ispin = 1, NSpin
       if( LeadBL(WhichLead)%Overlap )then
          call CompG0X( LeadBL(WhichLead), ispin, zenergy, G0X )
          GS0X = MATMUL( G0X, S0X )
          ReTrG01DBL = ReTrG01DBL + real(CTrace(GS0X(1:NAO,1:NAO)))
       else
          call CompGreensFunc( LeadBL(WhichLead), ispin, zenergy, G0 )
          ReTrG01DBL = ReTrG01DBL + real(CTrace(G0))
       end if
    end do
    if(NSpin==1) ReTrG01DBL=2d0*ReTrG01DBL
    if(Debug)Write(*,'(A,g15.5)')"ReTrG01DBL = ",ReTrG01DBL
  end function ReTrG01DBL

  !
  ! *** Computes rotation matrix TR for direction k ***
  !
  subroutine getRotMat( BL, k, TR ) 
    use cluster, only: vpb, cmatr
    implicit none

    type(TBetheLattice),intent(IN) :: BL
    integer, intent (in) :: k
    complex*16, dimension(BL%NAOrbs,BL%NAOrbs), intent(inout) :: TR

    ! Parameter used in CMATR for the 
    ! size of the rotaion matrix
    !integer, PARAMETER :: maxtrd=10
    
    real, dimension(BL%NAOrbs,BL%NAOrbs) :: TRR
    integer :: n, i, j, LeadNo
    real :: sum, rl, rm, rn

    n = BL%NAOrbs

    sum=dsqrt( &
         vpb(BL%LeadNo,1,k)*vpb(BL%LeadNo,1,k)+ &
         vpb(BL%LeadNo,2,k)*vpb(BL%LeadNo,2,k)+ &
         vpb(BL%LeadNo,3,k)*vpb(BL%LeadNo,3,k) )
    rl=vpb(BL%LeadNo,1,k)/sum
    rm=vpb(BL%LeadNo,2,k)/sum
    rn=vpb(BL%LeadNo,3,k)/sum

    ! * compute real rotation matrix TRR
    call cmatr(n,BL%AOT,rl,rm,rn,TRR)

    ! * and save in complex matrix array
    do i=1, n
       do j=1, n
          TR(i,j) = TRR(i,j)
       end do
    end do
  end subroutine getRotMat

  
  !
  ! *** Read Parameters of Bethe Lattice from file ***
  ! 
  subroutine ReadBLParameters( BL )
    use parameters, only: BLPar, Overlap
    use ANTCommon
    use iflport, only: getenv
    implicit none

    type(TBetheLattice), intent(inout) :: BL
    integer, parameter :: fname_len = 100
    character(LEN=fname_len-10) :: bl_dir_name
    integer :: dname_len, stat
!   external cgetenv
    character(LEN=fname_len) :: FName
    integer :: ios, i, nline, NAOrbs, NSpin, NElectrons, NCore, ipt, idt, ift, aocount
    character(LEN=50) :: SetName
    character :: ChAOT
    character(len=10) :: orblist = "spdfghijkl"
    integer :: orbindex, oldorbindex, shellcount, aocountinshell
    
    orbindex=0
    oldorbindex=0
    ! Obtain environment variable containing path for Bethe lattice parameters
    !call cgetenv( bl_dir_name, dname_len, "ALACANT\0" )
     call getenv( "ALACANT", bl_dir_name)
    !if( dname_len == 0 )then
    !   print *, "ERROR: Environment variable ALACANT is undefined. Abort."
    !   stop
    !end if
    !write (UNIT=FName,FMT='(A,A,I3.3,A)'), bl_dir_name(1:dname_len), "/BLDAT/BL", BL%AtmNo, ".dat"
     write (UNIT=FName,FMT='(A,A,I3.3,A)'), trim(bl_dir_name), "/BLDAT/BL", BL%AtmNo, ".dat"
     print *, "Open file ", fname, " to read Bethe lattice parameters."

     open( UNIT=ifu_bl, FILE=FName, IOSTAT=ios, STATUS='OLD')
     if( ios /= 0 ) then
        print *, "Error: Cannot open file ", fname
        stop
     end if
     
     do
        nline = FindKeyWord( ifu_bl, "BEGINSET" )
        if( nline > 0 )  then
           read (UNIT=ifu_bl,FMT=*,IOSTAT=ios) SetName
           if( ios /= 0 )then
              print *, "Format ERROR: in line ", nline
              stop
           end if
           if( SetName == BLPar(BL%LeadNo) )then
              print *, "Reading ", SetName, " parameters."
             read (UNIT=ifu_bl,FMT=*,IOSTAT=ios) NAOrbs, NSpin, NElectrons, NCore
             Write(*,'(A)') "NAOrbs, NSpin, NElectrons, NCore"
             Write(*,'(I2,I2,I2,I2)') NAOrbs, NSpin, NElectrons, NCore
             if( ios /= 0 )then
                print *, "Format ERROR: in line ", nline
                stop
             end if
             Write(*,'(A,I2,A,I2)') "BL%NAOrbs=",BL%NAOrbs,"; NAOrbs",NAOrbs
             if( BL%NAOrbs /= NAOrbs ) then
                !BL%NAOrbs = NAOrbs
                print *, "ERROR: NAOrbs read from BL data base not equal to NAOrbs of electrode plane in cluster."
                stop
             end if
             BL%NSpin = NSpin
             BL%NElectrons = NElectrons
             BL%NCore = NCore
             aocount = 0
             BL%nso = 0
             BL%npo = 0
             BL%ndo = 0
             BL%nfo = 0
             do
                if( aocount > BL%NAOrbs ) then
                   print *, "ERROR: NAOrbs not compatible with given shell structure."
                   stop 
                end if
                if( aocount == BL%NAOrbs ) exit
                read (UNIT=ifu_bl,FMT='(A1)',IOSTAT=ios), ChAOT
                Write(*,'(A,A)')"ChAOT = ",ChAOT

                orbindex = INDEX(orblist,ChAOT)
                Write(*,'(A,A,A,I2)')"ChAOT = ",ChAOT,"; ORBINDEX = ",orbindex
                if(DebugBethe)Pause
                if(orbindex <= oldorbindex)then
                  shellcount = shellcount+1
                  aocountinshell = 0
                end if
                oldorbindex=orbindex
                Write(*,'(A,A,A,I2)')"ChAOT = ",ChAOT,"; ORBINDEX = ",orbindex
                if(DebugBethe)Pause
                if( ChAOT == "s" ) then
                   aocountinshell = aocountinshell + 1
                   aocount = aocount + 1
                   BL%AOT( aocount ) = 0
                   BL%SHT( aocount ) = shellcount
                   BL%nso = BL%nso +1
                else if( ChAOT == "p" ) then
                   do ipt=1,3
                      aocountinshell = aocountinshell + 1
                      aocount = aocount + 1
                      BL%AOT( aocount ) = ipt
                      BL%SHT( aocount ) = shellcount
                      BL%npo = BL%npo + 1
                   end do
                else if( ChAOT == "d" ) then
                   do idt=4,8
                      aocountinshell = aocountinshell + 1
                      aocount = aocount + 1
                      BL%AOT( aocount ) = idt
                      BL%SHT( aocount ) = shellcount
                      BL%ndo = BL%ndo + 1
                   end do
                else if( ChAOT == "f" ) then
                   do ift=9,15
                      aocountinshell = aocountinshell + 1
                      aocount = aocount + 1
                      BL%AOT( aocount ) = ift
                      BL%SHT( aocount ) = shellcount
                      BL%nfo = BL%nfo + 1
                   end do
                else
                   print *, "ERROR: Illegal atomic orbital type identifier found: ", ChAOT
                   stop
                end if
             end do
             exit
          end if
       else 
          print *, "Parameter set not found. Abort."
          stop
       end if
    end do

    BL%Matrix = .false.

    do 
       call readline( BL, ifu_bl, ios )       
       nline = nline+1
       if( ios > 0 ) then 
          print*, "  in line No. " , nline
          stop
       end if
       if( ios /= 0 ) exit
    end do
    print*, "Done."
    REWIND ifu_bl
!    close(ifu_bl)
    close(ifu_bl)
    
    if (Overlap < 0.01 ) BL%Overlap = .false.

  end subroutine ReadBLParameters
  

  !
  ! *** read and evaluate a line from parameter file ***
  ! 
  subroutine readline( BL, inpfile, ios )
    use constants, only: Hart, Ryd
    implicit none

    type(TBetheLattice), intent(inout) :: BL
    integer, intent(in) :: inpfile
    integer, intent(inout) :: ios
    
    character(len=1)  :: eqsign
    character(len=1)  :: comment
    character(len=10) :: keyword
    real            :: rval
    integer           :: ival, i, j, nss, nps, nds, nfs
    real, save      :: unit = Hart
    real, dimension(MaxDim) :: rvec

    integer, save :: ispin = 1

    ! Jump comment lines
    read (unit=inpfile,fmt=*,iostat=ios), comment
    if( ios /= 0 .or. trim(comment) == '!' ) return
    backspace inpfile

    read (unit=inpfile,fmt=*,iostat=ios), keyword
    if( ios /= 0 ) then
       if ( ios > 0 ) print*, "Format ERROR 1: "
       return 
    end if

    ! Evaluating keywords 
    if( keyword == "ENDSET" ) then
       ! Terminate reading
       ios = -1

    else if( keyword == "ISPIN" ) then
       backspace inpfile
       read (unit=inpfile,fmt=*,iostat=ios), keyword, eqsign, ival      
       if( ios /= 0 .or. eqsign /= '=' ) then
          if ( ios > 0 ) print*, "Format ERROR 2: "
          return 
       end if       
       ispin = ival

    else if( keyword == "BLFERMISTART" ) then
       backspace inpfile
       read (unit=inpfile,fmt=*,iostat=ios), keyword, eqsign, ival
       if( ios /= 0 .or. eqsign /= '=' ) then
          if ( ios > 0 ) print*, "Format ERROR 2: "
          return
       end if
       BL%FermiStart = ival

    !Change energy unit to Ryd (for Papacon parameters)
    else if( keyword == "RYD" ) then
       unit = Ryd

    else if( keyword == "EV" ) then
       unit = 1.0d0

    else
       backspace inpfile
       read (unit=inpfile,fmt=*,iostat=ios), keyword, eqsign, rval
       Write(*,'(A)')"keyword = rval "
       Write(*,'(A,A,g15.5)')keyword, eqsign, rval
       if(DebugBethe)Pause
       print *, keyword, eqsign, rval      
       if( ios /= 0 .or. eqsign /= '=' ) then
          if ( ios > 0 ) print*, "Format ERROR 3: "
          return 
       end if

       ! number of s-shells
       nss = BL%nso
       ! number of p-shells
       nps = BL%npo/3
       ! number of d-shells
       nds = BL%ndo/5
       ! number of f-shells
       nfs = BL%nfo/7

       select case ( keyword )
          ! ******************
       case( "H0" )  
          BL%Matrix = .true.
          !backspace inpfile ! IMPORTANT TO COMMENT THIS. WORKS FOR C.SALGADO ON 2016-04-23.
          ! Read in complete on-site Hamiltonian
          do i=1,BL%NAOrbs
             read (unit=inpfile,fmt=*,iostat=ios), (rvec(j),j=1,BL%NAOrbs)
             do j=1,BL%NAOrbs
                BL%H0(ispin,i,j)=rvec(j)
             end do
             !!print '(100F13.4)', (BL%H0(ispin,i,j),j=1,BL%NAOrbs)
          end do
          ! ******************
       case( "Vk" )  
          BL%Matrix = .true.
          !backspace inpfile ! IMPORTANT TO COMMENT THIS. WORKS FOR C.SALGADO ON 2016-04-23.
          ! Read in complete hopping matrix
          do i=1,BL%NAOrbs
             read (unit=inpfile,fmt=*,iostat=ios), (rvec(j),j=1,BL%NAOrbs)
             do j=1,BL%NAOrbs
                BL%Vk(ispin,:,i,j)=rvec(j)
             end do
             !!print '(100F13.4)', (BL%Vk(ispin,1,i,j),j=1,BL%NAOrbs)
          end do
          ! ******************
       case( "S0" )  
          BL%Matrix = .true.
          BL%Overlap = .true.
          !backspace inpfile ! IMPORTANT TO COMMENT THIS. WORKS FOR C.SALGADO ON 2016-04-23.
          ! Read in complete on-site Overlap matrix
          do i=1,BL%NAOrbs
             read (unit=inpfile,fmt=*,iostat=ios), (rvec(j),j=1,BL%NAOrbs)
             do j=1,BL%NAOrbs
                BL%S0(i,j)=rvec(j)
             end do
             !!print '(100F13.4)', (BL%S0(i,j),j=1,BL%NAOrbs)
          end do
          ! ******************
       case( "Sk" )  
          BL%Matrix = .true.
          BL%Overlap = .true.
          !backspace inpfile ! IMPORTANT TO COMMENT THIS. WORKS FOR C.SALGADO ON 2016-04-23.
          ! Read in complete inter-site overlap matrix
          do i=1,BL%NAOrbs
             read (unit=inpfile,fmt=*,iostat=ios), (rvec(j),j=1,BL%NAOrbs)
             do j=1,BL%NAOrbs
                BL%Sk(:,i,j)=rvec(j)
             end do
             !!print '(100F13.4)', (BL%Sk(1,i,j),j=1,BL%NAOrbs)
          end do
          !!end select
          !!else
          !!select case ( keyword )
          !
          ! *****************
          ! ENERGY PARAMETERS
          ! *****************
          !
       case( "es"  )
          BL%es(ispin) = rval*unit
          ! ******************
       case( "ep"  )
          BL%ep(ispin) = rval*unit
          ! ******************
       case( "edd" )
          BL%edd(ispin) = rval*unit
          ! ******************
       case( "edt" )
          BL%edt(ispin) = rval*unit
          ! ******************
       case( "ef" )
          BL%ef(ispin) = rval*unit
          !
          ! ******************
          ! HOPPING PARAMETERS
          ! ******************
          !
       case( "sss" )
          BL%sss(ispin) = rval*unit
          ! ******************
       case( "sps" )
          BL%sps(ispin) = rval*unit
          ! ******************
       case( "pps" )
          ! otherwise take scalar value
          BL%pps(ispin) = rval*unit
          ! ******************
       case( "ppp" )
          BL%ppp(ispin) = rval*unit
          ! ******************
       case( "sds" )
          BL%sds(ispin)= rval*unit
          ! ******************
       case( "pds" )
          BL%pds(ispin)= rval*unit
          ! ******************
       case( "pdp" )
          BL%pdp(ispin)= rval*unit
          ! ******************
       case( "dds" )
          BL%dds(ispin)= rval*unit
          ! ******************
       case( "ddp" )
          BL%ddp(ispin)= rval*unit
          ! ******************
       case( "ddd" )
          BL%ddd(ispin)= rval*unit 
          ! ******************
       case( "vf" )
          BL%vf(ispin)= rval*unit 
          ! ******************
          !
          ! ******************
          ! OVERLAP PARAMETERS
          ! ******************
          !
      case( "S_sss" )
          BL%Overlap = .true.
          BL%S_sss = rval
          ! ******************
       case( "S_sps" )
          BL%Overlap = .true.
          BL%S_sps = rval
          ! ******************
       case( "S_pps" )
          BL%Overlap = .true.
          BL%S_pps = rval
          ! ******************
       case( "S_ppp" )
          BL%Overlap = .true.
          BL%S_ppp = rval
          ! ******************
       case( "S_sds" )
          BL%Overlap = .true.
          BL%S_sds = rval
          ! ******************
       case( "S_pds" )
          BL%Overlap = .true.
          BL%S_pds = rval
          ! ******************
       case( "S_pdp" )
          BL%Overlap = .true.
          BL%S_pdp = rval
          ! ******************
       case( "S_dds" )
          BL%Overlap = .true.
          BL%S_dds = rval
          ! ******************
       case( "S_ddp" )
          BL%Overlap = .true.
          BL%S_ddp = rval
          ! ******************
       case( "S_ddd" )
          BL%Overlap = .true.
          BL%S_ddd = rval
          ! ******************
       case( "S_f" )
          BL%Overlap = .true.
          BL%S_f = rval
          ! ******************
       case default
          print*, "ERROR - Undefined keyword: ", keyword
          ios = 1 ! Abort reading 
       end select
    end if

  end subroutine readline


  !
  ! *** look for a keyword in input file ***
  !
  integer function FindKeyWord( inpfile, keyword )
    implicit none

    integer, intent(in) :: inpfile
    character(LEN=*),intent(in) :: keyword
    character(LEN=10) :: string
    integer :: nline = 0, ios

    do
       nline = nline + 1
       read (UNIT=inpfile,FMT=*,IOSTAT=ios), string
       if( ios /= 0 ) then
          FINDKEYWORD = -1
          return
       end if
       if( string == keyword ) exit
    end do
    FINDKEYWORD = nline   
  end function FindKeyWord

  END MODULE BetheLattice

