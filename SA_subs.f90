!
!*****************************************************************************
!
      SUBROUTINE SimulatedAnnealing

      USE WINTERACTER
      USE DRUID_HEADER
      USE VARIABLES
      USE ATMVAR
      USE PO_VAR
      USE ZMVAR
      USE SOLVAR

      IMPLICIT NONE

      INCLUDE 'PARAMS.INC'
      INCLUDE 'Lattice.inc'

      DOUBLE PRECISION XOPT,       C,       FOPT
      COMMON /sacmn /  XOPT(MVAR), C(MVAR), FOPT

      DOUBLE PRECISION XP(MVAR)

      INTEGER          NBIN, LBIN
      REAL                         XBIN,       YOBIN,       YCBIN,       YBBIN,       EBIN
      COMMON /PROFBIN/ NBIN, LBIN, XBIN(MOBS), YOBIN(MOBS), YCBIN(MOBS), YBBIN(MOBS), EBIN(MOBS)

      DOUBLE PRECISION x,       lb,       ub,       vm
      COMMON /values/  x(MVAR), lb(MVAR), ub(MVAR), vm(MVAR)

      DOUBLE PRECISION T0, rt
      COMMON /saparl/  T0, rt

      INTEGER NACP(MVAR)

      INTEGER         nvar, ns, nt, iseed1, iseed2
      COMMON /sapars/ nvar, ns, nt, iseed1, iseed2

      DOUBLE PRECISION RFIX
      DOUBLE PRECISION RULB(mvar)
      DOUBLE PRECISION RANARR(30000), RANAR1(30000)
      DOUBLE PRECISION DXVAV(mvar), XVSIG(mvar), FLAV(mvar)
      DOUBLE PRECISION X0SUM(mvar), XSUM(mvar), XXSUM(mvar)
      DOUBLE PRECISION XDSS(mvar), A0SUM(mvar)

!  Type all functions.
      DOUBLE PRECISION, EXTERNAL :: EXPREP

      DOUBLE PRECISION DP0

      INTEGER         NPAR, IP
      COMMON /SIMSTO/ NPAR, IP(MVAR)

      INTEGER         NATOM
      REAL                   XATO
      INTEGER                          KX
      REAL                                        AMULT,      TF
      INTEGER         KTF
      REAL                      SITE
      INTEGER                              KSITE,      ISGEN
      REAL            SDX,        SDTF,      SDSITE
      INTEGER                                             KOM17
      COMMON /POSNS / NATOM, XATO(3,150), KX(3,150), AMULT(150), TF(150),  &
     &                KTF(150), SITE(150), KSITE(150), ISGEN(3,150),    &
     &                SDX(3,150), SDTF(150), SDSITE(150), KOM17

      REAL             CHIPROBEST
      COMMON /PLTSTO2/ CHIPROBEST

      INTEGER         iteration
      COMMON /ITRINF/ iteration

      CHARACTER(MaxPathLength) OutputFilesBaseName
      INTEGER                                       OFBN_Len
      CHARACTER(3)                                            SA_RunNumberStr
      COMMON /basnam/          OutputFilesBaseName, OFBN_Len, SA_RunNumberStr

      LOGICAL         RESTART
      INTEGER                  Curr_SA_Run, NumOf_SA_Runs, MaxRuns, MaxMoves
      REAL                                                                    ChiMult
      COMMON /MULRUN/ RESTART, Curr_SA_Run, NumOf_SA_Runs, MaxRuns, MaxMoves, ChiMult

      INTEGER           TotNumOfAtoms, NumOfHydrogens, NumOfNonHydrogens, OrderedAtm
      COMMON  /ORDRATM/ TotNumOfAtoms, NumOfHydrogens, NumOfNonHydrogens, OrderedAtm(1:MaxAtm_3)

      REAL            bchmin, bpwval, bchpro, avchi1, avchi2, avchi3, avchi4
      INTEGER         nd1, nmpert, nd3, nd4, bmIHANDLE
      COMMON /sagdat/ bchmin, bpwval, bchpro, avchi1, avchi2, avchi3, avchi4, &
                      nd1, nmpert, nd3, nd4, bmIHANDLE

      INTEGER              iMyExit, num_new_min
      COMMON / CMN000001 / iMyExit, num_new_min

