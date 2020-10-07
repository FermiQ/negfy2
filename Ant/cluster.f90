!*********************************************************!
!*********************  ANT.G-2.4.1  *********************!
!*********************************************************!
!                                                         !
!   Copyright (c) by                                      !
!                                                         !
!   Juan Jose Palacios (1)                                !
!   David Jacob (2)                                       !
!   Maria Soriano (1)                                     !
!   Angel J. Perez-Jimenez (3)                            !
!                                                         !
!  (1) Departamento de Fisica de la Materia Condensada    !
!      Universidad Autonoma de Madrid                     !      
!      28049 Madrid (SPAIN)                               !
!  (2) Theory Department                                  !
!      Max-Planck-Institute for Microstructure Physics    !
!      Halle, 06120 (GERMANY)                             !
!  (3) Departamento de Quimica Fisica                     !
!      Universidad de Alicante                            !
!      03690 Alicante (SPAIN)                             !
!                                                         !
!*********************************************************!
  MODULE cluster
!*********************************************************!
!  Module for analysis of system provided in gaussian     !
!  input file .com                                        !
!**********************************************************
  USE preproc !, ONLY: MaxAtm, MaxSh
  USE parameters, ONLY: NEmbed,NAtomEl
  IMPLICIT NONE
  SAVE
  PRIVATE

  PUBLIC :: AreConnected, LoAOrbNo, HiAOrbNo, NDirections,GetDir,NNeigBL,NEmbedBL
  PUBLIC :: LeadAtmNo, LeadNAOrbs, VPB, NAMol, NALead, NAOMol, NAOAtom, AnalyseCluster, cmatr 
  PUBLIC :: AnalyseClusterElectrodeOne, AnalyseClusterElectrodeTwo
  PUBLIC :: NConnect
  PUBLIC :: FillEl

  integer, PARAMETER :: nvec = 12

  real  :: vpb1(3,nvec), vpb2(3,nvec) 
  integer :: ndir(MaxAtm), nvbet(MaxAtm,nvec) 
  integer :: ifrpl(MaxAtm), norbmt
  integer :: ANLead1, ANLead2, nlead1, nmol, nlead2, nneig1, nneig2, NAtomData
  integer :: nn1, nn2

  integer, DIMENSION(MaxAtm) :: ANMol, NAO, LAO, HAO, NSh, AN
  CHARACTER, Dimension(100,MaxAtm) :: ShAtm  
  real,  DIMENSION(MaxAtm) :: XL1, YL1, ZL1, XM, YM, ZM, XL2, YL2, ZL2

CONTAINS

  ! *** If an atom of the cluster is connected to the Bethe-lattice ***
  logical FUNCTION AreConnected( iAtom, LeadNo )
    IMPLICIT NONE
    integer, INTENT(in) :: iAtom, LeadNo
    if(.not.(Nembed(LeadNo)==1))then
      AreConnected = ( ifrpl( iAtom ) == LeadNo )
    else
      AreConnected = ( ifrpl( iAtom+((-1)**(LeadNo)) ) == LeadNo )
    end if
  END FUNCTION AreConnected
  
  ! *** Lowest atomic orbital on Atom ***
  integer FUNCTION LoAOrbNo ( iAtom )
    IMPLICIT NONE
    integer, INTENT(in) :: iAtom
    LoAOrbNo = LAO(iAtom)
  END FUNCTION LoAOrbNo

  ! *** Highest atomic orbital on Atom ***
  integer FUNCTION HiAOrbNo ( iAtom )
    IMPLICIT NONE
    integer, INTENT(in) :: iAtom
    HiAOrbNo = HAO(iAtom)
  END FUNCTION HiAOrbNo

  ! *** Number of directions ***
  integer FUNCTION NDirections( iAtom )
    IMPLICIT NONE
    integer, INTENT(in) :: iAtom
    NDirections = ndir(iAtom)
  END FUNCTION NDirections

  ! *** Get n-th Direction on Atom ***
  integer FUNCTION GetDir( iAtom, n )
    IMPLICIT NONE
    integer, INTENT(in) :: iAtom, n
    GetDir = nvbet( iAtom, n )
  END FUNCTION GetDir

  ! *** conventional atomic number of a lead ***
  integer FUNCTION LeadAtmNo( LeadNo )
    IMPLICIT NONE
    integer, INTENT(in) :: LeadNo
    IF( LeadNo == 1 )THEN
       LeadAtmNo = ANLead1
    ELSE
       LeadAtmNo = ANLead2
    END IF
  END FUNCTION LeadAtmNo

  ! *** Number of atomic orbitals of a lead atom ***
  integer FUNCTION LeadNAOrbs( LeadNo )
    USE g09Common, ONLY: GetNAtoms
    IMPLICIT NONE
    integer, INTENT(in) :: LeadNo
    IF( LeadNo == 1)THEN
       LeadNAOrbs = NAO( 1 )
       Write(*,'(A,I2)')"NAOrbs(1)= NAO(1)=",NAO( 1 )
    ELSE
       LeadNAOrbs = NAO( GetNAtoms() )
       Write(*,'(A,I2)')"GetNAtoms()=",GetNAtoms()
       Write(*,'(A,I2)')"NAOrbs(GetNAtoms())= NAO(GetNAtoms())=",NAO( GetNAtoms() )
    END IF
  END FUNCTION LeadNAOrbs

  ! *** Direction vector component for direction k of Bethe lattice ***
  real FUNCTION VPB( LeadNo, i, k )
    IMPLICIT NONE
    integer, INTENT(in) :: LeadNo, i, k
    IF( LeadNo == 1 ) VPB=vpb1(i,k) 
    IF( LeadNo == 2 ) VPB=vpb2(i,k) 
  END FUNCTION VPB


  ! *** Number of atoms in molecule (i.e. not leads part of cluster) ***
  integer FUNCTION NAMol()
    NAMol = nmol
  END FUNCTION NAMol

  ! *** Number of lead atoms ***
  integer FUNCTION NALead( LeadNo )
    IMPLICIT NONE
    integer, INTENT(in) :: LeadNo
    IF( LeadNo == 1 ) NALead = nlead1
    IF( LeadNo == 2 ) NALead = nlead2
  END FUNCTION NALead

  ! *** Number of lead atoms connected to Bethe lattice ***
  integer FUNCTION NConnect( LeadNo )
    IMPLICIT NONE
    integer, INTENT(in) :: LeadNo
    IF( LeadNo == 1 ) NConnect = nn1
    IF( LeadNo == 2 ) NConnect = nn2
  END FUNCTION NCONNECT

  ! *** Total number of orbitals of molecule ***
  integer FUNCTION NAOMol()
    IMPLICIT NONE
    NAOMol = NOrbMT
  END FUNCTION NAOMol

  ! *** Get number of atomic orbitals of an atom ***
  integer FUNCTION NAOAtom( iAtom )
    IMPLICIT NONE
    integer, INTENT(in) :: iAtom
    NAOAtom = NAO( iAtom )
  END FUNCTION NAOAtom

  ! *** Get number of near neighbor atoms ***
  integer FUNCTION NNeigBL( LeadNo )
    IMPLICIT NONE
    integer, INTENT(in) :: LeadNo
    IF( LeadNo == 1 ) NNeigBL = nneig1
    IF( LeadNo == 2 ) NNeigBL = nneig2
  END FUNCTION NNeigBL

  integer FUNCTION NEmbedBL(i)
    IMPLICIT NONE
    integer, INTENT(in) :: i
    NEmbedBL = NEmbed(i)
  END FUNCTION NEmbedBL

  !***************************************************
  !*                                                 *
  !* Subroutine to analyse the cluster               *
  !*                                                 *
  !*      Old name: Subroutine MK_B_L by Angel       *
  !*                                                 *
  !*      Determine the positions and type of atoms  *
  !*      in the cluster and the crystal planes of   *
  !*      the contact                                *
  !*                                                 *
  !***************************************************
  SUBROUTINE AnalyseCluster
    use parameters, only: ANT1DInp, smalld, small, PlBethe1, PlBethe2, NoCloseHex, ElType
    USE preproc, ONLY: MaxAtm
    USE g09Common, ONLY: GetNShell, GetAtm4Sh, Get1stAO4Sh, GetNBasis, GetAN, GetAtmChg, GetAtmCo, GetNAtoms, &
       GetShellT, GetShellC
    use ANTCommon
    IMPLICIT NONE

    real,    PARAMETER :: sq2inv=0.707106781
    integer :: dos=2
    integer, PARAMETER :: MaxEl=104,ein=1

    integer, DIMENSION(3), PARAMETER :: AOT = (/ 1,2,3 /)

    real :: d1,d2,ddd,scalar                             
    integer :: n,nt
    real, DIMENSION(3,MaxAtm) :: v
    real, DIMENSION(3) :: vv
    real :: vb(3,12)
    real :: CQ(3),CQp(3,MaxAtm),ztotp(MaxAtm)
    integer, DIMENSION(MaxAtm) :: iplane, nfrsp, nlstp, ntotp
    real :: u3(3),bb(3),aplane(3,MaxAtm), vpr(3,nvec), ud(3,MaxAtm,nvec), vprt(3,nvec)
    integer :: nvpl(MaxAtm), invpl(MaxAtm),nbethe       
    integer :: IEl(MaxEl+1)

    integer :: i, ntot, nsw, nplane, j, l, iplfront1, iplfront2, k, icopl, &
         iii, jjj, i1, iivec, iil, kk, ll, lerr, nj, k1, ndi, ndirr, iatom, jatom, nao4sh
    
    real :: alpha, eta, smallp, pi, one, zero,au2ang, dvec, ztot, &
         u1x, u1y, u1z, u2x, u2y, u2z, bbnorm, product, u3norm, d2cq, dmax2, dmax3, &
         dtemp, xupcq, yupcq, zupcq, coscqpcq, ddx, ddy, ddz, dist, angvec, &
         xx, yy, zz, cosudvpr, yyy, zzz, vnorm, coscqpvpr

    ! Coordinates of Bethe lattice atoms for each electrode
    real, DIMENSION(MaxAtm*10) :: xbl1, ybl1, zbl1,  xbl2, ybl2, zbl2
    ! Number of Bethe lattice atoms for each electrode
    integer :: nblatoms1, nblatoms2, ibl
    ! Coordnates of a Bethe lattice atom
    real :: xbla, ybla, zbla
    ! Added by C. Salgado to work with Geometry
    real,  parameter :: PI_8  = 4 * atan (1.0_8)
    real :: cross(3)
    real :: crossmod
    integer :: nbethecount
    
    !C
    CALL FillEl(ein,MaxEl,IEl)
    !C Setting to zero all arrays ...
    ifrpl=0
    iplane=0
    nfrsp=0
    nlstp=0
    ntotp=0       
    nvpl=0
    invpl=0
    ndir=0
    nvbet=0
    ud=0.0d0
    vpb1=0.0d0
    vpb2=0.0d0
    vprt=0.0d0
    vpr=0.0d0
    !
    !    DEFINITION OF LOCAL VARIABLES
    !
    smallp = 1.d-2
    pi = ACOS(-1.)
    one = 1.d0
    zero = 0.d0
    au2ang = 0.52918d0
    dvec = 3.0/au2ang
    !
    !    DETERMINING THE NO. OF ORBITALS PER ATOM
    !
    ntot=0
    DO i=1,GetNShell()-1
       IF (GetAtm4Sh(i).NE.GetAtm4Sh(i+1)) THEN 
          ! Number of orbitals on atom center GetAtm4Sh(i)
          NAO(GetAtm4Sh(i))=Get1stAO4Sh(i+1)-(ntot+1)
          ! Highest orbital number (within cluster) on atom center GetAtm4Sh(i)
          HAO(GetAtm4Sh(i))=Get1stAO4Sh(i+1)-1
          ! Lowest orbital number (within cluster) on atom center GetAtm4Sh(i)
          LAO(GetAtm4Sh(i))=HAO(GetAtm4Sh(i))-NAO(GetAtm4Sh(i))+1
          ntot=ntot+NAO(GetAtm4Sh(i))
       ENDIF
    ENDDO
    NAO(GetAtm4Sh(GetNShell()))=GetNBasis()-ntot
    LAO(GetAtm4Sh(GetNShell()))=HAO(GetAtm4Sh(GetNShell())-1)+1
    HAO(GetAtm4Sh(GetNShell()))=LAO(GetAtm4Sh(GetNShell()))+NAO(GetAtm4Sh(GetNShell()))-1
   
    NSh=0
    do i=1,GetNShell() 
       ! increase number of shells by one for corresponding atom
       iatom=GetAtm4Sh(i)
       NSh(iatom)=NSh(iatom)+1
