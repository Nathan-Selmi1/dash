!*==GET_LOGREF.f90  processed by SPAG 6.11Dc at 13:14 on 17 Sep 2001
!
!*****************************************************************************
!
!
!*****************************************************************************
!
      SUBROUTINE GET_LOGREF(FILE,lenfil,ier)
!
      CHARACTER*(*), INTENT(IN   ) :: FILE
!
      INCLUDE 'PARAMS.INC'
      INCLUDE 'GLBVAR.INC'
      INCLUDE 'statlog.inc'
!
      COMMON /FCSTOR/ MAXK, FOB(150,MFCSTO)
      LOGICAL LOGREF
      COMMON /FCSPEC/ NLGREF, IREFH(3,MFCSPE), LOGREF(8,MFCSPE)
!

! JvdS should be the same thing
!O      COMMON /FCSPC2/ ARGK(MFCSP2), DSTAR(MFCSP2)
      INTEGER NTIC
      INTEGER IH
      REAL    ARGK
      REAL    DSTAR
      COMMON /PROFTIC/ NTIC,IH(3,MTIC),ARGK(MTIC),DSTAR(MTIC)



!
      COMMON /POSNS / NATOM, X(3,150), KX(3,150), AMULT(150), TF(150),  &
     &                KTF(150), SITE(150), KSITE(150), ISGEN(3,150),    &
     &                SDX(3,150), SDTF(150), SDSITE(150), KOM17
!
      COMMON /SAREFLNS/ AIOBS(MSAREF), AICALC(MSAREF)
!
      COMMON /CHISTO/ KKOR, WTIJ(MCHIHS), S2S(MCHIHS), S4S(MCHIHS),     &
     &                IKKOR(MCHIHS), JKKOR(MCHIHS)
!
      LOGICAL IHMINLT0, IKMINLT0, ILMINLT0
      COMMON /CSQLOG/ IHMINLT0, IKMINLT0, ILMINLT0
      COMMON /CSQINT/ IHMIN, IHMAX, IKMIN, IKMAX, ILMIN, ILMAX, IIMIN,  &
     &                IIMAX
!
      COMMON /CHISTOP/ NOBS, NFIT, IFIT(MCHSTP), CHIOBS, WT(MCHSTP),    &
     &                 XOBS(MCHSTP), YOBS(MCHSTP), YCAL(MCHSTP),        &
     &                 ESD(MCHSTP)
!
!     These declarations are needed for the get_logref.inc
!     file to work correctly
!     The following integers represent h,k,l,h+k,h+l,k+l and h+k+l
      INTEGER H_, K_, L_, HPK, HPL, KPL, HPKPL
!     The following integers represent the previous integers, divided by 2
!     and then multiplied by 2
      INTEGER H_m, K_m, L_m, HPKm, HPLm, KPLm, HPKPLm
!
      IHMIN = 9999
      IKMIN = 9999
      ILMIN = 9999
      IIMIN = 9999
      IHMAX = -9999
      IKMAX = -9999
      ILMAX = -9999
      IIMAX = -9999
      ier = 0
      OPEN (31,FILE=FILE(1:Lenfil),STATUS='OLD',ERR=998)
!
!**
!      MAXXKK=100000
      MAXXKK = MFCSPE
      MAXK = 0
      DO IR = 1, MAXXKK
        READ (31,*,ERR=998,END=200) (IREFH(I,IR),I=1,3), ARGK(IR),DSTAR(IR)
        MAXK = MAXK + 1
        IHMIN = MIN(IREFH(1,IR),IHMIN)
        IKMIN = MIN(IREFH(2,IR),IKMIN)
        ILMIN = MIN(IREFH(3,IR),ILMIN)
        IHMAX = MAX(IREFH(1,IR),IHMAX)
        IKMAX = MAX(IREFH(2,IR),IKMAX)
        ILMAX = MAX(IREFH(3,IR),ILMAX)
!       Now calculate 'i' index for hexagonals
        ITEM = -(IREFH(1,IR)+IREFH(2,IR))
        IIMIN = MIN(ITEM,IIMIN)
        IIMAX = MAX(ITEM,IIMAX)
      ENDDO