!  Type all internal variables.
      INTEGER NACC
      LOGICAL MAXLOG, MAKET0
      DOUBLE PRECISION FPSUM0, FPSUM1, FPSUM2, FPAV, FPSD
      DOUBLE PRECISION F, FP, P, PP, RATIO, DX
      DOUBLE PRECISION RANIN
      INTEGER NUP, NDOWN, NREJ, H, I, J, M, II, IV
      INTEGER MRAN, MRAN1, IARR, IAR1
      DOUBLE PRECISION T
      LOGICAL, EXTERNAL :: CheckTerm
      INTEGER NumTrialsPar(MVAR)

      INTEGER IM, IA, IC
      LOGICAL, EXTERNAL :: Get_AutoLocalMinimisation, IsEventWaiting, Get_AutoAlign
      INTEGER JRAN, num_old_min, NTOTMOV
      INTEGER III, IH, KK, iFrg, iFrgCopy
      INTEGER Last_NUP, Last_NDOWN
      CHARACTER*3 CNruns,CMruns
      LOGICAL PrevRejected, CurrIsPO, PrevWasPO
      DOUBLE PRECISION tX147

      CALL OpenChiSqPlotWindow
      Curr_SA_Run = 0
      NumOf_SA_Runs = 0
! Set up a random number generator store
! Use a quick and dirty one from NR
      CALL RANX2Init
      IM = 29282
      IA = 1255
      IC = 6173
      JRAN = 1
      DO I = 1, 30000
        JRAN = MOD(JRAN*IA+IC,IM)
        RANARR(I) = FLOAT(JRAN)/FLOAT(IM) ! RANARR now between  0.0 and 1.0
        RANIN = 2.0 * RANARR(I) - 1.0     ! RANIN  now between -0.1 and 1.0
        CALL RANX2E(RANIN,RANAR1(I))
      ENDDO
      IM = 7875
      IA = 211
      IC = 1663
! vm is adjusted during the SA. So re-initialise every time the SA is started to
! ensure that starting the SA more than once with the same parameters will give
! identical results.
      kk = 0
      DO iFrg = 1, maxfrg
        IF (gotzmfile(iFrg)) THEN
          DO iFrgCopy = 1, zmNumberOfCopies(iFrg)
            DO ii = 1, izmpar(iFrg)
              kk = kk + 1
              SELECT CASE (kzmpar(ii,iFrg))
                CASE (1) ! translation
                  vm(kk) = 0.1
                CASE (2) ! quaternion
                  vm(kk) = 0.1
                CASE (3) ! torsion
                  vm(kk) = 10.0
                CASE (4) ! angle
                  vm(kk) = 1.0
                CASE (5) ! bond
                  vm(kk) = 0.1*(ub(kk)-lb(kk))
                CASE (6) ! single rotation axis
                  vm(kk) = 0.1
              END SELECT
            ENDDO
          ENDDO
        ENDIF
      ENDDO
      IF (PrefParExists) THEN
        kk = kk + 1
        vm(kk) = 0.01
      ENDIF
      DP0 = 0.0
! ####################################
!   Starting point for multiple runs
! ####################################
    1 CONTINUE ! The start point for multiple runs.