!       print '(I4,I4,I2,I2)', iatom, i, GetShellT(i), GetShellC(i) 
       ! s-shell
       if( GetShellT(i) == 0 ) ShAtm(NSh(iatom),iatom) = 's'
       ! pure p-shell
       if( GetShellT(i) == 1 .and. GetShellC(i) == 1 ) ShAtm(NSh(iatom),iatom) = 'p'
       ! sp-shell
       if( GetShellT(i) == 1 .and. GetShellC(i) == 0 ) then
          ShAtm(NSh(iatom),iatom) = 's'
          NSh(iatom)=NSh(iatom)+1
          ShAtm(NSh(iatom),iatom) = 'p'
       end if
       ! pure d-shell
       if( GetShellT(i) == 2 .and. GetShellC(i) == 2 ) ShAtm(NSh(iatom),iatom) = 'd'
       ! spd-shell
       if( GetShellT(i) == 2 .and. GetShellC(i) == 0 )then
          ShAtm(NSh(iatom),iatom) = 's'
          NSh(iatom)=NSh(iatom)+1
          ShAtm(NSh(iatom),iatom) = 'p'
          NSh(iatom)=NSh(iatom)+1
          ShAtm(NSh(iatom),iatom) = 'd'
       end if
       ! f-shell
       if( GetShellT(i) == 3 ) ShAtm(NSh(iatom),iatom) = 'f'
       ! g-shell
       if( GetShellT(i) == 4 ) ShAtm(NSh(iatom),iatom) = 'g'
    end do

    NAtomData=0
    do iatom=1,GetNAtoms()
       AN(iatom)=GetAN(iatom)
       do jatom=1,iatom-1
          if( AN(iatom) == mod(AN(jatom),100) .and. NAO(iatom) == NAO(jatom) .and. NSh(iatom) == NSh(jatom) )then
             AN(iatom) = AN(jatom)
             exit
          end if
       end do
       ! if atomic number not found in list 
       if( iatom == jatom )then
          ! increment number of AtomData blocks to write
          NAtomData=NAtomData+1
          ! Find same last atomic number modulo 100
          do jatom=iatom-1,1,-1
             if( AN(iatom) == mod(AN(jatom),100) )then
                AN(iatom)=AN(jatom)+100
                exit
             end if
          end do
       end if
    end do

    if(ANT1DInp)then
       open( ifu_ant, file=trim(ant1dname)//'.ant', status='unknown' )
       write( ifu_ant, '(A)'),    "&Parameters"
       write( ifu_ant, '(A,A)'),  "Lead1File = ", 'bl1.'//trim(ant1dname)//'.dat'
       write( ifu_ant, '(A,A)'),  "Lead2File = ", 'bl2.'//trim(ant1dname)//'.dat'
       write( ifu_ant, '(A,A)'),  "Lead1XYZ = ", 'bl1.'//trim(ant1dname)//'.xyz'      
       write( ifu_ant, '(A,A)'),  "Lead2XYZ = ", 'bl2.'//trim(ant1dname)//'.xyz'      
       write( ifu_ant, '(A,A)'),  "DevFile = ", 'dev.'//trim(ant1dname)//'.dat'
       write( ifu_ant, '(A,A)'),  "DevXYZ = ", 'dev.'//trim(ant1dname)//'.xyz'      
       write( ifu_ant, '(A)'), "Bethe = .true."       
       write( ifu_ant, '(A,I2)'), "NAtomData = ",NAtomData      
       write( ifu_ant, '(A)'),    "/"      
       do iatom=1,GetNAtoms()
          do jatom=1,iatom-1
             if( AN(iatom) == AN(jatom) ) exit
          end do
          if( jatom == iatom )then
             write(ifu_ant, '(A)'), "&AtomData"
             write(ifu_ant, '(A,I3)'), "AN = ", AN(iatom)
             write(ifu_ant, '(A,100(A2))' ), "AtShells =", (ShAtm(i,iatom),i=1,NSh(iatom))
             write(ifu_ant, '(A)'), "/"
          end if
       end do
       close( ifu_ant )
    end if

    WRITE(IFU_LOG,*) '----------------------------------------------------------'
    WRITE(IFU_LOG,*) 'Analyzing cluster for the connection of the  Bethe Lattice'
    WRITE(IFU_LOG,*) '----------------------------------------------------------'
    !
    !    DETERMINING THE POSITIONS AND TYPE OF CLUSTER ATOMS
    !    AS WELL AS THE CENTER OF CHARGE OF THE MOLECULE
    !
    ! Los datos deben introducirse:
    !            Planos al que se adjunta la red de Bethe por la izquierda
    !            Otros Atomos del cluster de la izquierda
    !            Sistema molecular 
    !            Otros Atomos del cluster de la derecha
    !            Planos al que se adjunta la red de Bethe por la derecha
    !
    nlead1=0
    nlead2=0
    NOrbMT = 0
    nmol = 0
    nsw = 0
    CQ(1) = 0.d0
    CQ(2) = 0.d0
    CQ(3) = 0.d0
    ztot = 0.d0

    ANLead1 = GetAN(1)
    ANLead2 = GetAN(GetNAtoms())

    PRINT *
    PRINT ('(A,A2)'), " Atom type of lead 1: ", IEl(ANLead1)
    PRINT ('(A,A2)'), " Atom type of lead 2: ", IEl(ANLead2)
    PRINT *

    ! THE CODE BELOW IMPOSES A MINIMUM OF THREE ATOMS. FOR EACH BETHE LATTICE. COMMENTED ON 2017-03-27.
    IF(Nembed(1)/=1)THEN
      IF( GetAN(1) /= GetAN(2) .OR. GetAN(1) /= GetAN(3) )THEN
        PRINT *, "ERROR: Too few atoms to define first electrode."
        STOP
      END IF
    END IF

    IF(Nembed(2)/=1)THEN
      IF( GetAN(GetNAtoms()) /= GetAN(GetNAtoms()-1) .OR. GetAN(GetNAtoms()) /= GetAN(GetNAtoms()-2) )THEN
        PRINT *, "ERROR: Too few atoms to define second electrode."
        STOP
      END IF
    END IF

    DO i=1,GetNAtoms()
       WRITE(IFU_LOG,'(2(2X,I3),2X,F3.0,3(1X,I4))')i,GetAN(i), &
            &       GetAtmChg(i),NAO(i),LAO(i),HAO(i)
       ztotp(i) = 0.d0
       CQp(1,i) = 0.d0
       CQp(2,i) = 0.d0
       CQp(3,i) = 0.d0
       CQ(1) = CQ(1) + GetAtmCo(1,i)*GetAN(i)
       CQ(2) = CQ(2) + GetAtmCo(2,i)*GetAN(i)
       CQ(3) = CQ(3) + GetAtmCo(3,i)*GetAN(i)
       ztot = ztot + GetAN(i)
    END DO
    CQ(1) = CQ(1)/ztot
    CQ(2) = CQ(2)/ztot
    CQ(3) = CQ(3)/ztot

    PRINT *
    WRITE(IFU_LOG,*) ' Center of charge:'
    WRITE(IFU_LOG,'(3(1X,F10.6))') (CQ(i),i=1,3)
    PRINT *

    IF (NAtomEl(1)/=0) THEN
       nlead1=NAtomEl(1)
       DO i=1,nlead1
          XL1(i) = GetAtmCo(1,i)
          YL1(i) = GetAtmCo(2,i)
          ZL1(i) = GetAtmCo(3,i)
       END DO
    ELSE
       ! Find all atoms in left lead
       DO i=1,GetNAtoms()
          IF( GetAN(i) == ANLead1) THEN
             nlead1=nlead1+1
             XL1(nlead1) = GetAtmCo(1,i)
             YL1(nlead1) = GetAtmCo(2,i)
             ZL1(nlead1) = GetAtmCo(3,i)
          ELSE
             EXIT
          END IF
       END DO
       ! When cluster consists 
       ! of atoms of one element 
       IF( nlead1 == GetNAtoms())THEN
          nlead1=GetNAtoms()/2
       ENDIF
    END IF

    IF (NAtomEl(2)/=0) THEN
       nlead2=NAtomEl(2)
       j=0
       DO i=GetNAtoms(),GetNAtoms()-nlead2+1,-1
          j=j+1
          XL2(j) = GetAtmCo(1,i)
          YL2(j) = GetAtmCo(2,i)
          ZL2(j) = GetAtmCo(3,i)
       END DO
    ELSE
       ! Find all atoms in right lead
       DO i=GetNAtoms(),nlead1+1,-1
          IF( GetAN(i) == ANLead2 )THEN
             nlead2=nlead2+1
             XL2(nlead2) = GetAtmCo(1,i)
             YL2(nlead2) = GetAtmCo(2,i)
             ZL2(nlead2) = GetAtmCo(3,i)
          ELSE
             EXIT
          END IF
       END DO
    END IF

    ! Find all atoms in molecule
    DO i=nlead1+1,GetNAtoms()-nlead2
       nmol=nmol+1
       NOrbMT = NOrbMT + NAO(i)
       ANMol(nmol) = GetAN(i)
       XM(nmol) = GetAtmCo(1,i)
       YM(nmol) = GetAtmCo(2,i)
       ZM(nmol) = GetAtmCo(3,i)
    ENDDO

    nbethe=0
    WRITE(IFU_LOG,*) ' Atoms in left electrode:', nlead1
    DO i=1,nlead1
       WRITE(IFU_LOG,'(1X,I3,2X,A2,3(1X,F10.6))') &
            & i,IEl(ANLead1),XL1(i),YL1(i),ZL1(i)
       nbethe=nbethe+1
    ENDDO
    PRINT *
    WRITE(IFU_LOG,*) ' Atoms in molecule:', nmol
    DO i=1,nmol
       WRITE(IFU_LOG,' (1X,I3,2X,A2,3(1X,F10.6))') &
            & i+nlead1,IEl(ANMol(i)),XM(i),YM(i),ZM(i)
       nbethe=nbethe+1
    ENDDO
    PRINT *
    WRITE(IFU_LOG,*) ' Atoms in right electrode:',nlead2
    DO i=1,nlead2
       WRITE(IFU_LOG,' (1X,I3,2X,A2,3(1X,F10.6))') &
            & i+nlead1+nmol,IEl(ANLead2),XL2(i),YL2(i),ZL2(i)
       nbethe=nbethe+1
    ENDDO
    PRINT *

    !
    !   DETERMINE THE PLANES OF ATOMS PRESENT IN THE MOLECULE 
    !   TOGETHER WITH THEIR RESPECTIVE CENTER OF CHARGE AND
    !   DIRECTOR VECTOR
    !
    nplane = 0
    IF (GetNAtoms() .GT. 3) THEN

       IF(nlead1.GE.3) THEN 
          i = 1
          u1x = GetAtmCo(1,i) - GetAtmCo(1,i+1)
          u1y = GetAtmCo(2,i) - GetAtmCo(2,i+1)
          u1z = GetAtmCo(3,i) - GetAtmCo(3,i+1)
          
 13       u2x = GetAtmCo(1,i) - GetAtmCo(1,i+dos)
          u2y = GetAtmCo(2,i) - GetAtmCo(2,i+dos)
          u2z = GetAtmCo(3,i) - GetAtmCo(3,i+dos)

          bb(1) = u1y*u2z-u2y*u1z
          bb(2) = u2x*u1z-u1x*u2z
          bb(3) = u1x*u2y-u2x*u1y
          
          bbnorm = dsqrt(bb(1)*bb(1) + bb(2)*bb(2) + bb(3)*bb(3))

          IF (ABS(bbnorm).LT.smallp) then
              write(ifu_log,*)'First 3 atoms in line in electrode 1 !!!!'
              dos =dos +1
              goto 13
              stop
          END IF

          bb(1) = bb(1)/bbnorm
          bb(2) = bb(2)/bbnorm
          bb(3) = bb(3)/bbnorm
          
          product = 0.d0

          IF( ABS(product) .LT. smallp .AND. &
               &             iplane(i+1) .EQ. 0 .AND. &
               &             iplane(i+2) .EQ. 0 ) THEN 
             nplane = nplane + 1
             nfrsp(nplane)=i
             nlstp(nplane)=i+2

             ntotp(nplane)=nlstp(nplane)-nfrsp(nplane)+1
             iplane(i)   = nplane
             iplane(i+1) = nplane
             iplane(i+2) = nplane

             aplane(1,nplane) = bb(1)
             aplane(2,nplane) = bb(2)
             aplane(3,nplane) = bb(3)
             CQp(1,nplane) = CQp(1,nplane) &
                  &        + GetAtmCo(1,i)*GetAN(i) &
                  &        + GetAtmCo(1,i+1)*GetAN(i+1) &
                  &        + GetAtmCo(1,i+2)*GetAN(i+2) 

             CQp(2,nplane) = CQp(2,nplane) &
                  &        + GetAtmCo(2,i)*GetAN(i) &
                  &        + GetAtmCo(2,i+1)*GetAN(i+1) &
                  &        + GetAtmCo(2,i+2)*GetAN(i+2) 

             CQp(3,nplane) =  CQp(3,nplane) &
                  &        + GetAtmCo(3,i)*GetAN(i) &
                  &        + GetAtmCo(3,i+1)*GetAN(i+1) &
                  &        + GetAtmCo(3,i+2)*GetAN(i+2) 

             ztotp(nplane) = ztotp(nplane) + GetAN(i) + &

                  &          GetAN(i+1) + GetAN(i+2)                 
             DO j = i+3,nlead1
                u3(1) = GetAtmCo(1,i) - GetAtmCo(1,j)
                u3(2) = GetAtmCo(2,i) - GetAtmCo(2,j)
                u3(3) = GetAtmCo(3,i) - GetAtmCo(3,j)
                u3norm = dsqrt(u3(1)*u3(1) &
                     & + u3(2)*u3(2) &
                     & + u3(3)*u3(3) )
                u3(1) = u3(1)/u3norm
                u3(2) = u3(2)/u3norm
                u3(3) = u3(3)/u3norm
                product = 0.d0
                DO l = 1,3
                   product = product + u3(l)*bb(l)
                ENDDO

                IF (ABS(product) .LT. smallp .AND. &
                     &  iplane(j) .EQ. 0 ) THEN
                   iplane(j)=nplane
                   nlstp(nplane)=j
                   ntotp(nplane)=ntotp(nplane)+1
                   CQp(1,nplane) = CQp(1,nplane)  + GetAtmCo(1,j)*GetAN(j)
                   CQp(2,nplane) = CQp(2,nplane)  + GetAtmCo(2,j)*GetAN(j)
                   CQp(3,nplane) = CQp(3,nplane)  + GetAtmCo(3,j)*GetAN(j)
                   ztotp(nplane) = ztotp(nplane)  + GetAN(j)
                ENDIF
             ENDDO
          ENDIF
       ENDIF
       
       IF(nlead2.GE.3) THEN
          dos = 2
          i = GetNAtoms()

          u1x = GetAtmCo(1,i) - GetAtmCo(1,i-1)
          u1y = GetAtmCo(2,i) - GetAtmCo(2,i-1)
          u1z = GetAtmCo(3,i) - GetAtmCo(3,i-1)
          
 14       u2x = GetAtmCo(1,i) - GetAtmCo(1,i-dos)
          u2y = GetAtmCo(2,i) - GetAtmCo(2,i-dos)
          u2z = GetAtmCo(3,i) - GetAtmCo(3,i-dos)

          bb(1) = u1y*u2z-u2y*u1z
          bb(2) = u2x*u1z-u1x*u2z
          bb(3) = u1x*u2y-u2x*u1y
          
          bbnorm = dsqrt(bb(1)*bb(1) &
               & + bb(2)*bb(2) &
               & + bb(3)*bb(3) )

          IF (ABS(bbnorm).LT.smallp) then
              write(ifu_log,*)'Last 3 atoms in line in electrode 2 !!!!'
              dos =dos +1
              goto 14
              stop
          END IF

          bb(1) = bb(1)/bbnorm
          bb(2) = bb(2)/bbnorm
          bb(3) = bb(3)/bbnorm
          
          product = 0.d0

          IF( ABS(product) .LT. smallp .AND. &
               &  iplane(i-1) .EQ. 0 .AND. &
               &  iplane(i-2) .EQ. 0 ) THEN        

             nplane = nplane + 1
             nfrsp(nplane)=i-2

             nlstp(nplane)=i
             ntotp(nplane)=nlstp(nplane)-nfrsp(nplane)+1
             iplane(i)   = nplane
             iplane(i-1) = nplane
             iplane(i-2) = nplane

             aplane(1,nplane) = bb(1)
             aplane(2,nplane) = bb(2)
             aplane(3,nplane) = bb(3)
             CQp(1,nplane) =   CQp(1,nplane) &
                  &        + GetAtmCo(1,i)*GetAN(i) &
                  &        + GetAtmCo(1,i-1)*GetAN(i-1) &
                  &        + GetAtmCo(1,i-2)*GetAN(i-2) 

             CQp(2,nplane) =   CQp(2,nplane) &
                &        + GetAtmCo(2,i)*GetAN(i) &
                &        + GetAtmCo(2,i-1)*GetAN(i-1) &
                &        + GetAtmCo(2,i-2)*GetAN(i-2) 

             CQp(3,nplane) =   CQp(3,nplane) &
                  &        + GetAtmCo(3,i)*GetAN(i) &
                  &        + GetAtmCo(3,i-1)*GetAN(i-1) &
                  &        + GetAtmCo(3,i-2)*GetAN(i-2) 

             ztotp(nplane) = ztotp(nplane) + GetAN(i) + &
                  &          GetAN(i-1) + GetAN(i-2) 

             DO j = i-3,GetNAtoms()-nlead2+1,-1

                u3(1) = GetAtmCo(1,i) - GetAtmCo(1,j)
                u3(2) = GetAtmCo(2,i) - GetAtmCo(2,j)
                u3(3) = GetAtmCo(3,i) - GetAtmCo(3,j)
                u3norm = dsqrt(u3(1)*u3(1) &
                     & + u3(2)*u3(2) &
                     & + u3(3)*u3(3) )
                u3(1) = u3(1)/u3norm
                u3(2) = u3(2)/u3norm
                u3(3) = u3(3)/u3norm
                product = 0.d0
                DO l = 1,3
                   product = product + u3(l)*bb(l)
                ENDDO
                IF (ABS(product) .LT. smallp .AND. &
                     & iplane(j) .EQ. 0 ) THEN
                   iplane(j)=nplane
                   nfrsp(nplane)=j
                   ntotp(nplane)=ntotp(nplane)+1
                   CQp(1,nplane) = CQp(1,nplane)  + GetAtmCo(1,j)*GetAN(j)
                   CQp(2,nplane) = CQp(2,nplane)  + GetAtmCo(2,j)*GetAN(j)
                   CQp(3,nplane) = CQp(3,nplane)  + GetAtmCo(3,j)*GetAN(j)
                   ztotp(nplane) = ztotp(nplane)  + GetAN(j)
                ENDIF
             ENDDO
          ENDIF ! ( ABS(product) .LT. smallp .AND. (iplane(i-1) .EQ. 0) .AND. (iplane(i-2) .EQ. 0 ) )
       ENDIF ! (nlead2.GE.3)
       
!       ! ADDED BELOW TO DEAL WITH 1D BETHE LATTICE.
!       IF((nlead1.EQ.1).AND.(nlead2.EQ.1))THEN
!         bb(1)= GetAtmCo(1,1) - GetAtmCo(1,2)
!         bb(2)= GetAtmCo(2,1) - GetAtmCo(2,2)
!         bb(3)= GetAtmCo(3,1) - GetAtmCo(3,2)
!
!         bbnorm = dsqrt(bb(1)*bb(1) &
!               & + bb(2)*bb(2) &
!               & + bb(3)*bb(3) )
!
!          IF (ABS(bbnorm).LT.smallp) then
!              write(ifu_log,*)'The 2 atoms used to make 1D BL are too near!!!!'
!              stop
!          END IF
!
!          bb(1) = bb(1)/bbnorm
!          bb(2) = bb(2)/bbnorm
!          bb(3) = bb(3)/bbnorm
!       ENDIF

    ENDIF
          
    !C    DETERMINE THE FRONTIER PLANES WITHIN THE ABOVE PLANES
    !C    AND ORIENTATE THEIR DIRECTOR VECTOR IN THE DIRECTION
    !C    POINTING OUTSIDE THE CLUSTER
    !C
    iplfront1 = 0
    iplfront2 = 0
    DO i=1,nplane
       CQp(1,i) = CQp(1,i)/ztotp(i)
       CQp(2,i) = CQp(2,i)/ztotp(i)
       CQp(3,i) = CQp(3,i)/ztotp(i)
       d2CQ = dsqrt((CQp(1,i)-CQ(1))**2 + (CQp(2,i)-CQ(2))**2 + &
            & (CQp(3,i)-CQ(3))**2)
       IF (iplfront1 .EQ. 0) THEN
          dmax2 = d2CQ
          dmax3 = dmax2
          iplfront1 = i
          iplfront2 = iplfront1
       ELSE IF (d2CQ .GE. dmax2) THEN
          dtemp = dmax2
          dmax2 = d2CQ
          dmax3 = dtemp
          iplfront2 = iplfront1
          iplfront1 = i
       ELSE IF (d2CQ .GE. dmax3 .OR. dmax2 .EQ. dmax3) THEN
          dmax3 = d2CQ
          iplfront2 = i
       ENDIF

       xupCQ = CQp(1,i)-CQ(1)
       yupCQ = CQp(2,i)-CQ(2)
       zupCQ = CQp(3,i)-CQ(3)
       cosCQpCQ =xupCQ*aplane(1,i)+yupCQ*aplane(2,i)+zupCQ*aplane(3,i)
       IF (cosCQpCQ .LT. 0.d0) THEN
          invpl(i) = 1
          DO k=1,3
             aplane(k,i)=-aplane(k,i)
          ENDDO
       ENDIF
       WRITE(ifu_log,'(A,I1)') ' Plane ',i 
       WRITE(ifu_log,'(A,F10.6,A1,F10.6,A1,F10.6,A)') ' with normal vector (', aplane(1,i),',',aplane(2,i),',',aplane(3,i), ' )'
       WRITE(ifu_log,'(A,I4,A)') ' has ', ntotp(i), ' atoms:'
       DO j=nfrsp(i),nlstp(i)
          WRITE(ifu_log,'(2(2X,I3),3(F11.6))') j,iplane(j),GetAtmCo(1,j),GetAtmCo(2,j),GetAtmCo(3,j)
       ENDDO
       PRINT *
    ENDDO
    !
    !    Warning message  if there are less than two planes
    !
    IF (nplane .LT. 2) THEN
       WRITE(ifu_log,*) 'WARNING!!: There is a missing interface plane !!!'
    ENDIF
    !
    !
    if (NEmbed(1) == 0) NEmbed(1) = ntotp(1)
    if (NEmbed(1) > nlead1 ) NEmbed(1) = nlead1
    if (NEmbed(1) > nlead1 ) WRITE(6,*) 'WARNING!! check the coordinates file'
    if (NEmbed(2) == 0) NEmbed(2) = ntotp(2)
    if (NEmbed(2) > nlead2 ) NEmbed(2) = nlead2
    if (NEmbed(2) > nlead2 ) WRITE(6,*) 'WARNING!! check the coordinates file'

    nn1 = NEmbed(1) 
    nn2 = NEmbed(2)


    if(PlBethe1)then
        nbethecount = NEmbed(1) ! Build a plane Bethe lattice from plane.
    else
      if(nlead1==1)then
        nbethecount = nlead1+1 ! 1D Bethe Lattice
      else
        nbethecount = nlead1 ! Build a bulk Bethe lattice taking into account various planes.
      end if
    end if
 
    ! Finding lattice parameter for electrode 1

    write(ifu_log,*)'Finding lattice directions in electrode 1 ....'
    d1=100000000.0
    if(Nembed(1)==1)then
      d1=dsqrt((GetAtmCo(1,1)-GetAtmCo(1,2))**2+(GetAtmCo(2,1)-GetAtmCo(2,2))**2+(GetAtmCo(3,1)-GetAtmCo(3,2))**2)
    else
      do i=1,NEmbed(1)
        do j=i+1,nlead1
          ddd=dsqrt((xl1(j)-xl1(i))**2+(yl1(j)-yl1(i))**2+(zl1(j)-zl1(i))**2)
          if (ddd <= d1) d1=ddd
        end do
      end do
    endif
    print *, "Near-neighbor distance at electrode 1 = ", d1*au2ang

!    nneig1=0
!    do i=1,NEmbed(1)
!       !do j=i+1,nlead1
!       do j=i+1,nbethecount
!          vv(1)=xl1(j)-xl1(i)
!          vv(2)=yl1(j)-yl1(i)
!          vv(3)=zl1(j)-zl1(i)
!          ddd=dsqrt(vv(1)**2+vv(2)**2+vv(3)**2)
!          ! Remark DJ: I increased tolerance to 0.1 Angstroem
!          ! in order to allow for slightly disordered lattices
!          if (dabs(ddd-d1) > smalld) cycle   ! from here, only nn-distance atoms pass.
!          vv(1)=vv(1)/ddd
!          vv(2)=vv(2)/ddd
!          vv(3)=vv(3)/ddd	! normalize the vector to modulus 1.0
!          do k=1,nneig1
!             scalar=vv(1)*vpb1(1,k)+vv(2)*vpb1(2,k)+vv(3)*vpb1(3,k)
!             if (abs(scalar-1.0) <= small) goto 111
!          end do
!          nneig1=nneig1+1
!          vpb1(1,nneig1)=vv(1)                   
!          vpb1(2,nneig1)=vv(2)
!          vpb1(3,nneig1)=vv(3)
!          nneig1=nneig1+1
!          vpb1(1,nneig1)=-vv(1)                   
!          vpb1(2,nneig1)=-vv(2)
!          vpb1(3,nneig1)=-vv(3)
!111    end do
!    end do

    nneig1=0
    do i=1,NEmbed(1)
       do j=i+1,nbethecount
          vv(1)=xl1(j)-xl1(i)
          vv(2)=yl1(j)-yl1(i)
          vv(3)=zl1(j)-zl1(i)
          ddd=dsqrt(vv(1)**2+vv(2)**2+vv(3)**2)
          if (dabs(ddd-d1) > smalld) cycle
          vv(1)=vv(1)/ddd
          vv(2)=vv(2)/ddd
          vv(3)=vv(3)/ddd
          do k=1,nneig1
             scalar=vv(1)*vpb1(1,k)+vv(2)*vpb1(2,k)+vv(3)*vpb1(3,k)
             if (abs(scalar-1.0) <= small) goto 111
          end do
          nneig1=nneig1+1
          vpb1(1,nneig1)=vv(1)                   
          vpb1(2,nneig1)=vv(2)
          vpb1(3,nneig1)=vv(3)
          nneig1=nneig1+1
          vpb1(1,nneig1)=-vv(1)                   
          vpb1(2,nneig1)=-vv(2)
          vpb1(3,nneig1)=-vv(3)
111    end do
    end do
    if(NEmbed(1).EQ.1)then
      vv(1)=GetAtmCo(1,1)-GetAtmCo(1,2)
      vv(2)=GetAtmCo(2,1)-GetAtmCo(2,2)
      vv(3)=GetAtmCo(3,1)-GetAtmCo(3,2)
      ddd=dsqrt(vv(1)**2+vv(2)**2+vv(3)**2)
      if (dabs(ddd-d1) > smalld)then
        write(ifu_log,*)'The 2 atoms used to make 1D BL are too near!!!!'
        stop
      end if
!      vv(1)=vv(1)/ddd ! THIS LEADS TO ERRORS.
!      vv(2)=vv(2)/ddd ! THIS LEADS TO ERRORS.
!      vv(3)=vv(3)/ddd ! THIS LEADS TO ERRORS.
      vpb1(1,1)=vv(1)                   
      vpb1(2,1)=vv(2)
      vpb1(3,1)=vv(3)
      nneig1=1+1
      vpb1(1,nneig1)=-vv(1)
      vpb1(2,nneig1)=-vv(2)
      vpb1(3,nneig1)=-vv(3)
      nneig1=2
    endif

!	! For hexagonal lattices.
!    if (ANLead1 == 6 .or. ANLead1 == 1 .or. ANLead1 == 83 .or. ANLead1 == 51) then
!       vpb1(1,5)=-(vpb1(1,1)+vpb1(1,3))     
!       vpb1(2,5)=-(vpb1(2,1)+vpb1(2,3))
!       vpb1(3,5)=-(vpb1(3,1)+vpb1(3,3))
!       vpb1(1,6)=-vpb1(1,5)    
!       vpb1(2,6)=-vpb1(2,5)
!       vpb1(3,6)=-vpb1(3,5)
!       nneig1 = 6
!    end if

 ! For hexagonal lattices. I use PI_8  = 4 * atan (1.0_8)

 if(ElType(1)=="GRAPHENE")then
   if (NoCloseHex)then
     if (ANLead1 == 6 .or. ANLead1 == 1 .or. ANLead1 == 83 .or. ANLead1 == 51) then
         ! When there are no closed hexagons, I compute the cross product of the plane-normal vector with the only lattice direction stored in the vectors vpb1(1:3,1) and its opposite vpb1(1:3,2).
         cross(1) = vpb1(2,1) * aplane(3,1) - vpb1(3,1) * aplane(2,1)
         cross(2) = vpb1(3,1) * aplane(1,1) - vpb1(1,1) * aplane(3,1)
         cross(3) = vpb1(1,1) * aplane(2,1) - vpb1(2,1) * aplane(1,1)
         crossmod=dsqrt(cross(1)**2+cross(2)**2+cross(3)**2)
         cross(1)=cross(1)/crossmod
         cross(2)=cross(2)/crossmod
         cross(3)=cross(3)/crossmod	! normalize the vector to modulus 1.0

         vpb1(1,3)=-(cos(PI_8/3.0)*vpb1(1,1) + d1*sin(PI_8/3.0)*cross(1))
         vpb1(2,3)=-(cos(PI_8/3.0)*vpb1(2,1) + d1*sin(PI_8/3.0)*cross(2))
         vpb1(3,3)=-(cos(PI_8/3.0)*vpb1(3,1) + d1*sin(PI_8/3.0)*cross(3))
         vpb1(1,4)=-vpb1(1,3)
         vpb1(2,4)=-vpb1(2,3)
         vpb1(3,4)=-vpb1(3,3)

         vpb1(1,5)=-(cos(PI_8/3.0)*vpb1(1,1) - d1*sin(PI_8/3.0)*cross(1))
         vpb1(2,5)=-(cos(PI_8/3.0)*vpb1(2,1) - d1*sin(PI_8/3.0)*cross(2))
         vpb1(3,5)=-(cos(PI_8/3.0)*vpb1(3,1) - d1*sin(PI_8/3.0)*cross(3))
         vpb1(1,6)=-vpb1(1,5)
         vpb1(2,6)=-vpb1(2,5)
         vpb1(3,6)=-vpb1(3,5)
         nneig1 = 6
     end if
   else
     if (ANLead1 == 6 .or. ANLead1 == 1 .or. ANLead1 == 83 .or. ANLead1 == 51) then
         vpb1(1,5)=-(vpb1(1,1)+vpb1(1,3))
         vpb1(2,5)=-(vpb1(2,1)+vpb1(2,3))
         vpb1(3,5)=-(vpb1(3,1)+vpb1(3,3))
         vpb1(1,6)=-vpb1(1,5)
         vpb1(2,6)=-vpb1(2,5)
         vpb1(3,6)=-vpb1(3,5)
         nneig1 = 6
     end if
   end if
 end if
     
    if (nneig1 /= 12 .and. nneig1 /=8 .and. nneig1 /=6 .and. nneig1 /=4 .and. NEmbed(1) /=1 ) then
       write(ifu_log,*)'Problem finding lattice directions in electrode 1 !!!!!'
       stop
    else
       write(ifu_log,'(A6,i10,A20)')'Found ',nneig1, 'lattice directions'
       do i=1,nneig1
          write(ifu_log,'(3f10.5)')(vpb1(j,i),j=1,3)
       end do
    end if


    if(PlBethe2)then
        nbethecount = NEmbed(2) ! Build a plane Bethe lattice from plane.
    else
        nbethecount = nlead2 ! Build a bulk Bethe lattice taking into account various planes.
    end if

    ! Finding lattice parameter for electrode 2

    !print *, "nn2 = ", nn2

    write(ifu_log,*)'Finding lattice directions in electrode 2 ....'
    d2=100000000.0
    ! Loop until nn2 gives problems when innermost atoms (not included in NEmbed(2))
    ! do not have perfect crystalline order: Nearest neighbour distance too short
    if(Nembed(2)==1)then
      d2=dsqrt((GetAtmCo(1,GetNAtoms())-GetAtmCo(1,GetNAtoms()-1))**2+(GetAtmCo(2,GetNAtoms())-GetAtmCo(2,GetNAtoms()-1))**2+(GetAtmCo(3,GetNAtoms())-GetAtmCo(3,GetNAtoms()-1))**2)
    else
      do i=1,NEmbed(2)
        do j=i+1,nlead2
          ddd=dsqrt((xl2(j)-xl2(i))**2+(yl2(j)-yl2(i))**2+(zl2(j)-zl2(i))**2)
          if (ddd <= d2) d2=ddd
        end do
      end do
    endif
    print *, "Near-neighbor distance at electrode 2 = ", d2*au2ang

    nneig2=0
    do i=1,NEmbed(2)
       !do j=i+1,nlead2
       do j=i+1,nbethecount
          vv(1)=xl2(j)-xl2(i)
          vv(2)=yl2(j)-yl2(i)
          vv(3)=zl2(j)-zl2(i)
          ddd=dsqrt(vv(1)**2+vv(2)**2+vv(3)**2)
          ! Remark DJ: I increased tolerance to 0.1 Angstroem
          ! in order to allow for slightly disordered lattices
          if (dabs(ddd-d2) > smalld) cycle
          vv(1)=vv(1)/ddd
          vv(2)=vv(2)/ddd
          vv(3)=vv(3)/ddd
          do k=1,nneig2
             scalar=vv(1)*vpb2(1,k)+vv(2)*vpb2(2,k)+vv(3)*vpb2(3,k)
             if (abs(scalar-1.0) <= small) goto 222
          end do
          nneig2=nneig2+1
          vpb2(1,nneig2)=vv(1)                   
          vpb2(2,nneig2)=vv(2)
          vpb2(3,nneig2)=vv(3)
          nneig2=nneig2+1
          vpb2(1,nneig2)=-vv(1)                   
          vpb2(2,nneig2)=-vv(2)
          vpb2(3,nneig2)=-vv(3)
222    end do
    end do

    if(NEmbed(2).EQ.1)then
      vv(1)=GetAtmCo(1,GetNAtoms())-GetAtmCo(1,GetNAtoms()-1)
      vv(2)=GetAtmCo(2,GetNAtoms())-GetAtmCo(2,GetNAtoms()-1)
      vv(3)=GetAtmCo(3,GetNAtoms())-GetAtmCo(3,GetNAtoms()-1)
      ddd=dsqrt(vv(1)**2+vv(2)**2+vv(3)**2)
      if (dabs(ddd-d1) > smalld)then
        write(ifu_log,*)'The 2 atoms used to make 1D BL are too near!!!!'
        stop
      end if
!      vv(1)=vv(1)/ddd ! THIS LEADS TO ERRORS.
!      vv(2)=vv(2)/ddd ! THIS LEADS TO ERRORS.
!      vv(3)=vv(3)/ddd ! THIS LEADS TO ERRORS.
      vpb2(1,1)=vv(1)                   
      vpb2(2,1)=vv(2)
      vpb2(3,1)=vv(3)
      nneig2=1+1
      vpb2(1,nneig2)=-vv(1)
      vpb2(2,nneig2)=-vv(2)
      vpb2(3,nneig2)=-vv(3)
      nneig2=2
    endif


!	! For hexagonal lattices.
!    if (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51) then
!       vpb2(1,5)=-(vpb2(1,1)+vpb2(1,3))     
!       vpb2(2,5)=-(vpb2(2,1)+vpb2(2,3))
!       vpb2(3,5)=-(vpb2(3,1)+vpb2(3,3))
!       vpb2(1,6)=-vpb2(1,5)    
!       vpb2(2,6)=-vpb2(2,5)
!       vpb2(3,6)=-vpb2(3,5)
!       nneig2 = 6
!    end if

 if(ElType(2)=="GRAPHENE")then
   if (NoCloseHex)then
     if (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51) then
       ! When there are no closed hexagons, I compute the cross product of the plane-normal vector with the only lattice direction stored in the vectors vpb1(1:3,1) and its opposite vpb1(1:3,2).
       cross(1) = vpb2(2,1) * aplane(3,2) - vpb2(3,1) * aplane(2,2)
       cross(2) = vpb2(3,1) * aplane(1,2) - vpb2(1,1) * aplane(3,2)
       cross(3) = vpb2(1,1) * aplane(2,2) - vpb2(2,1) * aplane(1,2)
       crossmod=dsqrt(cross(1)**2+cross(2)**2+cross(3)**2)
       cross(1)=cross(1)/crossmod
       cross(2)=cross(2)/crossmod
       cross(3)=cross(3)/crossmod	! normalize the vector to modulus 1.0

       vpb2(1,3)=-(cos(PI_8/3.0)*vpb2(1,1) + d2*sin(PI_8/3.0)*cross(1))     
       vpb2(2,3)=-(cos(PI_8/3.0)*vpb2(2,1) + d2*sin(PI_8/3.0)*cross(2)) 
       vpb2(3,3)=-(cos(PI_8/3.0)*vpb2(3,1) + d2*sin(PI_8/3.0)*cross(3)) 
       vpb2(1,4)=-vpb2(1,3)    
       vpb2(2,4)=-vpb2(2,3)
       vpb2(3,4)=-vpb2(3,3)

       vpb2(1,5)=-(cos(PI_8/3.0)*vpb2(1,1) - d2*sin(PI_8/3.0)*cross(1))     
       vpb2(2,5)=-(cos(PI_8/3.0)*vpb2(2,1) - d2*sin(PI_8/3.0)*cross(2)) 
       vpb2(3,5)=-(cos(PI_8/3.0)*vpb2(3,1) - d2*sin(PI_8/3.0)*cross(3)) 
       vpb2(1,6)=-vpb2(1,5)    
       vpb2(2,6)=-vpb2(2,5)
       vpb2(3,6)=-vpb2(3,5)
       nneig2 = 6
     end if
   else
     if (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51) then
       vpb2(1,5)=-(vpb2(1,1)+vpb2(1,3))     
       vpb2(2,5)=-(vpb2(2,1)+vpb2(2,3))
       vpb2(3,5)=-(vpb2(3,1)+vpb2(3,3))
       vpb2(1,6)=-vpb2(1,5)    
       vpb2(2,6)=-vpb2(2,5)
       vpb2(3,6)=-vpb2(3,5)
       nneig2 = 6
     end if
   end if
 end if

    if (nneig2 /= 12 .and. nneig2 /=8 .and. nneig2 /=6 .and. nneig2 /=4 .and. NEmbed(2) /=1 ) then
       write(ifu_log,*)'Problem finding lattice directions in electrode 2 !!!!!'
       stop
    else
       write(ifu_log,'(A6,i10,A20)')'Found ',nneig2, 'lattice directions'
       do i=1,nneig2
          write(ifu_log,'(3f10.5)')(vpb2(j,i),j=1,3)
       end do
    end if

! Finding atoms in electrode 1 where to attach Bethe lattices

    nblatoms1 = 0

    if (nneig1 == 6 .and. (ANLead1 ==6 .or. ANLead1 ==1 .or. ANLead1 == 83 .or. ANLead1 == 51)) then
       nj=2
    else
       nj=1
    end if

    if (Nembed(1)==1)then
      ! xl1(i) = GetAtmCo(i)
      ! THE 3 LIES BELOW GIVE THE RELATIVE VECTORS BUT NOT THE POSITION.
      v(1,1)=(GetAtmCo(1,1)-GetAtmCo(1,2))!*d1
      v(2,1)=(GetAtmCo(2,1)-GetAtmCo(2,2))!*d1
      v(3,1)=(GetAtmCo(3,1)-GetAtmCo(3,2))!*d1
      ddd = sqrt(v(1,1)**2+v(2,1)**2+v(3,1)**2)
      !if (dabs(ddd-d1) > smalld)then
      !  write(ifu_log,*)'The 2 atoms used to make 1D BL1 are too near!!!! Exit when filling nvbet.'
      !  stop
      !endif
      ! Coordinates of a new Bethe lattice atom
      !zbla = au2ang*(zl1(i)+vb(3,k))
      xbla = au2ang*(GetAtmCo(1,1)+v(1,1))
      ybla = au2ang*(GetAtmCo(2,1)+v(2,1))
      zbla = au2ang*(GetAtmCo(3,1)+v(3,1))
      nblatoms1=1
      xbl1(nblatoms1) = xbla
      ybl1(nblatoms1) = ybla
      zbl1(nblatoms1) = zbla
    else
      do i=1,NEmbed(1)
        ndi=0
        do k1=1,nj
          ndirr=0
          do k=k1,nneig1,nj
             vb(1,k)=vpb1(1,k)*d1
             vb(2,k)=vpb1(2,k)*d1
             vb(3,k)=vpb1(3,k)*d1
             do j=1,nlead1
                if( j == i ) cycle
                v(1,j)=xl1(j)-xl1(i)
                v(2,j)=yl1(j)-yl1(i)
                v(3,j)=zl1(j)-zl1(i)
                ddd = sqrt(v(1,j)**2+v(2,j)**2+v(3,j)**2)
                if (dabs(ddd-d1) > smalld) cycle
                scalar=(vb(1,k)*v(1,j)+vb(2,k)*v(2,j)+vb(3,k)*v(3,j))/(d1*ddd)
                if( abs(scalar-1.0)<=small) goto 333
             end do
             if (nneig1 == 12 .or. nneig1 ==8) then
                scalar=vb(1,k)*aplane(1,1)+vb(2,k)*aplane(2,1)+vb(3,k)*aplane(3,1)
                if (scalar < -1.0*small) goto 333
             end if
             ndirr=ndirr+1
             nvbet(i,ndi+ndirr)=k
333       end do
          if (nneig1 == 6 .and. (ANLead1 ==6 .or. ANLead1 ==1 .or. ANLead1 == 83 .or. ANLead1 == 51)) then
             if (ndirr == 3) then
                do j=1,3
                   nvbet(i,ndi+j)=0
                end do
                ndirr=0
             end if
          end if
          ndi=ndi+ndirr
       end do
       ndir(i)=ndi
       if (ndi /= 0) ifrpl(i)=1

       do j=1,ndir(i)
          k=nvbet(i,j)
          !WRITE(ifu_log,'A,3(F11.6)')'Ar',au2ang*(xl1(i)+vb(1,k)),au2ang*(yl1(i)+vb(2,k)),au2ang*(zl1(i)+vb(3,k))
          ! Coordinates of a new Bethe lattice atom
          xbla = au2ang*(xl1(i)+vb(1,k))
          ybla = au2ang*(yl1(i)+vb(2,k))
          zbla = au2ang*(zl1(i)+vb(3,k))
          ! Find out whehter Bethe lattice atom already exists
          do ibl=1,nblatoms1
             if( abs(xbla-xbl1(ibl))<=smalld .and. abs(ybla-ybl1(ibl))<=smalld .and. abs(zbla-zbl1(ibl))<=smalld )exit
          end do
          if( ibl > nblatoms1 )then
             nblatoms1=nblatoms1+1
             xbl1(nblatoms1) = xbla
             ybl1(nblatoms1) = ybla
             zbl1(nblatoms1) = zbla
          end if

        end do
        nbethe=nbethe+ndir(i)
      end do
    end if


! Finding atoms in electrode 2 where to attach Bethe lattices

    nblatoms2 = 0

    if (nneig2 == 6 .and. (ANLead2 ==6 .or. ANLead2 ==1 .or. ANLead2 == 83 .or. ANLead2 == 51)) then
       nj=2
    else
       nj=1
    end if


    if (Nembed(2)==1)then
      ! xl1(i) = GetAtmCo(i)
      ! THE 3 LINES BELOW GIVE THE RELATIVE VECTOR BUT NOT THE POSITION.
      v(1,1)=(GetAtmCo(1,GetNAtoms())-GetAtmCo(1,GetNAtoms()-1))!*d2
      v(2,1)=(GetAtmCo(2,GetNAtoms())-GetAtmCo(2,GetNAtoms()-1))!*d2
      v(3,1)=(GetAtmCo(3,GetNAtoms())-GetAtmCo(3,GetNAtoms()-1))!*d2
      ddd = sqrt(v(1,1)**2+v(2,1)**2+v(3,1)**2)
      !if (dabs(ddd-d1) > smalld)then
      !  write(ifu_log,*)'The 2 atoms used to make 1D BL2 are too near!!!! Exit when filling nvbet.'
      !  stop
      !endif
      ! Coordinates of a new Bethe lattice atom
      !zbla = au2ang*(zl1(i)+vb(3,k))
      xbla = au2ang*(GetAtmCo(1,GetNAtoms())+v(1,1))
      ybla = au2ang*(GetAtmCo(2,GetNAtoms())+v(2,1))
      zbla = au2ang*(GetAtmCo(3,GetNAtoms())+v(3,1))
      nblatoms2=1
      xbl2(nblatoms2) = xbla
      ybl2(nblatoms2) = ybla
      zbl2(nblatoms2) = zbla
    else
      do i=GetNAtoms(),GetNAtoms()-NEmbed(2)+1,-1
        !write(ifu_log,*)'Atom', i
        ndi=0
        do k1=1,nj
          ndirr=0
          do k=k1,nneig2,nj
             vb(1,k)=vpb2(1,k)*d2
             vb(2,k)=vpb2(2,k)*d2
             vb(3,k)=vpb2(3,k)*d2
             do j=GetNAtoms(),GetNAtoms()-nlead2+1,-1
                if( j == i ) cycle
                v(1,j)=GetAtmCo(1,j)-GetAtmCo(1,i)
                v(2,j)=GetAtmCo(2,j)-GetAtmCo(2,i)
                v(3,j)=GetAtmCo(3,j)-GetAtmCo(3,i)
                ddd = sqrt(v(1,j)**2+v(2,j)**2+v(3,j)**2)
                if (dabs(ddd-d2) > smalld) cycle
                scalar=(vb(1,k)*v(1,j)+vb(2,k)*v(2,j)+vb(3,k)*v(3,j))/(d2*ddd)
                if( abs(scalar-1.0)<=small) goto 444
             end do
             if (nneig2 == 12 .or. nneig2 == 8) then
                scalar=vb(1,k)*aplane(1,2)+vb(2,k)*aplane(2,2)+vb(3,k)*aplane(3,2)
                if (scalar < -1.0*small) goto 444
             end if
             ndirr=ndirr+1
             nvbet(i,ndi+ndirr)=k
444       end do
          if (nneig2 == 6 .and. (ANLead2 ==6 .or. ANLead2 ==1 .or. ANLead2 == 83 .or. ANLead2 == 51)) then
             if (ndirr == 3) then
                do j=1,3
                   nvbet(i,ndi+j)=0
                end do
                ndirr=0
             end if
          end if
          ndi=ndi+ndirr
       end do
       ndir(i)=ndi
       if (ndi /= 0) ifrpl(i)=2

       do j=1,ndir(i)
          k=nvbet(i,j)
          !WRITE(ifu_log,'A,3(F11.6)')'Ar',(au2ang*(GetAtmCo(n,i)+vb(n,k)),n=1,3)  
          ! Coordinates of a new Bethe lattice atom
          xbla = au2ang*(GetAtmCo(1,i)+vb(1,k))
          ybla = au2ang*(GetAtmCo(2,i)+vb(2,k))
          zbla = au2ang*(GetAtmCo(3,i)+vb(3,k))
          ! Find out whether Bethe lattice atom already exists
          do ibl=1,nblatoms2
             if( abs(xbla-xbl2(ibl))<=smalld .and. abs(ybla-ybl2(ibl))<=smalld .and. abs(zbla-zbl2(ibl))<=smalld )exit
          end do
          ! If not found add new Bethe lattice atom to list
          if( ibl > nblatoms2 )then
             nblatoms2=nblatoms2+1
             xbl2(nblatoms2) = xbla
             ybl2(nblatoms2) = ybla
             zbl2(nblatoms2) = zbla
          end if

        end do
        nbethe=nbethe+ndir(i)
      end do
    end if
    !
    !    OPEN A FILE FOR FURTHER CHECK OF BETHE LATTICE DIRECTIONS 
    !
    !OPEN(unit=ifu_xyz,file='XYZ.'//trim(xxx)//'.dat',status='unknown')
    REWIND(ifu_xyz)
    write(ifu_xyz,'(I5)'), GetNAtoms()+nblatoms1+nblatoms2
    write(ifu_xyz,*)
       do ibl=1,nblatoms1
          WRITE(ifu_xyz,' (A2,3(F11.6))') 'Ar', xbl1(ibl), ybl1(ibl), zbl1(ibl)
       end do
       DO i=1,GetNAtoms()
          WRITE(ifu_xyz,'(A2,3(F11.6))') IEl(GetAN(i)), au2ang*GetAtmCo(1,i), au2ang*GetAtmCo(2,i), au2ang*GetAtmCo(3,i)
       END DO
       do ibl=1,nblatoms2
          WRITE(ifu_xyz,' (A2,3(F11.6))') 'Ar', xbl2(ibl), ybl2(ibl), zbl2(ibl)
       end do
    !CLOSE(ifu_xyz)

    if( ANT1DInp )then
       OPEN(unit=ifu_ant,file='dev.'//trim(ant1dname)//'.xyz',status='unknown')
       write(ifu_ant,*), GetNAtoms()
       write(ifu_ant,*)
       DO i=1,GetNAtoms()
          WRITE(ifu_ant,'(I3,3(F11.6))') AN(i), au2ang*GetAtmCo(1,i), au2ang*GetAtmCo(2,i), au2ang*GetAtmCo(3,i)
       END DO
       close(ifu_ant)
       OPEN(unit=ifu_ant,file='bl1.'//trim(ant1dname)//'.xyz',status='unknown')
       write(ifu_ant,*), nblatoms1
       write(ifu_ant,*)
       do ibl=1,nblatoms1
          WRITE(ifu_ant,' (I3,3(F11.6))') AN(1), xbl1(ibl), ybl1(ibl), zbl1(ibl)
       end do
       close(ifu_ant)
       OPEN(unit=ifu_ant,file='bl2.'//trim(ant1dname)//'.xyz',status='unknown')       
       write(ifu_ant,*), nblatoms2
       write(ifu_ant,*)
       do ibl=1,nblatoms2
          WRITE(ifu_ant,' (I3,3(F11.6))') AN(GetNAtoms()), xbl2(ibl), ybl2(ibl), zbl2(ibl)
       end do
       close(ifu_ant)
    end if

  END SUBROUTINE AnalyseCluster

  SUBROUTINE AnalyseClusterElectrodeOne
    use parameters, only: ANT1DInp, smalld, small, PlBethe1, PlBethe2, NoCloseHex
    USE preproc, ONLY: MaxAtm
    USE g09Common, ONLY: GetNShell, GetAtm4Sh, Get1stAO4Sh, GetNBasis, GetAN, GetAtmChg, GetAtmCo, GetNAtoms
    use ANTCommon
    IMPLICIT NONE

    real,    PARAMETER :: sq2inv=0.707106781
    integer :: dos=2
    integer, PARAMETER :: MaxEl=104,ein=1

    integer, DIMENSION(3), PARAMETER :: AOT = (/ 1,2,3 /)

    real :: d1,d2,ddd,scalar                             
    integer :: n,nt,nn1,nn2
    real, DIMENSION(3,MaxAtm) :: v
    real, DIMENSION(3) :: vv
    real :: vb(3,12)
    real :: CQ(3),CQp(3,MaxAtm),ztotp(MaxAtm)
    integer, DIMENSION(MaxAtm) :: iplane, nfrsp, nlstp, ntotp
    real :: u3(3),bb(3),aplane(3,MaxAtm), vpr(3,nvec), ud(3,MaxAtm,nvec), vprt(3,nvec)
    integer :: nvpl(MaxAtm), invpl(MaxAtm),nbethe        !!, itype(2,MaxAtm)
    integer :: IEl(MaxEl+1)

    integer :: i, ntot, nsw, nplane, j, l, iplfront1, iplfront2, k, icopl, &
         iii, jjj, i1, iivec, iil, kk, ll, lerr, nj, k1, ndi, ndirr
    
    real :: alpha, eta, smallp, pi, one, zero,au2ang, dvec, ztot, &
         u1x, u1y, u1z, u2x, u2y, u2z, bbnorm, product, u3norm, d2cq, dmax2, dmax3, &
         dtemp, xupcq, yupcq, zupcq, coscqpcq, ddx, ddy, ddz, dist, angvec, &
         xx, yy, zz, cosudvpr, yyy, zzz, vnorm, coscqpvpr

    ! Coordinates of Bethe lattice atoms for each electrode
    real, DIMENSION(MaxAtm*10) :: xbl1, ybl1, zbl1,  xbl2, ybl2, zbl2
    ! Number of Bethe lattice atoms for each electrode
    integer :: nblatoms1, nblatoms2, ibl
    ! Coordnates of a Bethe lattice atom
    real :: xbla, ybla, zbla
    ! Added by C. Salgado to work with Geometry
    real,  parameter :: PI_8  = 4 * atan (1.0_8)
    real :: cross(3)
    real :: crossmod
    integer :: nbethecount
    
    !C
    CALL FillEl(ein,MaxEl,IEl)
    !C Setting to zero all arrays ...
    ifrpl=0
    iplane=0
    nfrsp=0
    nlstp=0
    ntotp=0       
    nvpl=0
    invpl=0
    ndir=0
    nvbet=0
    ud=0.0d0
    vpb1=0.0d0
    vpb2=0.0d0
    vprt=0.0d0
    vpr=0.0d0
    !
    !    DEFINITION OF LOCAL VARIABLES
    !
    smallp = 1.d-2
    pi = ACOS(-1.)
    one = 1.d0
    zero = 0.d0
    au2ang = 0.52918d0
    dvec = 3.0/au2ang
    !
    !    DETERMINING THE NO. OF ORBITALS PER ATOM
    !
    ntot=0
    DO i=1,GetNShell()-1
       IF (GetAtm4Sh(i).NE.GetAtm4Sh(i+1)) THEN 
          ! Number of orbitals on atom center GetAtm4Sh(i)
          NAO(GetAtm4Sh(i))=Get1stAO4Sh(i+1)-(ntot+1)
          ! Highest orbital number (within cluster) on atom center GetAtm4Sh(i)
          HAO(GetAtm4Sh(i))=Get1stAO4Sh(i+1)-1
          ! Lowest orbital number (within cluster) on atom center GetAtm4Sh(i)
          LAO(GetAtm4Sh(i))=HAO(GetAtm4Sh(i))-NAO(GetAtm4Sh(i))+1
          ntot=ntot+NAO(GetAtm4Sh(i))
       ENDIF
    ENDDO
    NAO(GetAtm4Sh(GetNShell()))=GetNBasis()-ntot
    LAO(GetAtm4Sh(GetNShell()))=HAO(GetAtm4Sh(GetNShell())-1)+1
    HAO(GetAtm4Sh(GetNShell()))=LAO(GetAtm4Sh(GetNShell()))+NAO(GetAtm4Sh(GetNShell()))-1
    
    WRITE(IFU_LOG,*) '----------------------------------------------------------'
    WRITE(IFU_LOG,*) 'Analyzing cluster for the connection of the  Bethe Lattice'
    WRITE(IFU_LOG,*) '----------------------------------------------------------'
    !
    !    DETERMINING THE POSITIONS AND TYPE OF CLUSTER ATOMS
    !    AS WELL AS THE CENTER OF CHARGE OF THE MOLECULE
    !
    ! Los datos deben introducirse:
    !            Plano al que se adjunta la red de Bethe por la izquierda
    !            Otros Atomos del cluster de la izquierda
    !            Sistema molecular 
    !            Otros Atomos del cluster de la derecha
    !            Plano al que se adjunta la red de Bethe por la derecha
    !
    nlead1=0
    nlead2=0
    NOrbMT = 0
    nmol = 0
    nsw = 0
    CQ(1) = 0.d0
    CQ(2) = 0.d0
    CQ(3) = 0.d0
    ztot = 0.d0

    ANLead1 = GetAN(1)

    PRINT *
    PRINT ('(A,A2)'), " Atom type of lead 1: ", IEl(ANLead1)
    PRINT *

    IF( GetAN(1) /= GetAN(2) .OR. GetAN(1) /= GetAN(3) )THEN
       PRINT *, "ERROR: Too few atoms to define left electrode."
       STOP
    END IF

    DO i=1,GetNAtoms()
       WRITE(IFU_LOG,'(2(2X,I3),2X,F3.0,3(1X,I4))')i,GetAN(i), &
            &       GetAtmChg(i),NAO(i),LAO(i),HAO(i)
       ztotp(i) = 0.d0
       CQp(1,i) = 0.d0
       CQp(2,i) = 0.d0
       CQp(3,i) = 0.d0
       CQ(1) = CQ(1) + GetAtmCo(1,i)*GetAN(i)
       CQ(2) = CQ(2) + GetAtmCo(2,i)*GetAN(i)
       CQ(3) = CQ(3) + GetAtmCo(3,i)*GetAN(i)
       ztot = ztot + GetAN(i)
    END DO
    CQ(1) = CQ(1)/ztot
    CQ(2) = CQ(2)/ztot
    CQ(3) = CQ(3)/ztot

    PRINT *
    WRITE(IFU_LOG,*) ' Center of charge:'
    WRITE(IFU_LOG,'(3(1X,F10.6))') (CQ(i),i=1,3)
    PRINT *

    IF (NAtomEl(1)/=0) THEN
       nlead1=NAtomEl(1)
       DO i=1,nlead1
          XL1(i) = GetAtmCo(1,i)
          YL1(i) = GetAtmCo(2,i)
          ZL1(i) = GetAtmCo(3,i)
       END DO
    ELSE
       ! Find all atoms in left lead
       DO i=1,GetNAtoms()
          IF( GetAN(i) == ANLead1) THEN
             nlead1=nlead1+1
             XL1(nlead1) = GetAtmCo(1,i)
             YL1(nlead1) = GetAtmCo(2,i)
             ZL1(nlead1) = GetAtmCo(3,i)
          ELSE
             EXIT
          END IF
       END DO
    END IF

    ! Find all atoms in molecule
    DO i=nlead1+1,GetNAtoms()
       nmol=nmol+1
       NOrbMT = NOrbMT + NAO(i)
       ANMol(nmol) = GetAN(i)
       XM(nmol) = GetAtmCo(1,i)
       YM(nmol) = GetAtmCo(2,i)
       ZM(nmol) = GetAtmCo(3,i)
    ENDDO

    nbethe=0
    WRITE(IFU_LOG,*) ' Atoms in substrate:', nlead1
    DO i=1,nlead1
       WRITE(IFU_LOG,'(1X,I3,2X,A2,3(1X,F10.6))') &
            & i,IEl(ANLead1),XL1(i),YL1(i),ZL1(i)
       nbethe=nbethe+1
    ENDDO
    PRINT *
    WRITE(IFU_LOG,*) ' Atoms in molecule:', nmol
    DO i=1,nmol
       WRITE(IFU_LOG,' (1X,I3,2X,A2,3(1X,F10.6))') &
            & i+nlead1,IEl(ANMol(i)),XM(i),YM(i),ZM(i)
       nbethe=nbethe+1
    ENDDO
    PRINT *

    !
    !   DETERMINE THE PLANES OF ATOMS PRESENT IN THE MOLECULE 
    !   TOGETHER WITH THEIR RESPECTIVE CENTER OF CHARGE AND
    !   DIRECTOR VECTOR
    !
    nplane = 0
    IF (GetNAtoms() .GT. 3) THEN

       IF(nlead1.GE.3) THEN 
          i = 1
          u1x = GetAtmCo(1,i) - GetAtmCo(1,i+1)
          u1y = GetAtmCo(2,i) - GetAtmCo(2,i+1)
          u1z = GetAtmCo(3,i) - GetAtmCo(3,i+1)
          
 13       u2x = GetAtmCo(1,i) - GetAtmCo(1,i+dos)
          u2y = GetAtmCo(2,i) - GetAtmCo(2,i+dos)
          u2z = GetAtmCo(3,i) - GetAtmCo(3,i+dos)

          bb(1) = u1y*u2z-u2y*u1z
          bb(2) = u2x*u1z-u1x*u2z
          bb(3) = u1x*u2y-u2x*u1y
          
          bbnorm = dsqrt(bb(1)*bb(1) + bb(2)*bb(2) + bb(3)*bb(3))

          IF (ABS(bbnorm).LT.smallp) then
              write(ifu_log,*)'First 3 atoms in line in electrode 1 !!!!'
              dos = dos +1
              goto 13
              stop
          END IF

          bb(1) = bb(1)/bbnorm
          bb(2) = bb(2)/bbnorm
          bb(3) = bb(3)/bbnorm
          
          product = 0.d0

          IF( ABS(product) .LT. smallp .AND. &
               &             iplane(i+1) .EQ. 0 .AND. &
               &             iplane(i+2) .EQ. 0 ) THEN 
             nplane = nplane + 1
             nfrsp(nplane)=i
             nlstp(nplane)=i+2

             ntotp(nplane)=nlstp(nplane)-nfrsp(nplane)+1
             iplane(i)   = nplane
             iplane(i+1) = nplane
             iplane(i+2) = nplane

             aplane(1,nplane) = bb(1)
             aplane(2,nplane) = bb(2)
             aplane(3,nplane) = bb(3)
             CQp(1,nplane) = CQp(1,nplane) &
                  &        + GetAtmCo(1,i)*GetAN(i) &
                  &        + GetAtmCo(1,i+1)*GetAN(i+1) &
                  &        + GetAtmCo(1,i+2)*GetAN(i+2) 

             CQp(2,nplane) = CQp(2,nplane) &
                  &        + GetAtmCo(2,i)*GetAN(i) &
                  &        + GetAtmCo(2,i+1)*GetAN(i+1) &
                  &        + GetAtmCo(2,i+2)*GetAN(i+2) 

             CQp(3,nplane) =  CQp(3,nplane) &
                  &        + GetAtmCo(3,i)*GetAN(i) &
                  &        + GetAtmCo(3,i+1)*GetAN(i+1) &
                  &        + GetAtmCo(3,i+2)*GetAN(i+2) 

             ztotp(nplane) = ztotp(nplane) + GetAN(i) + &

                  &          GetAN(i+1) + GetAN(i+2)                 
             DO j = i+3,nlead1
                u3(1) = GetAtmCo(1,i) - GetAtmCo(1,j)
                u3(2) = GetAtmCo(2,i) - GetAtmCo(2,j)
                u3(3) = GetAtmCo(3,i) - GetAtmCo(3,j)
                u3norm = dsqrt(u3(1)*u3(1) &
                     & + u3(2)*u3(2) &
                     & + u3(3)*u3(3) )
                u3(1) = u3(1)/u3norm
                u3(2) = u3(2)/u3norm
                u3(3) = u3(3)/u3norm
                product = 0.d0
                DO l = 1,3
                   product = product + u3(l)*bb(l)
                ENDDO

                IF (ABS(product) .LT. smallp .AND. &
                     &  iplane(j) .EQ. 0 ) THEN
                   iplane(j)=nplane
                   nlstp(nplane)=j
                   ntotp(nplane)=ntotp(nplane)+1
                   CQp(1,nplane) = CQp(1,nplane)  + GetAtmCo(1,j)*GetAN(j)
                   CQp(2,nplane) = CQp(2,nplane)  + GetAtmCo(2,j)*GetAN(j)
                   CQp(3,nplane) = CQp(3,nplane)  + GetAtmCo(3,j)*GetAN(j)
                   ztotp(nplane) = ztotp(nplane)  + GetAN(j)
                ENDIF
             ENDDO
          ENDIF
       ENDIF
    ENDIF
       
    !C    DETERMINE THE FRONTIER PLANES WITHIN THE ABOVE PLANES
    !C    AND ORIENTATE THEIR DIRECTOR VECTOR IN THE DIRECTION
    !C    POINTING OUTSIDE THE CLUSTER
    !C
    iplfront1 = 0
    DO i=1,nplane
       CQp(1,i) = CQp(1,i)/ztotp(i)
       CQp(2,i) = CQp(2,i)/ztotp(i)
       CQp(3,i) = CQp(3,i)/ztotp(i)
       d2CQ = dsqrt((CQp(1,i)-CQ(1))**2 + (CQp(2,i)-CQ(2))**2 + &
            & (CQp(3,i)-CQ(3))**2)
       IF (iplfront1 .EQ. 0) THEN
          dmax2 = d2CQ
          dmax3 = dmax2
          iplfront1 = i
          iplfront2 = iplfront1
       ELSE IF (d2CQ .GE. dmax2) THEN
          dtemp = dmax2
          dmax2 = d2CQ
          dmax3 = dtemp
          iplfront2 = iplfront1
          iplfront1 = i
       ELSE IF (d2CQ .GE. dmax3 .OR. dmax2 .EQ. dmax3) THEN
          dmax3 = d2CQ
          iplfront2 = i
       ENDIF

       xupCQ = CQp(1,i)-CQ(1)
       yupCQ = CQp(2,i)-CQ(2)
       zupCQ = CQp(3,i)-CQ(3)
       cosCQpCQ =xupCQ*aplane(1,i)+yupCQ*aplane(2,i)+zupCQ*aplane(3,i)
       IF (cosCQpCQ .LT. 0.d0) THEN
          invpl(i) = 1
          DO k=1,3
             aplane(k,i)=-aplane(k,i)
          ENDDO
       ENDIF
       WRITE(ifu_log,'(A,I1)') ' Plane ',i 
       WRITE(ifu_log,'(A,F10.6,A1,F10.6,A1,F10.6,A)') ' with normal vector (', aplane(1,i),',',aplane(2,i),',',aplane(3,i), ' )'
       WRITE(ifu_log,'(A,I4,A)') ' has ', ntotp(i), ' atoms:'
       DO j=nfrsp(i),nlstp(i)
          WRITE(ifu_log,'(2(2X,I3),3(F11.6))') j,iplane(j),GetAtmCo(1,j),GetAtmCo(2,j),GetAtmCo(3,j)
       ENDDO
       PRINT *
    ENDDO
    !
    !    Warning message  if there are less than two planes
    !
    IF (nplane .LT. 2) THEN
       WRITE(ifu_log,*) 'WARNING!!: There is a missing plane. The transmission cannot be calculated !!!'
    ENDIF
    !
    !

    if (NEmbed(1) == 0) NEmbed(1) = ntotp(1)
    if (NEmbed(1) > nlead1 ) NEmbed(1) = nlead1
    if (NEmbed(1) > nlead1 ) WRITE(6,*) 'WARNING!! check the coordinates file'

    nn1 = NEmbed(1)

    ! Finding lattice parameter for electrode 1

    write(ifu_log,*)'Finding lattice directions in electrode 1 ....'
    d1=100000000.0
    do i=1,NEmbed(1)
       do j=i+1,nlead1
          ddd=dsqrt((xl1(j)-xl1(i))**2+(yl1(j)-yl1(i))**2+(zl1(j)-zl1(i))**2)
          if (ddd <= d1) d1=ddd
       end do
    end do
    print *, "Near-neighbor distance at electrode 1 = ", d1*au2ang

    nneig1=0
    do i=1,NEmbed(1)
       do j=i+1,nlead1
          vv(1)=xl1(j)-xl1(i)
          vv(2)=yl1(j)-yl1(i)
          vv(3)=zl1(j)-zl1(i)
          ddd=dsqrt(vv(1)**2+vv(2)**2+vv(3)**2)
          if (dabs(ddd-d1) > smalld) cycle
          vv(1)=vv(1)/ddd
          vv(2)=vv(2)/ddd
          vv(3)=vv(3)/ddd
          do k=1,nneig1
             scalar=vv(1)*vpb1(1,k)+vv(2)*vpb1(2,k)+vv(3)*vpb1(3,k)
             if (abs(scalar-1.0) <= small) goto 111
          end do
          nneig1=nneig1+1
          vpb1(1,nneig1)=vv(1)                   
          vpb1(2,nneig1)=vv(2)
          vpb1(3,nneig1)=vv(3)
          nneig1=nneig1+1
          vpb1(1,nneig1)=-vv(1)                   
          vpb1(2,nneig1)=-vv(2)
          vpb1(3,nneig1)=-vv(3)
111    end do
    end do

    if (ANLead1 == 6 .or. ANLead1 == 1 .or. ANLead1 == 83 .or. ANLead1 == 51) then
       vpb1(1,5)=-(vpb1(1,1)+vpb1(1,3))     
       vpb1(2,5)=-(vpb1(2,1)+vpb1(2,3))
       vpb1(3,5)=-(vpb1(3,1)+vpb1(3,3))
       vpb1(1,6)=-vpb1(1,5)    
       vpb1(2,6)=-vpb1(2,5)
       vpb1(3,6)=-vpb1(3,5)
       nneig1 = 6
    end if
       
    if (nneig1 /= 12 .and. nneig1 /=8 .and. nneig1 /=6 .and. nneig1 /= 4) then
       write(ifu_log,'(A6,i10,A20)')'Found ',nneig1, 'lattice directions'
       write(ifu_log,*)'Problem finding lattice directions in electrode 1 !!!!!'
       stop
    else
       write(ifu_log,'(A6,i10,A20)')'Found ',nneig1, 'lattice directions'
       do i=1,nneig1
          write(ifu_log,'(3f10.5)')(vpb1(j,i),j=1,3)
       end do
    end if

! Finding atoms in electrode 1 where to attach Bethe lattices

    nblatoms1 = 0

    if (nneig1 == 6 .and. (ANLead1 == 6 .or. ANLead1 == 1 .or. ANLead1 == 83 .or. ANLead1 == 51)) then
       nj=2
    else
       nj=1
    end if
    do i=1,NEmbed(1)
       ndi=0
       do k1=1,nj
       ndirr=0
       do k=k1,nneig1,nj
          vb(1,k)=vpb1(1,k)*d1
          vb(2,k)=vpb1(2,k)*d1
          vb(3,k)=vpb1(3,k)*d1
          do j=1,nlead1
             v(1,j)=xl1(j)-xl1(i)
             v(2,j)=yl1(j)-yl1(i)
             v(3,j)=zl1(j)-zl1(i)
             if (abs(vb(1,k)-v(1,j))<=smalld.and.abs(vb(2,k)-v(2,j))<=smalld.and.abs(vb(3,k)-v(3,j))<=smalld) goto 333
          end do
          if (nneig1 == 12 .or. nneig1 == 8) then
             scalar=vb(1,k)*aplane(1,1)+vb(2,k)*aplane(2,1)+vb(3,k)*aplane(3,1)
             if (scalar < -1.0*small) goto 333
          end if
          ndirr=ndirr+1
          nvbet(i,ndi+ndirr)=k
333    end do
       if (nneig1 == 6 .and. (ANLead1 == 6 .or. ANLead1 == 1 .or. ANLead1 == 83 .or. ANLead1 == 51)) then
       if (ndirr == 3) then
          do j=1,3
             nvbet(i,ndi+j)=0
          end do
          ndirr=0
       end if
       end if
       ndi=ndi+ndirr
       end do 
       ndir(i)=ndi
       if (ndi /= 0) ifrpl(i)=1

       do j=1,ndir(i)
          k=nvbet(i,j)
          !WRITE(ifu_log,'A,3(F11.6)')'Ar',au2ang*(xl1(i)+vb(1,k)),au2ang*(yl1(i)+vb(2,k)),au2ang*(zl1(i)+vb(3,k))
          ! Coordinates of a new Bethe lattice atom
          xbla = au2ang*(xl1(i)+vb(1,k))
          ybla = au2ang*(yl1(i)+vb(2,k))
          zbla = au2ang*(zl1(i)+vb(3,k))
          ! Find out whehter Bethe lattice atom already exists
          do ibl=1,nblatoms1
             if( abs(xbla-xbl1(ibl))<=smalld .and. abs(ybla-ybl1(ibl))<=smalld .and. abs(zbla-zbl1(ibl))<=smalld )exit
          end do
          if( ibl > nblatoms1 )then
             nblatoms1=nblatoms1+1
             xbl1(nblatoms1) = xbla
             ybl1(nblatoms1) = ybla
             zbl1(nblatoms1) = zbla
          end if

       end do
       nbethe=nbethe+ndir(i)
    end do

    REWIND(ifu_xyz)
    write(ifu_xyz,'(I5)'), GetNAtoms()+nblatoms1+nblatoms2
    write(ifu_xyz,*)
    do ibl=1,nblatoms1
       WRITE(ifu_xyz,' (A2,3(F11.6))') 'Ar', xbl1(ibl), ybl1(ibl), zbl1(ibl)
    end do
    DO i=1,GetNAtoms()
       WRITE(ifu_xyz,'(A2,3(F11.6))') IEl(GetAN(i)), au2ang*GetAtmCo(1,i), au2ang*GetAtmCo(2,i), au2ang*GetAtmCo(3,i)
    END DO
    
    if( ANT1DInp )then
       OPEN(unit=ifu_ant,file=trim(ant1dname)//'.xyz',status='unknown')
       write(ifu_ant,*), GetNAtoms()
       write(ifu_ant,*)
       DO i=1,GetNAtoms()
          WRITE(ifu_ant,'(I2,3(F11.6))') GetAN(i), au2ang*GetAtmCo(1,i), au2ang*GetAtmCo(2,i), au2ang*GetAtmCo(3,i)
       END DO
       close(ifu_ant)
       OPEN(unit=ifu_ant,file='bl1.'//trim(ant1dname)//'.xyz',status='unknown')
       write(ifu_ant,*), nblatoms1
       write(ifu_ant,*)
       do ibl=1,nblatoms1
          WRITE(ifu_ant,' (I2,3(F11.6))') ANLead1, xbl1(ibl), ybl1(ibl), zbl1(ibl)
       end do
       close(ifu_ant)
    end if

  END SUBROUTINE AnalyseClusterElectrodeOne

  SUBROUTINE AnalyseClusterElectrodeTwo
    use parameters, only: ANT1DInp, small, smalld, PlBethe1, PlBethe2, NoCloseHex
    USE preproc, ONLY: MaxAtm
    USE g09Common, ONLY: GetNShell, GetAtm4Sh, Get1stAO4Sh, GetNBasis, GetAN, GetAtmChg, GetAtmCo, GetNAtoms
    use ANTCommon
    IMPLICIT NONE

    real,    PARAMETER :: sq2inv=0.707106781
    integer :: dos=2
    integer, PARAMETER :: MaxEl=104,ein=1

    integer, DIMENSION(3), PARAMETER :: AOT = (/ 1,2,3 /)

    real :: d1,d2,ddd,scalar                             
    integer :: n,nt,nn1,nn2
    real, DIMENSION(3,MaxAtm) :: v
    real, DIMENSION(3) :: vv
    real :: vb(3,12)
    real :: CQ(3),CQp(3,MaxAtm),ztotp(MaxAtm)
    integer, DIMENSION(MaxAtm) :: iplane, nfrsp, nlstp, ntotp
    real :: u3(3),bb(3),aplane(3,MaxAtm), vpr(3,nvec), ud(3,MaxAtm,nvec), vprt(3,nvec)
    integer :: nvpl(MaxAtm), invpl(MaxAtm),nbethe        !!, itype(2,MaxAtm)
    integer :: IEl(MaxEl+1)

    integer :: i, ntot, nsw, nplane, j, l, iplfront1, iplfront2, k, icopl, &
         iii, jjj, i1, iivec, iil, kk, ll, lerr, nj, k1, ndi, ndirr
    
    real :: alpha, eta, smallp, pi, one, zero,au2ang, dvec, ztot, &
         u1x, u1y, u1z, u2x, u2y, u2z, bbnorm, product, u3norm, d2cq, dmax2, dmax3, &
         dtemp, xupcq, yupcq, zupcq, coscqpcq, ddx, ddy, ddz, dist, angvec, &
         xx, yy, zz, cosudvpr, yyy, zzz, vnorm, coscqpvpr

    ! Coordinates of Bethe lattice atoms for each electrode
    real, DIMENSION(MaxAtm*10) :: xbl1, ybl1, zbl1,  xbl2, ybl2, zbl2
    ! Number of Bethe lattice atoms for each electrode
    integer :: nblatoms1, nblatoms2, ibl
    ! Coordnates of a Bethe lattice atom
    real :: xbla, ybla, zbla
    ! Added by C. Salgado to work with Geometry
    real,  parameter :: PI_8  = 4 * atan (1.0_8)
    real :: cross(3)
    real :: crossmod
    integer :: nbethecount
    
    !C
    CALL FillEl(ein,MaxEl,IEl)
    !C Setting to zero all arrays ...
    ifrpl=0
    iplane=0
    nfrsp=0
    nlstp=0
    ntotp=0       
    nvpl=0
    invpl=0
    ndir=0
    nvbet=0
    ud=0.0d0
    vpb1=0.0d0
    vpb2=0.0d0
    vprt=0.0d0
    vpr=0.0d0
    !
    !    DEFINITION OF LOCAL VARIABLES
    !
    smallp = 1.d-2
    pi = ACOS(-1.)
    one = 1.d0
    zero = 0.d0
    au2ang = 0.52918d0
    dvec = 3.0/au2ang
    !
    !    DETERMINING THE NO. OF ORBITALS PER ATOM
    !
    ntot=0
    DO i=1,GetNShell()-1
       IF (GetAtm4Sh(i).NE.GetAtm4Sh(i+1)) THEN 
          ! Number of orbitals on atom center GetAtm4Sh(i)
          NAO(GetAtm4Sh(i))=Get1stAO4Sh(i+1)-(ntot+1)
          ! Highest orbital number (within cluster) on atom center GetAtm4Sh(i)
          HAO(GetAtm4Sh(i))=Get1stAO4Sh(i+1)-1
          ! Lowest orbital number (within cluster) on atom center GetAtm4Sh(i)
          LAO(GetAtm4Sh(i))=HAO(GetAtm4Sh(i))-NAO(GetAtm4Sh(i))+1
          ntot=ntot+NAO(GetAtm4Sh(i))
       ENDIF
    ENDDO
    NAO(GetAtm4Sh(GetNShell()))=GetNBasis()-ntot
    LAO(GetAtm4Sh(GetNShell()))=HAO(GetAtm4Sh(GetNShell())-1)+1
    HAO(GetAtm4Sh(GetNShell()))=LAO(GetAtm4Sh(GetNShell()))+NAO(GetAtm4Sh(GetNShell()))-1
    
    WRITE(IFU_LOG,*) '----------------------------------------------------------'
    WRITE(IFU_LOG,*) 'Analyzing cluster for the connection of the  Bethe Lattice'
    WRITE(IFU_LOG,*) '----------------------------------------------------------'
    !
    !    DETERMINING THE POSITIONS AND TYPE OF CLUSTER ATOMS
    !    AS WELL AS THE CENTER OF CHARGE OF THE MOLECULE
    !
    ! Los datos deben introducirse:
    !            Plano al que se adjunta la red de Bethe por la izquierda
    !            Otros Atomos del cluster de la izquierda
    !            Sistema molecular 
    !            Otros Atomos del cluster de la derecha
    !            Plano al que se adjunta la red de Bethe por la derecha
    !
    nlead2=0
    NOrbMT = 0
    nmol = 0
    nsw = 0
    CQ(1) = 0.d0
    CQ(2) = 0.d0
    CQ(3) = 0.d0
    ztot = 0.d0

    ANLead2 = GetAN(GetNAtoms())

    PRINT *
    PRINT ('(A,A2)'), " Atom type of lead 2: ", IEl(ANLead2)
    PRINT *

    IF( GetAN(GetNAtoms()) /= GetAN(GetNAtoms()-1) .OR. GetAN(GetNAtoms()) /= GetAN(GetNAtoms()-2) )THEN
       PRINT *, "ERROR: Too few atoms to define right electrode."
       STOP
    END IF

    DO i=1,GetNAtoms()
       WRITE(IFU_LOG,'(2(2X,I3),2X,F3.0,3(1X,I4))')i,GetAN(i), &
            &       GetAtmChg(i),NAO(i),LAO(i),HAO(i)
       ztotp(i) = 0.d0
       CQp(1,i) = 0.d0
       CQp(2,i) = 0.d0
       CQp(3,i) = 0.d0
       CQ(1) = CQ(1) + GetAtmCo(1,i)*GetAN(i)
       CQ(2) = CQ(2) + GetAtmCo(2,i)*GetAN(i)
       CQ(3) = CQ(3) + GetAtmCo(3,i)*GetAN(i)
       ztot = ztot + GetAN(i)
    END DO
    CQ(1) = CQ(1)/ztot
    CQ(2) = CQ(2)/ztot
    CQ(3) = CQ(3)/ztot

    PRINT *
    WRITE(IFU_LOG,*) ' Center of charge:'
    WRITE(IFU_LOG,'(3(1X,F10.6))') (CQ(i),i=1,3)
    PRINT *

    IF (NAtomEl(2)/=0) THEN
       nlead2=NAtomEl(2)
       j=0
       DO i=GetNAtoms(),GetNAtoms()-nlead2+1,-1
          j=j+1
          XL2(j) = GetAtmCo(1,i)
          YL2(j) = GetAtmCo(2,i)
          ZL2(j) = GetAtmCo(3,i)
       END DO
    ELSE
       ! Find all atoms in right lead
       DO i=GetNAtoms(),1,-1
          IF( GetAN(i) == ANLead2 )THEN
             nlead2=nlead2+1
             XL2(nlead2) = GetAtmCo(1,i)
             YL2(nlead2) = GetAtmCo(2,i)
             ZL2(nlead2) = GetAtmCo(3,i)
          ELSE
             EXIT
          END IF
       END DO
    END IF

    ! Find all atoms in molecule
    DO i=1,GetNAtoms()-nlead2
       nmol=nmol+1
       NOrbMT = NOrbMT + NAO(i)
       ANMol(nmol) = GetAN(i)
       XM(nmol) = GetAtmCo(1,i)
       YM(nmol) = GetAtmCo(2,i)
       ZM(nmol) = GetAtmCo(3,i)
    ENDDO

    nbethe=0
    WRITE(IFU_LOG,*) ' Atoms in molecule:', nmol
    DO i=1,nmol
       WRITE(IFU_LOG,' (1X,I3,2X,A2,3(1X,F10.6))') &
            & i,IEl(ANMol(i)),XM(i),YM(i),ZM(i)
       nbethe=nbethe+1
    ENDDO
    PRINT *
    WRITE(IFU_LOG,*) ' Atoms in substrate:',nlead2
    DO i=1,nlead2
       WRITE(IFU_LOG,' (1X,I3,2X,A2,3(1X,F10.6))') &
            & i+nmol,IEl(ANLead2),XL2(i),YL2(i),ZL2(i)
       nbethe=nbethe+1
    ENDDO
    PRINT *

    !
    !   DETERMINE THE PLANES OF ATOMS PRESENT IN THE MOLECULE 
    !   TOGETHER WITH THEIR RESPECTIVE CENTER OF CHARGE AND
    !   DIRECTOR VECTOR
    !
    nplane = 0
    IF (GetNAtoms() .GT. 3) THEN

       IF(nlead2.GE.3) THEN
          i = GetNAtoms()

          u1x = GetAtmCo(1,i) - GetAtmCo(1,i-1)
          u1y = GetAtmCo(2,i) - GetAtmCo(2,i-1)
          u1z = GetAtmCo(3,i) - GetAtmCo(3,i-1)
          
 13       u2x = GetAtmCo(1,i) - GetAtmCo(1,i-dos)
          u2y = GetAtmCo(2,i) - GetAtmCo(2,i-dos)
          u2z = GetAtmCo(3,i) - GetAtmCo(3,i-dos)

          bb(1) = u1y*u2z-u2y*u1z
          bb(2) = u2x*u1z-u1x*u2z
          bb(3) = u1x*u2y-u2x*u1y
          
          bbnorm = dsqrt(bb(1)*bb(1) &
               & + bb(2)*bb(2) &
               & + bb(3)*bb(3) )

          IF (ABS(bbnorm).LT.smallp) then
              write(ifu_log,*)'Last 3 atoms in line in electrode 2 !!!!'
              dos =dos +1
              goto 13
              stop
          END IF

          bb(1) = bb(1)/bbnorm
          bb(2) = bb(2)/bbnorm
          bb(3) = bb(3)/bbnorm
          
          product = 0.d0

          IF( ABS(product) .LT. smallp .AND. &
               &  iplane(i-1) .EQ. 0 .AND. &
               &  iplane(i-2) .EQ. 0 ) THEN        

             nplane = nplane + 1
             nfrsp(nplane)=i-2

             nlstp(nplane)=i
             ntotp(nplane)=nlstp(nplane)-nfrsp(nplane)+1
             iplane(i)   = nplane
             iplane(i-1) = nplane
             iplane(i-2) = nplane

             aplane(1,nplane) = bb(1)
             aplane(2,nplane) = bb(2)
             aplane(3,nplane) = bb(3)
             CQp(1,nplane) =   CQp(1,nplane) &
                  &        + GetAtmCo(1,i)*GetAN(i) &
                  &        + GetAtmCo(1,i-1)*GetAN(i-1) &
                  &        + GetAtmCo(1,i-2)*GetAN(i-2) 

             CQp(2,nplane) =   CQp(2,nplane) &
                &        + GetAtmCo(2,i)*GetAN(i) &
                &        + GetAtmCo(2,i-1)*GetAN(i-1) &
                &        + GetAtmCo(2,i-2)*GetAN(i-2) 

             CQp(3,nplane) =   CQp(3,nplane) &
                  &        + GetAtmCo(3,i)*GetAN(i) &
                  &        + GetAtmCo(3,i-1)*GetAN(i-1) &
                  &        + GetAtmCo(3,i-2)*GetAN(i-2) 

             ztotp(nplane) = ztotp(nplane) + GetAN(i) + &
                  &          GetAN(i-1) + GetAN(i-2) 

             DO j = i-3,GetNAtoms()-nlead2+1,-1

                u3(1) = GetAtmCo(1,i) - GetAtmCo(1,j)
                u3(2) = GetAtmCo(2,i) - GetAtmCo(2,j)
                u3(3) = GetAtmCo(3,i) - GetAtmCo(3,j)
                u3norm = dsqrt(u3(1)*u3(1) &
                     & + u3(2)*u3(2) &
                     & + u3(3)*u3(3) )
                u3(1) = u3(1)/u3norm
                u3(2) = u3(2)/u3norm
                u3(3) = u3(3)/u3norm
                product = 0.d0
                DO l = 1,3
                   product = product + u3(l)*bb(l)
                ENDDO
                IF (ABS(product) .LT. smallp .AND. &
                     & iplane(j) .EQ. 0 ) THEN
                   iplane(j)=nplane
                   nfrsp(nplane)=j
                   ntotp(nplane)=ntotp(nplane)+1
                   CQp(1,nplane) = CQp(1,nplane)  + GetAtmCo(1,j)*GetAN(j)
                   CQp(2,nplane) = CQp(2,nplane)  + GetAtmCo(2,j)*GetAN(j)
                   CQp(3,nplane) = CQp(3,nplane)  + GetAtmCo(3,j)*GetAN(j)
                   ztotp(nplane) = ztotp(nplane)  + GetAN(j)
                ENDIF
             ENDDO
          ENDIF
       ENDIF
    ENDIF
          
    !C    DETERMINE THE FRONTIER PLANES WITHIN THE ABOVE PLANES
    !C    AND ORIENTATE THEIR DIRECTOR VECTOR IN THE DIRECTION
    !C    POINTING OUTSIDE THE CLUSTER
    !C
    iplfront1 = 0
    iplfront2 = 0
    DO i=1,nplane
       CQp(1,i) = CQp(1,i)/ztotp(i)
       CQp(2,i) = CQp(2,i)/ztotp(i)
       CQp(3,i) = CQp(3,i)/ztotp(i)
       d2CQ = dsqrt((CQp(1,i)-CQ(1))**2 + (CQp(2,i)-CQ(2))**2 + &
            & (CQp(3,i)-CQ(3))**2)
       IF (iplfront1 .EQ. 0) THEN
          dmax2 = d2CQ
          dmax3 = dmax2
          iplfront1 = i
          iplfront2 = iplfront1
       ELSE IF (d2CQ .GE. dmax2) THEN
          dtemp = dmax2
          dmax2 = d2CQ
          dmax3 = dtemp
          iplfront2 = iplfront1
          iplfront1 = i
       ELSE IF (d2CQ .GE. dmax3 .OR. dmax2 .EQ. dmax3) THEN
          dmax3 = d2CQ
          iplfront2 = i
       ENDIF

       xupCQ = CQp(1,i)-CQ(1)
       yupCQ = CQp(2,i)-CQ(2)
       zupCQ = CQp(3,i)-CQ(3)
       cosCQpCQ =xupCQ*aplane(1,i)+yupCQ*aplane(2,i)+zupCQ*aplane(3,i)
       IF (cosCQpCQ .LT. 0.d0) THEN
          invpl(i) = 1
          DO k=1,3
             aplane(k,i)=-aplane(k,i)
          ENDDO
       ENDIF
       WRITE(ifu_log,'(A,I1)') ' Plane ',i 
       WRITE(ifu_log,'(A,F10.6,A1,F10.6,A1,F10.6,A)') ' with normal vector (', aplane(1,i),',',aplane(2,i),',',aplane(3,i), ' )'
       WRITE(ifu_log,'(A,I4,A)') ' has ', ntotp(i), ' atoms:'
       DO j=nfrsp(i),nlstp(i)
          WRITE(ifu_log,'(2(2X,I3),3(F11.6))') j,iplane(j),GetAtmCo(1,j),GetAtmCo(2,j),GetAtmCo(3,j)
       ENDDO
       PRINT *
    ENDDO
    !
    !    Warning message  if there are less than two planes
    !
    IF (nplane .LT. 2) THEN
       WRITE(ifu_log,*) 'WARNING!!: There is a missing plane. The transmission cannot be calculated !!!'
    ENDIF
    !
    !
    if (NEmbed(2) == 0) NEmbed(2) = ntotp(1)
    if (NEmbed(2) > nlead2 ) NEmbed(2) = nlead2
    if (NEmbed(2) > nlead2 ) WRITE(6,*) 'WARNING!! check the coordinates file'

    nn2 = NEmbed(2)

    ! Finding lattice parameter for electrode 2

    if(PlBethe2)then
        nbethecount = NEmbed(2) ! Build a plane Bethe lattice from plane.
    else
      if(nlead2==1)then
        nbethecount = nlead2+1 ! 1D Bethe Lattice
      else
        nbethecount = nlead2 ! Build a bulk Bethe lattice taking into account various planes.
      end if
    end if

    write(ifu_log,*)'Finding lattice directions in electrode 2 ....'
    d2=100000000.0
    do i=1,NEmbed(2)
       do j=i+1,nlead2
          ddd=dsqrt((xl2(j)-xl2(i))**2+(yl2(j)-yl2(i))**2+(zl2(j)-zl2(i))**2)
          if (ddd <= d2) d2=ddd
       end do
    end do
    print *, "Near-neighbor distance at electrode 2 = ", d2*au2ang

    nneig2=0
    do i=1,NEmbed(2)
       !do j=i+1,nlead2
       do j=i+1,nbethecount
          vv(1)=xl2(j)-xl2(i)
          vv(2)=yl2(j)-yl2(i)
          vv(3)=zl2(j)-zl2(i)
          ddd=dsqrt(vv(1)**2+vv(2)**2+vv(3)**2)
          if (dabs(ddd-d2) > smalld) cycle
          vv(1)=vv(1)/ddd
          vv(2)=vv(2)/ddd
          vv(3)=vv(3)/ddd
          do k=1,nneig2
             scalar=vv(1)*vpb2(1,k)+vv(2)*vpb2(2,k)+vv(3)*vpb2(3,k)
             if (abs(scalar-1.0) <= small) goto 222
          end do
          nneig2=nneig2+1
          vpb2(1,nneig2)=vv(1)                   
          vpb2(2,nneig2)=vv(2)
          vpb2(3,nneig2)=vv(3)
          nneig2=nneig2+1
          vpb2(1,nneig2)=-vv(1)                   
          vpb2(2,nneig2)=-vv(2)
          vpb2(3,nneig2)=-vv(3)
222    end do
    end do

!    if (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51) then
!       vpb2(1,5)=-(vpb2(1,1)+vpb2(1,3))     
!       vpb2(2,5)=-(vpb2(2,1)+vpb2(2,3))
!       vpb2(3,5)=-(vpb2(3,1)+vpb2(3,3))
!       vpb2(1,6)=-vpb2(1,5)    
!       vpb2(2,6)=-vpb2(2,5)
!       vpb2(3,6)=-vpb2(3,5)
!       nneig2 = 6
!    end if
    
  if (NoCloseHex)then
    if (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51) then
 ! When there are no closed hexagons, I compute the cross product of the plane-normal vector with the only lattice direction stored in the vectors vpb1(1:3,1) and its opposite vpb1(1:3,2).

       if(DOT_PRODUCT(aplane(:,2),aplane(:,2))==0) aplane(:,2) = aplane(:,1)

       write(ifu_log,*)'vpb2(1:3,1)'
       write(ifu_log,*)(vpb2(i,1),i=1,3)
       write(ifu_log,*)'vpb2(1:3,2)'
       write(ifu_log,*)(vpb2(i,2),i=1,3)
       write(ifu_log,*)'aplane(1:3,2)'
       write(ifu_log,*)(aplane(i,2),i=1,3)

       cross(1) = vpb2(2,1) * aplane(3,2) - vpb2(3,1) * aplane(2,2)
       cross(2) = vpb2(3,1) * aplane(1,2) - vpb2(1,1) * aplane(3,2)
       cross(3) = vpb2(1,1) * aplane(2,2) - vpb2(2,1) * aplane(1,2)
       crossmod=dsqrt(cross(1)**2+cross(2)**2+cross(3)**2)
       cross(1)=cross(1)/crossmod
       cross(2)=cross(2)/crossmod
       cross(3)=cross(3)/crossmod	! normalize the vector to modulus 1.0
       
       write(ifu_log,*)'cross(1:3)'
       write(ifu_log,*)(cross(i),i=1,3)

       crossmod=dsqrt(vpb2(1,1)**2+vpb2(2,1)**2+vpb2(3,1)**2)

       !vpb2(1,3)=-(cos(PI_8/3.0)*vpb2(1,1) + d2*sin(PI_8/3.0)*cross(1)) 
       vpb2(1,3)=-(cos(PI_8/3.0)*vpb2(1,1) + sin(PI_8/3.0)*cross(1))      
       vpb2(2,3)=-(cos(PI_8/3.0)*vpb2(2,1) + sin(PI_8/3.0)*cross(2)) 
       vpb2(3,3)=-(cos(PI_8/3.0)*vpb2(3,1) + sin(PI_8/3.0)*cross(3)) 
       vpb2(1,4)=-vpb2(1,3)    
       vpb2(2,4)=-vpb2(2,3)
       vpb2(3,4)=-vpb2(3,3)

       vpb2(1,5)=-(cos(PI_8/3.0)*vpb2(1,1) - sin(PI_8/3.0)*cross(1))     
       vpb2(2,5)=-(cos(PI_8/3.0)*vpb2(2,1) - sin(PI_8/3.0)*cross(2)) 
       vpb2(3,5)=-(cos(PI_8/3.0)*vpb2(3,1) - sin(PI_8/3.0)*cross(3)) 
       vpb2(1,6)=-vpb2(1,5)    
       vpb2(2,6)=-vpb2(2,5)
       vpb2(3,6)=-vpb2(3,5)
       nneig2 = 6
    end if
  else
    if (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51) then
      vpb2(1,5)=-(vpb2(1,1)+vpb2(1,3))
      vpb2(2,5)=-(vpb2(2,1)+vpb2(2,3))
      vpb2(3,5)=-(vpb2(3,1)+vpb2(3,3))
      vpb2(1,6)=-vpb2(1,5)
      vpb2(2,6)=-vpb2(2,5)
      vpb2(3,6)=-vpb2(3,5)
      nneig2 = 6
    end if
  end if

    if (nneig2 /= 12 .and. nneig2 /=8 .and. nneig2 /=6 .and. nneig2 /=4) then
       write(ifu_log,'(A6,i10,A20)')'Found ',nneig2, 'lattice directions'
       write(ifu_log,*)'Problem finding lattice directions in electrode 2 !!!!!'
       stop
    else
       write(ifu_log,'(A6,i10,A20)')'Found ',nneig2, 'lattice directions'
       do i=1,nneig2
          write(ifu_log,'(3f10.5)')(vpb2(j,i),j=1,3)
       end do
    end if

! Finding atoms in electrode 2 where to attach Bethe lattices

    nblatoms2 = 0

    if (nneig2 == 6 .and. (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51)) then
       nj=2
    else
       nj=1
    end if

    do i=GetNAtoms(),GetNAtoms()-NEmbed(2)+1,-1
       ndi=0
       do k1=1,nj
       ndirr=0
       do k=k1,nneig2,nj
          vb(1,k)=vpb2(1,k)*d2
          vb(2,k)=vpb2(2,k)*d2
          vb(3,k)=vpb2(3,k)*d2
          do j=GetNAtoms(),GetNAtoms()-nlead2+1,-1
             if (i == j) cycle
             v(1,j)=GetAtmCo(1,j)-GetAtmCo(1,i)
             v(2,j)=GetAtmCo(2,j)-GetAtmCo(2,i)
             v(3,j)=GetAtmCo(3,j)-GetAtmCo(3,i)
             if (abs(vb(1,k)-v(1,j))<=smalld.and.abs(vb(2,k)-v(2,j))<=smalld.and.abs(vb(3,k)-v(3,j))<=smalld) goto 444
          end do
          if (nneig2 == 12 .or. nneig2 == 8) then
             scalar=vb(1,k)*aplane(1,1)+vb(2,k)*aplane(2,1)+vb(3,k)*aplane(3,1)
             if (scalar < -1.0*small) goto 444
          end if
          ndirr=ndirr+1
          nvbet(i,ndi+ndirr)=k
444    end do
       if (nneig2 == 6 .and. (ANLead2 == 6 .or. ANLead2 == 1 .or. ANLead2 == 83 .or. ANLead2 == 51)) then
       if (ndirr == 3) then
          do j=1,3
             nvbet(i,ndi+j)=0
          end do
          ndirr=0
       end if
       end if
       ndi=ndi+ndirr
       end do 
       ndir(i)=ndi
       if (ndi /= 0) ifrpl(i)=2

       do j=1,ndir(i)
          k=nvbet(i,j)
          !WRITE(ifu_log,'A,3(F11.6)')'Ar',(au2ang*(GetAtmCo(n,i)+vb(n,k)),n=1,3)  
          ! Coordinates of a new Bethe lattice atom
          xbla = (GetAtmCo(1,i)+vb(1,k))/au2ang
          ybla = (GetAtmCo(2,i)+vb(2,k))/au2ang
          zbla = (GetAtmCo(3,i)+vb(3,k))/au2ang
          ! Find out whether Bethe lattice atom already exists
          do ibl=1,nblatoms2
             if( abs(xbla-xbl2(ibl))<=smalld .and. abs(ybla-ybl2(ibl))<=smalld .and. abs(zbla-zbl2(ibl))<=smalld )exit
          end do
          ! If not found at new Bethe lattice atom to list
          if( ibl > nblatoms2 )then
             nblatoms2=nblatoms2+1
             xbl2(nblatoms2) = xbla
             ybl2(nblatoms2) = ybla
             zbl2(nblatoms2) = zbla
          end if

       end do
       nbethe=nbethe+ndir(i)
    end do

    !
    !    OPEN A FILE FOR FURTHER CHECK OF BETHE LATTICE DIRECTIONS 
    !
    !OPEN(unit=ifu_xyz,file='XYZ.'//trim(xxx)//'.dat',status='unknown')
    REWIND(ifu_xyz)
    write(ifu_xyz,'(I5)'), GetNAtoms()+nblatoms2
    write(ifu_xyz,*)
       DO i=1,GetNAtoms()
          WRITE(ifu_xyz,'(A2,3(F11.6))') IEl(GetAN(i)), au2ang*GetAtmCo(1,i), au2ang*GetAtmCo(2,i), au2ang*GetAtmCo(3,i)
       END DO
       do ibl=1,nblatoms2
          WRITE(ifu_xyz,' (A2,3(F11.6))') 'Ar', xbl2(ibl), ybl2(ibl), zbl2(ibl)
       end do
    !CLOSE(ifu_xyz)

    if( ANT1DInp )then
       OPEN(unit=ifu_ant,file=trim(ant1dname)//'.xyz',status='unknown')
       write(ifu_ant,*), GetNAtoms()
       write(ifu_ant,*)
       DO i=1,GetNAtoms()
          WRITE(ifu_ant,'(I2,3(F11.6))') GetAN(i), au2ang*GetAtmCo(1,i), au2ang*GetAtmCo(2,i), au2ang*GetAtmCo(3,i)
       END DO
       close(ifu_ant)
       OPEN(unit=ifu_ant,file='bl2.'//trim(ant1dname)//'.xyz',status='unknown')       
       write(ifu_ant,*), nblatoms2
       write(ifu_ant,*)
       do ibl=1,nblatoms2
          WRITE(ifu_ant,' (I2,3(F11.6))') ANLead2, xbl2(ibl), ybl2(ibl), zbl2(ibl)
       end do
       close(ifu_ant)
    end if

  END SUBROUTINE AnalyseClusterElectrodeTwo


  !***********************************************
  ! Computes rotation matrix for direction (x,y,z)
  !***********************************************
  SUBROUTINE cmatr(numorb,AOT,x,y,z,tr)
    IMPLICIT NONE
    
    integer, INTENT(in) :: numorb
    integer, DIMENSION(numorb), INTENT(in) :: AOT
    real, INTENT(in) :: x,y,z
    real, DIMENSION(numorb,numorb), INTENT(out) :: tr
    
    ! transformation matrices for s-, p- d- and f-orbitals
    real :: trs(1,1),trp(3,3),trd(5,5), trf(7,7)

    real, PARAMETER :: CUT1=1.0D-10, CUT2=1.0D-06

    integer :: i, j, k
    real :: sq3, cost, sint, cosp, sinp, cos2t, sin2t, cos2p, sin2p
    
    sq3 = SQRT(3.0d0)
    cost = z 

    SINT = 0.0D0
    IF((1.0D0-COST**2).GT.CUT1) SINT = DSQRT(1.0D0-COST**2)
    COSP = 1.0D0
    SINP = 0.0D0
    IF(SINT.GT.CUT2) COSP = X / SINT
    IF(SINT.GT.CUT2) SINP = Y / SINT
    
    ! s-orbital transformation
    trs=1.0d0
        
    trp=0.0d0
    ! p-orbitals transformation
    trp(1,1) = cost * cosp
    trp(1,2) = -sinp
    trp(1,3) = sint * cosp
    trp(2,1) = cost * sinp
    trp(2,2) = cosp
    trp(2,3) = sint * sinp
    trp(3,1) = -sint
    trp(3,3) = cost
    
    cos2t = cost**2 - sint**2
    sin2t = 2.d0 * sint * cost  
    cos2p = cosp**2 - sinp**2
    sin2p = 2.d0 * sinp * cosp
    
    trd=0.d0
    ! d-orbitals transformation
    trd(1,1) = (3.d0 * cost**2 - 1.d0) / 2.d0
    trd(1,2) = - sq3 * sin2t / 2.d0
    trd(1,4) = sq3 * sint**2 / 2.d0
    trd(2,1) = sq3 * sin2t * cosp / 2.d0 
    trd(2,2) = cos2t * cosp
    trd(2,3) = -cost * sinp
    trd(2,4) = -trd(2,1) / sq3
    trd(2,5) = sint * sinp
    trd(3,1) = sq3 * sin2t * sinp / 2.d0 
    trd(3,2) = cos2t * sinp
    trd(3,3) = cost * cosp 
    trd(3,4) = -trd(3,1) / sq3 
    trd(3,5) = -sint * cosp
    trd(4,1) = sq3 * sint**2 * cos2p / 2.d0
    trd(4,2) = sin2t * cos2p / 2.d0
    trd(4,3) = -sint * sin2p
    trd(4,4) = (1.d0 + cost**2) * cos2p / 2.d0
    trd(4,5) = -cost * sin2p
    trd(5,1) = sq3 * sint**2 * sin2p / 2.d0
    trd(5,2) = sin2t * sin2p / 2.d0
    trd(5,3) = sint * cos2p
    trd(5,4) = (1.d0 + cost**2) * sin2p / 2.d0
    trd(5,5) = cost * cos2p
    
    ! f-orbitals transformation
    trf=1.0

    tr=0.d0
    DO i=1,numorb
       IF( AOT(i) == 0 )THEN
          tr(i,i) = trs(1,1)
       ELSE IF( AOT(i) == 1 ) THEN
          DO j=1,3
             DO k=1,3 
                tr(i-1+j,i-1+k) = trp(j,k)
             END DO
          END DO
       ELSE IF( AOT(i) == 4 ) THEN
          DO j=1,5
             DO k=1,5
                tr(i-1+j,i-1+k) = trd(j,k)
             END DO
          END DO
       ELSE IF( AOT(i) == 9 ) THEN
          DO j=1,7
             DO k=1,7
                tr(i-1+j,i-1+k) = trf(j,k)
             END DO
          END DO
       END IF
    END DO

    
  END SUBROUTINE cmatr


      Subroutine FillEl(ISt,IEnd,El)
      Implicit Integer(A-Z)
!C
!C     Load array El with the names of the elements from ISt to IEnd.
!C     ISt can be zero, in which case El starts with Banquo, or -1, in
!C     which case El starts with X
!C
      Parameter (MinEl=-2,MaxEl=118)
      Dimension ElDat(MinEl:MaxEl), El(ISt:IEnd)
      Save ElDat, Quest
      Data ElDat/2hTV,2hX ,2HBq,2HH ,2HHe,2HLi,2HBe,2HB ,2HC ,&
     2HN ,2HO ,2HF ,2HNe,2HNa,2HMg,2HAl,2HSi,2HP ,2HS ,2HCl,2HAr,2HK ,&
     2HCa,2HSc,2HTi,2HV ,2HCr,2HMn,2HFe,2HCo,2HNi,2HCu,2HZn,2HGa,2HGe,&
     2HAs,2HSe,2HBr,2HKr,2HRb,2HSr,2HY ,2HZr,2HNb,2HMo,2HTc,2HRu,2HRh,&
     2HPd,2HAg,2HCd,2HIn,2HSn,2HSb,2HTe,2HI ,2HXe,2HCs,2HBa,2HLa,2HCe,&
     2HPr,2HNd,2HPm,2HSm,2HEu,2HGd,2HTb,2HDy,2HHo,2HEr,2HTm,2HYb,2HLu,&
     2HHf,2HTa,2HW ,2HRe,2HOs,2HIr,2HPt,2HAu,2HHg,2HTl,2HPb,2HBi,2HPo,&
     2HAt,2HRn,2HFr,2HRa,2HAc,2HTh,2HPa,2HU ,2hNp,2hPu,2hAm,2hCm,2hBk,&
     2hCf,2hEs,2hFm,2hMd,2hNo,2hLr,2hRf,2hDb,2hSg,2hBh,2hHs,2hMt,2hDs,&
     2hUu,2hUb,2hUt,2hUq,2hUp,2hUh,2hUs,2hUo/,Quest/2h??/
!C
      ISt1 = Max(ISt,MinEl)
      IEnd1 = Min(IEnd,MaxEl)
      Do 10 I = ISt, (ISt1-1)
   10   El(I) = Quest
      Do 20 I = ISt1, IEnd1
   20   El(I) = ElDat(I)
      Do 30 I = (IEnd1+1), IEnd
   30   El(I) = Quest
      Return
      End


  END MODULE Cluster