!
  200 CONTINUE
!
      IHMINLT0 = IHMIN.LT.0
      IKMINLT0 = IKMIN.LT.0
      ILMINLT0 = ILMIN.LT.0
!
      IF (ABS(ihmin).GT.ABS(ihmax)) THEN
        ihmax = ABS(ihmin)
      ENDIF
      IF (ABS(ikmin).GT.ABS(ikmax)) THEN
        ikmax = ABS(ikmin)
      ENDIF
      IF (ABS(ilmin).GT.ABS(ilmax)) THEN
        ilmax = ABS(ilmin)
      ENDIF
!
!
! JvdS Replaced include by its contents (the include file was used only once)
!O      include 'GET_LOGREF.inc'
!
!     Decides for each space group, which structure factor
!     calculation should be invoked for each particular reflection.
!     For example, in P 1 21 1, there are two different structure
!     factor expressions, depending upon whether or not "k" is even
!     or odd.  If the LOGREF entry for a particular reflection is
!     set to TRUE, this means that the reflection meets the criterion
!     which comes as a comment directly afterward.  Thus
!     LOGREF(1,IR)=K_.EQ.K_m ! k=2n
!     means that if k is even for the IR'th reflection, then LOGREF
!     for that reflection is set to true.  The following abbreviations
!     are used for reflection indices (all defined as integer in the file
!     get_logref.for
!
!     H_    = h
!     K_    = k
!     L_    = l
!     HPK   = h+k
!     HPL   = h+l
!     KPL   = k+l
!     HPKPL = h+k+l
!
!     Note that when these abbreviations are used with an 'm' appended,
!     they hold the result of some modulus style calculation performed
!     on the related variable.  Hence K_m=2*(K_/2) followed by a test
!     of "does K_ equal K_m?" tests whether or not k is even.
!
!
      SELECT CASE (NumberSGTable)
      CASE (1,2,40,58,430,433,434,435,356,449,451,462,468)      ! P1,P-1,C 1 2 1,C 1 2/m 1,P3,P-3,R3(hex),R-3(hex),I-4,P-31m, P-3m1, P6, P-6
        NLGREF = 0
      CASE (469,471,481,483,485)             ! P6/m, P622, P-6m2, P-62m, P6/mmm
        NLGREF = 0
      CASE (39,57)                           ! P 1 21 1, P 1 21/m 1
        NLGREF = 1
        DO IR = 1, MAXK
          K_ = IREFH(2,IR)
          K_m = 2*(K_/2)
          LOGREF(1,IR) = K_.EQ.K_m ! k=2n
        ENDDO
      CASE (44,50,61,67,116,176,298)         ! P 1 c 1, C 1 c 1, P 1 2/c 1, C 1 21/c 1, C 2 2 21
        NLGREF = 1                          ! C m c 21,C m c m,
        DO IR = 1, MAXK
          L_ = IREFH(3,IR)
          L_m = 2*(L_/2)
          LOGREF(1,IR) = (L_.EQ.L_m) ! l=2n
        ENDDO
      CASE (64,304)                          ! P 1 21/c 1 , C m c a
        NLGREF = 1
        DO IR = 1, MAXK
          KPL = IREFH(2,IR) + IREFH(3,IR)
          KPLm = 2*(KPL/2)
          LOGREF(1,IR) = KPL.EQ.KPLm ! k+l=2n
        ENDDO
      CASE (65)                              ! P 1 21/n 1
        NLGREF = 1
        DO IR = 1, MAXK
          HPKPL = IREFH(1,IR) + IREFH(2,IR) + IREFH(3,IR)
          HPKPLm = 2*(HPKPL/2)
          LOGREF(1,IR) = HPKPL.EQ.HPKPLm ! h+k+l=2n
        ENDDO
      CASE (66)                              ! P 1 21/a 1
        NLGREF = 1
        DO IR = 1, MAXK
          HPK = IREFH(1,IR) + IREFH(2,IR)
          HPKm = 2*(HPK/2)
          LOGREF(1,IR) = HPK.EQ.HPKm ! h+k=2n
        ENDDO
      CASE (52,69)                           ! I 1 a 1,I 1 2/a 1
        NLGREF = 1
        DO IR = 1, MAXK
          H_ = IREFH(1,IR)
          H_m = 2*(H_/2)
          LOGREF(1,IR) = (H_.EQ.H_m) ! h=2n
        ENDDO
      CASE (112)                             ! P 21 21 2
        NLGREF = 1
        DO IR = 1, MAXK
          HPK = IREFH(1,IR) + IREFH(2,IR)
          HPKm = 2*(HPK/2)
          LOGREF(1,IR) = (HPK.EQ.HPKm) ! h+k=2n
        ENDDO
      CASE (115,290)                         ! P21 21 21, P b c a
        NLGREF = 4
        DO IR = 1, MAXK
          HPK = IREFH(1,IR) + IREFH(2,IR)
          KPL = IREFH(2,IR) + IREFH(3,IR)
          HPKm = 2*(HPK/2)
          KPLm = 2*(KPL/2)
          LOGREF(1,IR) = (HPK.EQ.HPKm) .AND. (KPL.EQ.KPLm)
                                                         !h+k=2n,  k+l=2n
          LOGREF(2,IR) = (HPK.EQ.HPKm) .AND. (KPL.NE.KPLm)
                                                         !h+k=2n,  k+l=2n+1
          LOGREF(3,IR) = (HPK.NE.HPKm) .AND. (KPL.EQ.KPLm)
                                                         !h+k=2n+1,k+l=2n
          LOGREF(4,IR) = (HPK.NE.HPKm) .AND. (KPL.NE.KPLm)
                                                         !h+k=2n+1,k+l=2n+1
        ENDDO
      CASE (143)                             ! P c a 21
        NLGREF = 4
        DO IR = 1, MAXK
          H_ = IREFH(1,IR)
          L_ = IREFH(3,IR)
          H_m = 2*(H_/2)
          L_m = 2*(L_/2)
          LOGREF(1,IR) = (H_.EQ.H_m) .AND. (L_.EQ.L_m)
                                                     ! h=2n  ,l=2n
          LOGREF(2,IR) = (H_.EQ.H_m) .AND. (L_.NE.L_m)
                                                     ! h=2n  ,l=2n+1
          LOGREF(3,IR) = (H_.NE.H_m) .AND. (L_.EQ.L_m)
                                                     ! h=2n+1,l=2n
          LOGREF(4,IR) = (H_.NE.H_m) .AND. (L_.NE.L_m)
                                                     ! h=2n+1,l=2n+1
        ENDDO
      CASE (164,284)                         ! P n a 21, P b c n
        NLGREF = 4
        DO IR = 1, MAXK
          HPK = IREFH(1,IR) + IREFH(2,IR)
          L_ = IREFH(3,IR)
          HPKm = 2*(HPK/2)
          L_m = 2*(L_/2)
          LOGREF(1,IR) = (HPK.EQ.HPKm) .AND. (L_.EQ.L_m)
                                                       !h+k=2n,  l=2n
          LOGREF(2,IR) = (HPK.EQ.HPKm) .AND. (L_.NE.L_m)
                                                       !h+k=2n,  l=2n+1
          LOGREF(3,IR) = (HPK.NE.HPKm) .AND. (L_.EQ.L_m)
                                                       !h+k=2n+1,l=2n
          LOGREF(4,IR) = (HPK.NE.HPKm) .AND. (L_.NE.L_m)
                                                       !h+k=2n+1,l=2n+1
        ENDDO
      CASE (212)                             ! F d d 2
        NLGREF = 4
        DO IR = 1, MAXK
          HPKPL = IREFH(1,IR) + IREFH(2,IR) + IREFH(3,IR)
          IREMAIN = MOD(HPKPL,4)
          LOGREF(1,IR) = (IREMAIN.EQ.0) !h+k+l=4n
          LOGREF(2,IR) = (IREMAIN.EQ.1) !h+k+l=4n+1
          LOGREF(3,IR) = (IREMAIN.EQ.2) !h+k+l=4n+2
          LOGREF(4,IR) = (IREMAIN.EQ.3) !h+k+l=4n+3
        ENDDO
      CASE (266)                             ! P c c n
        NLGREF = 4
        DO IR = 1, MAXK
          HPK = IREFH(1,IR) + IREFH(2,IR)
          HPL = IREFH(1,IR) + IREFH(3,IR)
          HPKm = 2*(HPK/2)
          HPLm = 2*(HPL/2)
          LOGREF(1,IR) = (HPK.EQ.HPKm) .AND. (HPL.EQ.HPLm)
                                                         ! h+k=2n  ,h+l=2n
          LOGREF(2,IR) = (HPK.EQ.HPKm) .AND. (HPL.NE.HPLm)
                                                         ! h+k=2n  ,h+l=2n+1
          LOGREF(3,IR) = (HPK.NE.HPKm) .AND. (HPL.EQ.HPLm)
                                                         ! h+k=2n+1,h+l=2n
          LOGREF(4,IR) = (HPK.NE.HPKm) .AND. (HPL.NE.HPLm)
                                                         ! h+k=2n+1,h+l=2n+1
        ENDDO
      CASE (269)                             ! P b c m
        NLGREF = 4
        DO IR = 1, MAXK
          K_ = IREFH(2,IR)
          L_ = IREFH(3,IR)
          K_m = 2*(K_/2)
          L_m = 2*(L_/2)
          LOGREF(1,IR) = (K_.EQ.K_m) .AND. (L_.EQ.L_m)
                                                     ! k=2n  ,l=2n
          LOGREF(2,IR) = (K_.EQ.K_m) .AND. (L_.NE.L_m)
                                                     ! k=2n  ,l=2n+1
          LOGREF(3,IR) = (K_.NE.K_m) .AND. (L_.EQ.L_m)
                                                     ! k=2n+1,l=2n
          LOGREF(4,IR) = (K_.NE.K_m) .AND. (L_.NE.L_m)
                                                     ! k=2n+1,l=2n+1
        ENDDO
      CASE (292)                             ! P n m a
        NLGREF = 4
        DO IR = 1, MAXK
          HPL = IREFH(1,IR) + IREFH(3,IR)
          K_ = IREFH(2,IR)
          HPLm = 2*(HPL/2)
          K_m = 2*(K_/2)
          LOGREF(1,IR) = (HPL.EQ.HPLm) .AND. (K_.EQ.K_m)
                                                       !h+l=2n,  k=2n
          LOGREF(2,IR) = (HPL.EQ.HPLm) .AND. (K_.NE.K_m)
                                                       !h+l=2n,  k=2n+1
          LOGREF(3,IR) = (HPL.NE.HPLm) .AND. (K_.EQ.K_m)
                                                       !h+l=2n+1,k=2n
          LOGREF(4,IR) = (HPL.NE.HPLm) .AND. (K_.NE.K_m)
                                                       !h+l=2n+1,k=2n+1
        ENDDO
      CASE (365)                             ! I 41/a (origin choice 2)
        NLGREF = 8
        DO IR = 1, MAXK
          H_ = IREFH(1,IR)
          K_ = IREFH(2,IR)
          H_m = 2*(H_/2)
          K_m = 2*(K_/2)
          HPKPL = IREFH(1,IR) + IREFH(2,IR) + IREFH(3,IR)
          IREMAIN = MOD(HPKPL,4)
          LOGREF(1,IR) = (H_.EQ.H_m) .AND. (K_.EQ.K_m) .AND.            &
     &                   (IREMAIN.EQ.0)
          LOGREF(2,IR) = (H_.EQ.H_m) .AND. (K_.NE.K_m) .AND.            &
     &                   (IREMAIN.EQ.0)
          LOGREF(3,IR) = (H_.NE.H_m) .AND. (K_.EQ.K_m) .AND.            &
     &                   (IREMAIN.EQ.0)
          LOGREF(4,IR) = (H_.NE.H_m) .AND. (K_.NE.K_m) .AND.            &
     &                   (IREMAIN.EQ.0)
          LOGREF(5,IR) = (H_.EQ.H_m) .AND. (K_.EQ.K_m) .AND.            &
     &                   (IREMAIN.EQ.2)
          LOGREF(6,IR) = (H_.EQ.H_m) .AND. (K_.NE.K_m) .AND.            &
     &                   (IREMAIN.EQ.2)
          LOGREF(7,IR) = (H_.NE.H_m) .AND. (K_.EQ.K_m) .AND.            &
     &                   (IREMAIN.EQ.2)
          LOGREF(8,IR) = (H_.NE.H_m) .AND. (K_.NE.K_m) .AND.            &
     &                   (IREMAIN.EQ.2)
          IF (H_.EQ.2 .AND. K_.EQ.2 .AND. IREMAIN.EQ.2) THEN
          ENDIF
        ENDDO
      CASE (369)                             ! P 41 21 2
        NLGREF = 4
        DO IR = 1, MAXK
          H_ = IREFH(1,IR)
          K_ = IREFH(2,IR)
          L_ = IREFH(3,IR)
          IREMAIN = MOD(2*H_+2*K_+L_,4)
          LOGREF(1,IR) = (IREMAIN.EQ.0) !2h+2k+l=4n
          LOGREF(2,IR) = (IREMAIN.EQ.1) !2h+2k+l=4n+1
          LOGREF(3,IR) = (IREMAIN.EQ.2) !2h+2k+l=4n+2
          LOGREF(4,IR) = (IREMAIN.EQ.3) !2h+2k+l=4n+3
        ENDDO
      CASE (431,432)                         ! P31, P32
        NLGREF = 3
        DO IR = 1, MAXK
          LL = MOD(IREFH(3,IR)+300,3)
          LLM = 3*(LL/3)
          LOGREF(1,IR) = (LL.EQ.0)
          LOGREF(2,IR) = (LL.EQ.1)
          LOGREF(3,IR) = (LL.EQ.2)
        ENDDO
      CASE DEFAULT
      END SELECT
!
      SELECT CASE (NumberSGTable)    ! adjustments for presence of 'i' index
      CASE (430,431,432,433,434,435,449,451,462,468)
        JHMIN = MIN(IIMIN,IHMIN,IKMIN)
        JHMAX = MAX(IIMAX,IHMAX,IKMAX)
        IF (ABS(jhmin).GT.ABS(jhmax)) THEN
          jhmax = ABS(jhmin)
        ENDIF
        IHMIN = JHMIN
        IKMIN = JHMIN
        IHMAX = JHMAX
        IKMAX = JHMAX
        IHMINLT0 = IHMIN.LT.0
        IKMINLT0 = IKMIN.LT.0
      CASE (469,471,481,483,485)
        JHMIN = MIN(IIMIN,IHMIN,IKMIN)
        JHMAX = MAX(IIMAX,IHMAX,IKMAX)
        IF (ABS(jhmin).GT.ABS(jhmax)) THEN
          jhmax = ABS(jhmin)
        ENDIF
        IHMIN = JHMIN
        IKMIN = JHMIN
        IHMAX = JHMAX
        IKMAX = JHMAX
        IHMINLT0 = IHMIN.LT.0
        IKMINLT0 = IKMIN.LT.0
      CASE DEFAULT
      END SELECT
!
      SELECT CASE (NumberSGTable)    ! adjustments for presence of kx and hy terms
      CASE (356,365,369)
        jhmin = MIN(ihmin,ikmin)
        jhmax = MAX(ihmax,ikmax)
        ihmin = jhmin
        ikmin = jhmin
        ihmax = jhmax
        ikmax = jhmax
        IHMINLT0 = IHMIN.LT.0
        IKMINLT0 = IKMIN.LT.0
      END SELECT
!
!
      GOTO 999
  998 ier = 1
  999 CLOSE (31)
      RETURN
!
      END SUBROUTINE GET_LOGREF