! Set initial values.
      imyexit = 0
      Curr_SA_Run = Curr_SA_Run + 1
      WRITE (SA_RunNumberStr,'(I3.3)') Curr_SA_Run
      CALL PushActiveWindowID
      CALL WDialogSelect(IDD_SA_Action1)
      WRITE(CNruns,'(I3)') Curr_SA_Run
      IF (Curr_SA_Run .EQ. 2) CALL WDialogFieldState(IDB_Summary,Enabled)
      WRITE(CMruns,'(I3)') MaxRuns
      CNruns = ADJUSTL(CNruns)
      CMruns = ADJUSTL(CMruns)
      CALL WDialogPutString(IDD_SA_RunLabel,'Simulated annealing run number '//CNRuns(1:LEN_TRIM(CNruns))// &
                                            ' of '//CMRuns(1:LEN_TRIM(CMRuns)))
      CALL PopActiveWindowID
      num_new_min = 0
      num_old_min = -1
      MAKET0 = (T0.LE.0.0)  ! T0 is estimated each run of a multirun
      IF (MAKET0) THEN
        T = 100000.0
      ELSE
        T = T0
      ENDIF
! Initialise the random number generator RANMAR.
! Increment the seeds for each SA run
      CALL RMARInit(ISEED1+Curr_SA_Run,ISEED2+Curr_SA_Run)
! Initialise all degrees of freedom either to a preset value or to
! a random value
      CALL MAKXIN(nvar)
      DO IV = 1, nvar
        C(IV) = 2.0
      ENDDO
      ITERATION = 1
      NACC = 0
      NTOTMOV = 0
      NPAR = 0
      RFIX = 1E-3
      DO I = 1, nvar
        XOPT(I) = X(I)
        NACP(I) = 0
        NumTrialsPar(I) = 0
        RULB(I) = UB(I) - LB(I)
        IF (RULB(I).GT.RFIX) THEN
! NPAR is the number of parameters that are allowed to vary (i.e., not fixed)
! so in a way, NPAR is the number of parameters that are parameters.
          NPAR = NPAR + 1
          IP(NPAR) = I
        ENDIF
      ENDDO
      nmpert = nt * ns * NPAR ! Number of Moves per Temperature
! Evaluate the function with input X and return value as F.
      IF (PrefParExists) CALL PO_PRECFC
      CALL FCN(X,F,0)
      DO II = 1, NATOM
        DO III = 1, 3
          XAtmCoords(III,II,Curr_SA_Run) = XATO(III,II)
        ENDDO
      ENDDO
! Evaluate the profile chi-squared as well
      CALL valchipro(CHIPROBEST)
      PrevRejected = .TRUE.
! plot the profile
      CALL Profile_Plot
!  If the function is to be minimised, switch the sign of the function.
!  Note that all intermediate and final output switches the sign back
!  to eliminate any possible confusion for the user.
! JvdS According to the compiler, this part was never initialised.
! As it usually works, I assume MAXLOG is usually 0 probably meaning .FALSE.
      MAXLOG = .FALSE.
      IF (.NOT. MAXLOG) F = -F
      FOPT = F
      MRAN  = ISEED1 + Curr_SA_Run
      MRAN1 = ISEED2 + Curr_SA_Run
! ##########################################
!   Starting point for multiple iterations
! ##########################################
      Last_NUP   = nmpert / 2
      Last_NDOWN = nmpert / 2
  100 CONTINUE
      NUP = 0
      NREJ = 0
      NDOWN = 0
      DO II = 1, nvar
        X0SUM(II) = 0.0
        A0SUM(II) = 0.0
        XSUM(II) = 0.0
        XXSUM(II) = 0.0
        XDSS(II) = 0.0
      ENDDO
      FPSUM0 = 0.0
      FPSUM1 = 0.0
      FPSUM2 = 0.0
! Update the SA status window
      CALL SA_OUTPUT(SNGL(T),-SNGL(fopt),-SNGL(FPAV), SNGL(FPSD),xopt,dxvav,xvsig,flav,lb,ub,  &
                     vm,nvar,Last_NUP,Last_NDOWN,NREJ,ntotmov,iteration)
      CALL sa_move_status(nmpert,0)
! ##########################################
!   Starting point for multiple moves
! ##########################################
      DO M = 1, NT
! MRAN RANGE IS 0 -> IM=7875
        MRAN = MOD(MRAN*IA+IC,IM)
        IARR = MRAN + 1
        MRAN1 = MOD(MRAN1*IA+IC,IM)
        IAR1 = MRAN1 + 1
        DO J = 1, NS
          DO IH = 1, NPAR
            H = IP(1+INT(RANARR(IARR)*NPAR))
            IARR = IARR + 1
            NumTrialsPar(H) = NumTrialsPar(H) + 1
! Generate XP, the trial value of X. Note use of VM to choose XP.
            DO I = 1, nvar
              XP(I) = X(I)
            ENDDO
            DX = RANAR1(IAR1) * VM(H)
            IAR1 = IAR1 + 1
            XP(H) = X(H) + DX
!O! If translation, adjust to be between 0.0 and 1.0
!O            IF (kzmpar2(H) .EQ. 1) THEN
!O              DO WHILE (XP(H) .LT. 0.0)
!O                XP(H) = XP(H) + 1.0
!O              ENDDO
!O              DO WHILE (XP(H) .GT. 1.0)
!O                XP(H) = XP(H) - 1.0
!O              ENDDO
!O            ENDIF
!O! If torsion angle, adjust to be between -180.0 and +180.0
!O            IF (kzmpar2(H) .EQ. 3) THEN
!O              DO WHILE (XP(H) .LT. -180.0)
!O                XP(H) = XP(H) + 360.0
!O              ENDDO
!O              DO WHILE (XP(H) .GT.  180.0)
!O                XP(H) = XP(H) - 360.0
!O              ENDDO
!O            ENDIF
! If XP is out of bounds, select a point in bounds for the trial.
            IF ((XP(H).LT.LB(H)) .OR. (XP(H).GT.UB(H))) THEN
              XP(H) = LB(H) + RULB(H) * RANARR(IARR)
              IARR = IARR + 1
            ENDIF
            CurrIsPO = (kzmpar2(H) .EQ. 7)
            IF (PrefParExists) THEN
! Evaluate the function with the trial point XP and return as FP.
              tX147 = X(iPrfPar)
              X(iPrfPar) = XP(iPrfPar) 
              IF (PrevRejected) THEN
                IF (PrevWasPO) THEN
                  IF (CurrIsPO) THEN
                    CALL FCN(XP,FP,iPrfPar)
                  ELSE
                    CALL PO_PRECFC
                    CALL FCN(XP,FP,0)
                  ENDIF
                ELSE
                  IF (CurrIsPO) THEN
                    CALL PO_PRECFC
                    CALL FCN(XP,FP,0)
                  ELSE
                    CALL FCN(XP,FP,0)
                  ENDIF
                ENDIF
              ELSE
                CALL FCN(XP,FP,H)
              ENDIF
              X(iPrfPar) = tX147
            ELSE
              CALL FCN(XP,FP,0)
            ENDIF
            PrevWasPO = CurrIsPO

            FP = -FP
            FPSUM0 = FPSUM0 + 1.0
            FPSUM1 = FPSUM1 + FP
            FPSUM2 = FPSUM2 + FP*FP
            A0SUM(H) = A0SUM(H) + 1.0
            XDSS(H) = XDSS(H) + (FP-F)**2
            PrevRejected = .FALSE.
! Accept the new point if the function value increases.
            IF (FP.GE.F) THEN
              X(H) = XP(H)
              F = FP
              NACC = NACC + 1
              NACP(H) = NACP(H) + 1
              X0SUM(H) = X0SUM(H) + 1.0
              XSUM(H) = XSUM(H) + X(H)
              XXSUM(H) = XXSUM(H) + X(H)**2
              NUP = NUP + 1
! If greater than any other point, record as new optimum.
              IF (FP.GT.FOPT) THEN
                DO I = 1, nvar
                  XOPT(I) = XP(I)
                ENDDO
                DO II = 1, NATOM
                  DO III = 1, 3
                    XAtmCoords(III,II,Curr_SA_Run) = XATO(III,II)
                  ENDDO
                ENDDO
                num_new_min = num_new_min + 1
                CALL valchipro(CHIPROBEST)
                FOPT = FP
! Update the SA status window
                CALL SA_OUTPUT(SNGL(T),-SNGL(FOPT),-SNGL(FPAV),SNGL(FPSD),XOPT,dxvav,xvsig,flav,lb,ub,  &
                               vm,NVAR,Last_NUP,Last_NDOWN,NREJ,ntotmov,iteration)
              ENDIF
! If the point is lower, use the Metropolis criterion to decide on
! acceptance or rejection.
            ELSE
              P = EXPREP((FP-F)/T)
              PP = RANARR(IARR)
              IARR = IARR + 1
              IF (PP.LT.P) THEN
                X(H) = XP(H)
                F = FP
                NACC = NACC + 1
                NACP(H) = NACP(H) + 1
                X0SUM(H) = X0SUM(H) + 1.0
                XSUM(H) = XSUM(H) + X(H)
                XXSUM(H) = XXSUM(H) + X(H)**2
                NDOWN = NDOWN + 1
              ELSE
                NREJ = NREJ + 1
                PrevRejected = .TRUE.
!O                X0SUM(H) = X0SUM(H) + 1.0
!O                XSUM(H) = XSUM(H) + X(H)
!O                XXSUM(H) = XXSUM(H) + X(H)**2
              ENDIF
            ENDIF
          ENDDO ! Loop over parameters
          CALL sa_move_status(nmpert,m*NPAR*ns)
        ENDDO ! Loop over NS
! Adjust VM so that approximately half of all evaluations are accepted.
        DO II = 1, NPAR
          I = IP(II)
          RATIO = DFLOAT(NACP(I))/DFLOAT(NumTrialsPar(I))
          IF (RATIO.GT.0.6) THEN
            VM(I) = VM(I)*(1.0+C(I)*(RATIO-0.6)/0.4)
          ELSEIF (RATIO.LT.0.4) THEN
            VM(I) = VM(I)/(1.0+C(I)*((0.4-RATIO)/0.4))
          ENDIF
          IF (VM(I).GT.RULB(I)) THEN
            VM(I) = RULB(I)
          ENDIF
          IF (VM(I).LT.0.01*RULB(I)) THEN
            VM(I) = 0.01*RULB(I)
          ENDIF
          NACP(I) = 0
          NumTrialsPar(I) = 0
        ENDDO
        CALL PeekEvent
        IF (iMyExit .NE. 0) GOTO 999 ! Exit all loops and jump straight to the end
      ENDDO ! Loop over moves per iteration (NT)
      Last_NDOWN = NDOWN
      Last_NUP   = NUP
! Calculate the average energy and deviation
      FPAV = FPSUM1/FPSUM0
      FPSD = SQRT(MAX(DP0,(FPSUM2/FPSUM0)-(FPAV**2)))
      DO I = 1, nvar
        IF (X0SUM(I).GT.0.) THEN
          DXVAV(I) = XSUM(I)/X0SUM(I)
          XVSIG(I) = SQRT(MAX(DP0,(XXSUM(I)/X0SUM(I))-(DXVAV(I)*DXVAV(I))))
          FLAV(I) = SQRT(MAX(DP0,XDSS(I)/A0SUM(I)))
        ENDIF
      ENDDO
      ntotmov = ntotmov + nmpert
! ep  Plots Chi sqd vs. num of moves plot
      CALL PrepareChiSqPlotData(iteration)
      iteration = iteration + 1
      IF (num_new_min .NE. num_old_min) CALL Profile_Plot ! plot the profile
      num_old_min = num_new_min
      CALL SA_OUTPUT(SNGL(T),-SNGL(fopt),-SNGL(FPAV),SNGL(FPSD),xopt, &
                     dxvav,xvsig,flav,lb,ub,vm,nvar,Last_NUP,Last_NDOWN,NREJ, &
                     ntotmov,iteration)
! If we have asked for an initial temperature to be calculated then do so
      IF (MAKET0) THEN
! Start temperature increased by 50% as asked for
        T = FPSD*1.5
        MAKET0 = .FALSE.
        GOTO 100
      ENDIF
! If termination criteria are not met, prepare for another loop.
! We will use the energy fluctuation to reduce the temperature
      T = T/(1.0+(RT*T)/(3.0*FPSD))
      F = FOPT
      DO I = 1, nvar
        X(I) = XOPT(I)
      ENDDO
  999 CONTINUE ! This is where we jump to if the user pressed 'Stop' during the SA
               ! The variable imyexit has been set to 3, 4 or 5  (3 = stop SA, 4 = start next run, 5 = Edit)
               ! If we didn't jump to this point, just passed it, imyexit is 0
!  Check termination criteria.
!  Terminate SA if appropriate.
      IF (RESTART) THEN
        IF (CheckTerm(NTOTMOV,CHIPROBEST) .OR. (iMyExit .NE. 0)) THEN
! End of a run in a multi-run. This is the place for a final local minimisation
! Get AutoLocalMinimisation from the Configuration Window
          NumOf_SA_Runs = Curr_SA_Run
          IF (Get_AutoLocalMinimisation()) THEN
            CALL LocalMinimise(.TRUE.)
! ep  Plots Chi sqd vs. num of moves plot
            CALL PrepareChiSqPlotData(MAX(1,iteration-1))
          ENDIF
! ep  Saves calculated and observed diffraction patterns in .pro file 
          CALL Sa_soln_store
! Align structure.  Will get to this point whether autominimise enabled or not.
          IF (Get_AutoAlign()) CALL Align
! Store optimum crystal structure        
          CALL Log_SARun_Entry
          CALL SA_STRUCTURE_OUTPUT(T,XOPT,ntotmov)
          IF ((Curr_SA_Run.LT.MaxRuns) .AND. (iMyExit .NE. 3) .AND. (iMyExit .NE. 5)) THEN
            GOTO 1 ! Next run
          ENDIF
        ELSE
          GOTO 100 ! Next iteration
        ENDIF
      ELSEIF ((iteration.LT.MaxIter) .AND. (T.GT.0.0) .AND. (iMyExit .EQ. 0)) THEN
        GOTO 100 ! Next iteration
      ELSE
        NumOf_SA_Runs = Curr_SA_Run ! = 1
        IF (Get_AutoLocalMinimisation()) THEN
          CALL LocalMinimise(.TRUE.)
! ep  Plots Chi sqd vs. num of moves plot
          CALL PrepareChiSqPlotData(MAX(1,iteration-1))
        ENDIF
! ep  Saves calculated and observed diffraction patterns in .pro file 
        CALL Sa_soln_store
! Align structure.  Will get to this point whether autominimise enabled or not.
        IF (Get_AutoAlign()) CALL Align
        CALL Log_SARun_Entry
        CALL SA_STRUCTURE_OUTPUT(T,XOPT,ntotmov)
      ENDIF

      END SUBROUTINE SimulatedAnnealing
!
!*****************************************************************************
!
      FUNCTION EXPREP(RDUM)
!  This function replaces exp to avoid under- and overflows and is
!  designed for IBM 370 type machines. It may be necessary to modify
!  it for other machines. Note that the maximum and minimum values of
!  EXPREP are such that they have no effect on the algorithm.
!
      DOUBLE PRECISION RDUM, EXPREP

      IF (RDUM.GT.174.) THEN
        EXPREP = 3.69D+75
      ELSEIF (RDUM.LT.-180.) THEN
        EXPREP = 0.0
      ELSE
        EXPREP = EXP(RDUM)
      ENDIF

      END FUNCTION EXPREP
!
!*****************************************************************************
!
      SUBROUTINE RMARInit(IJ,KL)
!  This subroutine and the next function generate random numbers. See
!  the comments for SA for more information. The only changes from the
!  orginal code is that (1) the test to make sure that RMARIN runs first
!  was taken out since SA assures that this is done (this test didn't
!  compile under IBM's VS Fortran) and (2) typing ivec as integer was
!  taken out since ivec isn't used. With these exceptions, all following
!  lines are original.
!
! This is the initialization routine for the random number generator
!     RANMAR()
! NOTE: The seed variables can have values between:    0 <= IJ <= 31328
!                                                      0 <= KL <= 30081
      IMPLICIT NONE
      
      INTEGER, INTENT (INOUT) :: IJ, KL
      
      REAL            U,     C, CD, CM
      INTEGER                           I97, J97
      COMMON /raset1/ U(97), C, CD, CM, I97, J97

      INTEGER ii, jj, i, j, k, l, m
      REAL    s, t

      IF ((IJ.LT.0) .OR. (IJ.GT.31328) .OR. (KL.LT.0) .OR. (KL.GT.30081)) THEN
        CALL InfoMessage('Seeds for random number generator must be '// &
            'between 0 and 30081 and have been reset to 1375 and 29767.')
        IJ = 1375
        KL = 29767
      ENDIF
      i = MOD(IJ/177,177) + 2
      j = MOD(IJ,177) + 2
      k = MOD(KL/169,178) + 1
      l = MOD(KL,169)
      DO ii = 1, 97
        s = 0.0
        t = 0.5
        DO jj = 1, 24
          m = MOD(MOD(i*j,179)*k,179)
          i = j
          j = k
          k = m
          l = MOD(53*l+1,169)
          IF (MOD(l*m,64).GE.32) THEN
            s = s + t
          ENDIF
          t = 0.5*t
        ENDDO
        U(ii) = s
      ENDDO
      C = 362436.0/16777216.0
      CD = 7654321.0/16777216.0
      CM = 16777213.0/16777216.0
      I97 = 97
      J97 = 33

      END SUBROUTINE RMARInit
!
!*****************************************************************************
!
      FUNCTION RANMAR

      REAL            U,     C, CD, CM
      INTEGER                           I97, J97
      COMMON /raset1/ U(97), C, CD, CM, I97, J97

      uni = U(I97) - U(J97)
      IF (uni.LT.0.0) uni = uni + 1.0
      U(I97) = uni
      I97 = I97 - 1
      IF (I97.EQ.0) I97 = 97
      J97 = J97 - 1
      IF (J97.EQ.0) J97 = 97
      C = C - CD
      IF (C.LT.0.0) C = C + CM
      uni = uni - C
      IF (uni.LT.0.0) uni = uni + 1.0
      RANMAR = uni

      END FUNCTION RANMAR
!
!*****************************************************************************
!
      SUBROUTINE RANX2E(DRIN,DROUT)

      DOUBLE PRECISION drin, drout
      COMMON /x2eran/ xs, yran(200)

      rin = SNGL(drin)
      rin = ABS(rin)
      jn = 1
      DO j = 199, 1, -1
        IF (rin.GT.yran(j)) THEN
          jn = j
          GOTO 10
        ENDIF
      ENDDO
!.. rin is between yran(jn) and yran(jn+1) now iterate
   10 xl = xs*FLOAT(jn-1)
      xsn = 0.5*xs
      xm = xl + xsn
      xh = xm + xsn
      yl = yran(jn)
      yh = yran(jn+1)
      ym = 1. - (0.5*xm*xm+xm+1.)*EXP(-xm)
   15 xlo = xl
      xmo = xm
      xho = xh
      ylo = yl
      ymo = ym
      yho = yh
      IF (ABS(yh-yl).LT.1E-3) GOTO 20
      IF (rin.GE.ym) THEN
        xl = xmo
        xh = xho
        yl = ymo
        yh = yho
      ELSE
        xl = xlo
        xh = xmo
        yl = ylo
        yh = ymo
      ENDIF
      xm = 0.5*(xh+xl)
      ym = 1. - (0.5*xm*xm+xm+1.)*EXP(-xm)
      GOTO 15
   20 rout = xm
      IF (drin.LT.0.0) rout = -rout
      drout = DBLE(rout)

      END SUBROUTINE RANX2E
!
!*****************************************************************************
!
      SUBROUTINE RANX2Init

      COMMON /x2eran/ xs, yran(200)

      xs = 0.1
      DO i = 1, 200
        xi = xs*FLOAT(i-1)
        yran(i) = 1. - (0.5*xi*xi+xi+1.)*EXP(-xi)
      ENDDO

      END SUBROUTINE RANX2Init
!
!*****************************************************************************
!
      SUBROUTINE MAKXIN(N)

      INCLUDE 'PARAMS.INC'

      DOUBLE PRECISION x, lb, ub, vm, xpreset
      COMMON /values/ x(mvar), lb(mvar), ub(mvar), vm(mvar)
      COMMON /presetr/ xpreset(mvar)
      LOGICAL log_preset
      COMMON /presetl/ log_preset

      IF (LOG_PRESET) THEN
        DO IV = 1, N
          X(IV) = XPRESET(IV)
        ENDDO
      ELSE
        DO IV = 1, N
          X(IV) = LB(IV) + (UB(IV)-LB(IV))*RANMAR()
        ENDDO
      ENDIF

      END SUBROUTINE MAKXIN
!
!*****************************************************************************
!
      LOGICAL FUNCTION CheckTerm(Nmoves,BestProChiSq)

      IMPLICIT NONE

      INTEGER, INTENT (IN   ) :: Nmoves
      REAL,    INTENT (IN   ) :: BestProChiSq

      LOGICAL         RESTART
      INTEGER                  Curr_SA_Run, NumOf_SA_Runs, MaxRuns, MaxMoves
      REAL                                                                    ChiMult
      COMMON /MULRUN/ RESTART, Curr_SA_Run, NumOf_SA_Runs, MaxRuns, MaxMoves, ChiMult

      REAL             PAWLEYCHISQ, RWPOBS, RWPEXP
      COMMON /PRCHISQ/ PAWLEYCHISQ, RWPOBS, RWPEXP

      CheckTerm = ((Nmoves.GT.MaxMoves) .OR. (BestProChiSq.LT.(ChiMult*PAWLEYCHISQ)))

      END FUNCTION CheckTerm
!
!*****************************************************************************
!