!
!*****************************************************************************
!
      SUBROUTINE Upload_Widths()

      USE WINTERACTER
      USE DRUID_HEADER 

      IMPLICIT NONE

      INCLUDE 'PARAMS.INC'

      REAL              XPF_Range
      LOGICAL                                       RangeFitYN
      INTEGER           IPF_Lo,                     IPF_Hi
      INTEGER           NumPeakFitRange,            CurrentRange
      INTEGER           IPF_Range
      INTEGER           NumInPFR
      REAL              XPF_Pos,                    YPF_Pos
      INTEGER           IPF_RPt
      REAL              XPeakFit,                   YPeakFit
      COMMON /PEAKFIT1/ XPF_Range(2,MAX_NPFR),      RangeFitYN(MAX_NPFR),        &
                        IPF_Lo(MAX_NPFR),           IPF_Hi(MAX_NPFR),            &
                        NumPeakFitRange,            CurrentRange,                &
                        IPF_Range(MAX_NPFR),                                     &
                        NumInPFR(MAX_NPFR),                                      & 
                        XPF_Pos(MAX_NPPR,MAX_NPFR), YPF_Pos(MAX_NPPR,MAX_NPFR),  &
                        IPF_RPt(MAX_NPFR),                                       &
                        XPeakFit(MAX_FITPT),        YPeakFit(MAX_FITPT)

      REAL              PkFnVal,                      PkFnEsd,                      &
                        PkFnCal,                                                    &
                        PkFnVarVal,                   PkFnVarEsd,                   &
                        PkAreaVal,                    PkAreaEsd,                    &
                        PkPosVal,                     PkPosEsd,                     &
                        PkPosAv
      COMMON /PEAKFIT2/ PkFnVal(MPkDes,Max_NPFR),     PkFnEsd(MPkDes,Max_NPFR),     &
                        PkFnCal(MPkDes,Max_NPFR),                                   &
                        PkFnVarVal(3,MPkDes),         PkFnVarEsd(3,MPkDes),         &
                        PkAreaVal(MAX_NPPR,MAX_NPFR), PkAreaEsd(MAX_NPPR,MAX_NPFR), &
                        PkPosVal(MAX_NPPR,MAX_NPFR),  PkPosEsd(MAX_NPPR,MAX_NPFR),  &
                        PkPosAv(MAX_NPFR)

      REAL    FitPar(MPkDes), FitEsd(MPkDes)
      INTEGER IOrdTem(MAX_NPFR)
      INTEGER IOrd, IPtPS
      REAL    ptem3, ptem4

! This is for testing for mathematical errors
      INTEGER IBMBER
      COMMON / CCSLER / IBMBER 

      INTEGER NTPeak, I, J, NumFittedPFR

      IBMBER = 0
      NTPeak = 0
      NumFittedPFR = 0 ! The number of Peak Fit Ranges that have actually been fitted
! Loop over all hatched areas. Per area, count all peaks that the user has indicated to be present.
      IF (NumPeakFitRange .GT. 0) THEN
        DO J = 1, NumPeakFitRange
          IF (RangeFitYN(J)) THEN
            NTPeak = NTPeak + NumInPFR(J)
            CALL INC(NumFittedPFR)
          ELSE
            PkPosAv(J) = 200.0 ! This way, they will end up after the fitted PFRs after the SORT.
          ENDIF
        ENDDO
      ENDIF
      IF (NumFittedPFR .EQ. 0) THEN
! Winteracter doesn't seem able to cope with setting the number of rows in a grid to zero,
! so instead I set it such that it fills the screen but doesn't allow scrolling down.
        CALL PushActiveWindowID
! Write out sigmas
        CALL WDialogSelect(IDD_Sigma_info)
        CALL WGridRows(IDF_Sigma_Grid,5)
        CALL WDialogClearField(IDF_Sigma_Grid)
        CALL WDialogClearField(IDF_Sigma1)
        CALL WDialogClearField(IDF_sigma2)
! Write out gammas
        CALL WDialogSelect(IDD_Gamma_info)
        CALL WGridRows(IDF_Gamma_Grid,5)
        CALL WDialogClearField(IDF_Gamma_Grid)
        CALL WDialogClearField(IDF_Gamma1)
        CALL WDialogClearField(IDF_Gamma2)
! Write out HPSL
        CALL WDialogSelect(IDD_HPSL_info)
        CALL WGridRows(IDF_HPSL_Grid,5)
        CALL WDialogClearField(IDF_HPSL_Grid)
        CALL WDialogClearField(IDF_HPSL1)
! Write out HMSL
        CALL WDialogSelect(IDD_HMSL_info)
        CALL WGridRows(IDF_HMSL_Grid,5)
        CALL WDialogClearField(IDF_HMSL_Grid)
        CALL WDialogClearField(IDF_HMSL1)
        CALL PopActiveWindowID
        RETURN
      ENDIF
! Sort all peak fit ranges. Those that haven't been fitted have been set to 200.0 and will appear after the others.
      CALL SORT_REAL(PkPosAv,IOrdTem,NumPeakFitRange)
      CALL PushActiveWindowID
! Write out sigmas
      CALL WDialogSelect(IDD_Sigma_info)
      CALL WGridRows(IDF_Sigma_Grid,NumFittedPFR)
      CALL WDialogClearField(IDF_Sigma_Grid)
! Only update those that have actually been fitted--we wouldn't have sensible values to show for the others anyway.
      DO I = 1, NumFittedPFR
        iord = IOrdTem(I)
        CALL WGridPutCellReal(IDF_Sigma_Grid,1,I,PkPosAv(iord),'(F12.3)')
        CALL WGridPutCellReal(IDF_Sigma_Grid,2,I,PkFnVal(1,iord),'(F12.5)')
        CALL WGridPutCellReal(IDF_Sigma_Grid,3,I,PkFnEsd(1,iord),'(F12.5)')
      ENDDO
      IF (NumFittedPFR .GE. 3) THEN
! Let's fit Sigma
        CALL Fit_Sigma(FitPar,FitEsd,2)
        IF (IBMBER .NE. 0) THEN
          IBMBER = 0
          CALL DebugErrorMessage('Fitting Sigma Failed.')
          CALL PopActiveWindowID
          RETURN
        ENDIF
        PkFnVarVal(1,1) = ABS(FitPar(1))
        PkFnVarVal(2,1) = ABS(FitPar(2))
        PkFnVarEsd(1,1) = FitEsd(1)
        PkFnVarEsd(2,1) = FitEsd(2)
        CALL WDialogPutReal(IDF_Sigma1,PkFnVarVal(1,1),'(F10.4)')
        CALL WDialogPutReal(IDF_Sigma2,PkFnVarVal(2,1),'(F10.4)')
        DO I = 1, NumFittedPFR
          iord = IOrdTem(I)
          CALL WGridPutCellReal(IDF_Sigma_Grid,4,I,PkFnCal(1,iord),'(F12.5)')
        ENDDO
      ENDIF
! Write out gammas
      CALL WDialogSelect(IDD_Gamma_info)
      CALL WGridRows(IDF_Gamma_Grid,NumFittedPFR)
      CALL WDialogClearField(IDF_Gamma_Grid)
      DO I = 1, NumFittedPFR
        iord = IOrdTem(I)
        CALL WGridPutCellReal(IDF_Gamma_Grid,1,I,PkPosAv(iord),'(F12.3)')
        CALL WGridPutCellReal(IDF_Gamma_Grid,2,I,PkFnVal(2,iord),'(F12.5)')
        CALL WGridPutCellReal(IDF_Gamma_Grid,3,I,PkFnEsd(2,iord),'(F12.5)')
      ENDDO
      IF (NumFittedPFR .GE. 3) THEN
! Let's fit Gamma
        CALL Fit_Gamma(FitPar,FitEsd,2)
        IF (IBMBER .NE. 0) THEN
          IBMBER = 0
          CALL DebugErrorMessage('Fitting Gamma Failed.')
          CALL PopActiveWindowID
          RETURN
        ENDIF
        PkFnVarVal(1,2) = FitPar(1)
        PkFnVarVal(2,2) = FitPar(2)
        PkFnVarEsd(1,2) = FitEsd(1)
        PkFnVarEsd(2,2) = FitEsd(2)
        CALL WDialogPutReal(IDF_Gamma1,PkFnVarVal(1,2),'(F10.4)')
        CALL WDialogPutReal(IDF_Gamma2,PkFnVarVal(2,2),'(F10.4)')
        DO I = 1, NumFittedPFR
          iord = IOrdTem(i)
          CALL WGridPutCellReal(IDF_Gamma_Grid,4,I,PkFnCal(2,iord),'(F12.5)')
        ENDDO
      ENDIF
! Write out HPSL
      CALL WDialogSelect(IDD_HPSL_info)
      CALL WGridRows(IDF_HPSL_Grid,NumFittedPFR)
      CALL WDialogClearField(IDF_HPSL_Grid)
      DO I = 1, NumFittedPFR
        iord = IOrdTem(I)
        CALL WGridPutCellReal(IDF_HPSL_Grid,1,I,PkPosAv(iord),'(F12.3)')
        CALL WGridPutCellReal(IDF_HPSL_Grid,2,I,PkFnVal(3,iord),'(F12.5)')
        CALL WGridPutCellReal(IDF_HPSL_Grid,3,I,PkFnEsd(3,iord),'(F12.5)')
      ENDDO
      IF (NumFittedPFR .GE. 2) THEN
! Let's fit HPSL
        IPtPS =3 
        CALL Fit_Constant(FitPar,FitEsd,1,IPtPS)
        IF (IBMBER .NE. 0) THEN
          IBMBER = 0
          CALL DebugErrorMessage('Fitting HPSL Failed.')
          CALL PopActiveWindowID
          RETURN
        ENDIF
        PkFnVarVal(1,3) = MAX(0.0002,FitPar(1))
        PkFnVarEsd(1,3) = FitEsd(1)
        CALL WDialogPutReal(IDF_HPSL1,PkFnVarVal(1,3),'(F10.4)')
        DO I = 1, NumFittedPFR
          iord = IOrdTem(I)
          CALL WGridPutCellReal(IDF_HPSL_Grid,4,i,PkFnCal(3,iord),'(F12.5)')
        ENDDO
      ENDIF
! Write out HMSL
      CALL WDialogSelect(IDD_HMSL_info)
      CALL WGridRows(IDF_HMSL_Grid,NumFittedPFR)
      CALL WDialogClearField(IDF_HMSL_Grid)
      DO I = 1, NumFittedPFR
        iord = IOrdTem(I)
        CALL WGridPutCellReal(IDF_HMSL_Grid,1,i,PkPosAv(iord),'(F12.3)')
        CALL WGridPutCellReal(IDF_HMSL_Grid,2,i,PkFnVal(4,iord),'(F12.5)')
        CALL WGridPutCellReal(IDF_HMSL_Grid,3,i,PkFnEsd(4,iord),'(F12.5)')
      ENDDO
! Let's fit HMSL
      IF (NumFittedPFR .GE. 2) THEN
        IPtPS = 4
        CALL Fit_Constant(FitPar,FitEsd,1,IPtPS)
        IF (IBMBER .NE. 0) THEN
          IBMBER = 0
          CALL DebugErrorMessage('Fitting HMSL Failed.')
          CALL PopActiveWindowID
          RETURN
        ENDIF
        PkFnVarVal(1,4) = MAX(0.0001,FitPar(1))
        PkFnVarEsd(1,4) = FitEsd(1)
        CALL WDialogPutReal(IDF_HMSL1,PkFnVarVal(1,4),'(F10.4)')
        DO I = 1, NumFittedPFR
          iord = IOrdTem(I)
          CALL WGridPutCellReal(IDF_HMSL_Grid,4,I,PkFnCal(4,iord),'(F12.5)')
        ENDDO
      ENDIF
! Warn if HPSL is less than HMSL
      IF (NumFittedPFR .GE. 2) THEN
        IF (PkFnVarVal(1,4) .GT. PkFnVarVal(1,3)) THEN
!U         IF (Confirm('HMSL is greater than HPSL.'//CHAR(13)//&
!U         'Check for bad values in peak width list.'//CHAR(13)// &
!U         'An expediency: do you wish to swap values?')) THEN
           ptem3 = PkFnVarVal(1,3)
           ptem4 = PkFnVarVal(1,4)
           PkFnVarVal(1,3) = ptem4
           PkFnVarVal(1,4) = ptem3
!U         ENDIF
        ENDIF
      ENDIF
      CALL PopActiveWindowID

      END SUBROUTINE Upload_Widths
!
!*****************************************************************************
!
      SUBROUTINE FillFUNVAL_COMMON(IPtPS)
!
! The chi-sqrds for sigma, gamma, HPSL and HMSL are calculated from values in /FUNVAL/
! which must be filled with values from /PEAKFIT2/
! IPtPS = 1 : sigma
!         2 : gamma
!         3 : HPSL
!         4 : HMSL
! Peak fit ranges that have not been fitted are excluded.
!
      IMPLICIT NONE

      INTEGER, INTENT (IN   ) :: IPtPS

      INCLUDE 'PARAMS.INC'

      REAL              XPF_Range
      LOGICAL                                       RangeFitYN
      INTEGER           IPF_Lo,                     IPF_Hi
      INTEGER           NumPeakFitRange,            CurrentRange
      INTEGER           IPF_Range
      INTEGER           NumInPFR
      REAL              XPF_Pos,                    YPF_Pos
      INTEGER           IPF_RPt
      REAL              XPeakFit,                   YPeakFit
      COMMON /PEAKFIT1/ XPF_Range(2,MAX_NPFR),      RangeFitYN(MAX_NPFR),        &
                        IPF_Lo(MAX_NPFR),           IPF_Hi(MAX_NPFR),            &
                        NumPeakFitRange,            CurrentRange,                &
                        IPF_Range(MAX_NPFR),                                     &
                        NumInPFR(MAX_NPFR),                                      & 
                        XPF_Pos(MAX_NPPR,MAX_NPFR), YPF_Pos(MAX_NPPR,MAX_NPFR),  &
                        IPF_RPt(MAX_NPFR),                                       &
                        XPeakFit(MAX_FITPT),        YPeakFit(MAX_FITPT)

      REAL              PkFnVal,                      PkFnEsd,                      &
                        PkFnCal,                                                    &
                        PkFnVarVal,                   PkFnVarEsd,                   &
                        PkAreaVal,                    PkAreaEsd,                    &
                        PkPosVal,                     PkPosEsd,                     &
                        PkPosAv
      COMMON /PEAKFIT2/ PkFnVal(MPkDes,Max_NPFR),     PkFnEsd(MPkDes,Max_NPFR),     &
                        PkFnCal(MPkDes,Max_NPFR),                                   &
                        PkFnVarVal(3,MPkDes),         PkFnVarEsd(3,MPkDes),         &
                        PkAreaVal(MAX_NPPR,MAX_NPFR), PkAreaEsd(MAX_NPPR,MAX_NPFR), &
                        PkPosVal(MAX_NPPR,MAX_NPFR),  PkPosEsd(MAX_NPPR,MAX_NPFR),  &
                        PkPosAv(MAX_NPFR)

      INTEGER     MVAL
      PARAMETER ( MVAL = 50 )
      INTEGER         NVAL
      REAL                  XVAL,       YVAL,       ZVAL,       EVAL
      COMMON /FUNVAL/ NVAL, XVAL(MVAL), YVAL(MVAL), ZVAL(MVAL), EVAL(MVAL)

      INTEGER I, NumFittedPFR

      NumFittedPFR = 0 ! The number of Peak Fit Ranges that have actually been fitted
! Loop over all hatched areas.
      IF (NumPeakFitRange .GT. 0) THEN
        DO I = 1, NumPeakFitRange
          IF (RangeFitYN(I)) THEN
            CALL INC(NumFittedPFR)
            XVAL(NumFittedPFR) = PkPosAv(I)
            YVAL(NumFittedPFR) = PkFnVal(IPtPS,I)
            EVAL(NumFittedPFR) = MAX(0.01 * ABS(YVAL(NumFittedPFR)),PkFnEsd(IPtPS,I))
          ENDIF
        ENDDO
      ENDIF
      IF (NumFittedPFR .EQ. 0) CALL DebugErrorMessage('NumFittedPFR .EQ. 0 in FillFUNVAL_COMMON()')
      NVAL = NumFittedPFR

      END SUBROUTINE FillFUNVAL_COMMON
!
!*****************************************************************************
!
      SUBROUTINE FillPkFnCal(IPtPS)
!
! The results from the chi-sqrds for sigma, gamma, HPSL and HMSL are stored in /PEAKFIT2/
! with values from /FUNVAL/.
! Essentially, this routine is the inverse of FillFUNVAL_COMMON()
! IPtPS = 1 : sigma
!         2 : gamma
!         3 : HPSL
!         4 : HMSL
! Peak fit ranges that have not been fitted are excluded.
!
      IMPLICIT NONE

      INTEGER, INTENT (IN   ) :: IPtPS

      INCLUDE 'PARAMS.INC'

      REAL              XPF_Range
      LOGICAL                                       RangeFitYN
      INTEGER           IPF_Lo,                     IPF_Hi
      INTEGER           NumPeakFitRange,            CurrentRange
      INTEGER           IPF_Range
      INTEGER           NumInPFR
      REAL              XPF_Pos,                    YPF_Pos
      INTEGER           IPF_RPt
      REAL              XPeakFit,                   YPeakFit
      COMMON /PEAKFIT1/ XPF_Range(2,MAX_NPFR),      RangeFitYN(MAX_NPFR),        &
                        IPF_Lo(MAX_NPFR),           IPF_Hi(MAX_NPFR),            &
                        NumPeakFitRange,            CurrentRange,                &
                        IPF_Range(MAX_NPFR),                                     &
                        NumInPFR(MAX_NPFR),                                      & 
                        XPF_Pos(MAX_NPPR,MAX_NPFR), YPF_Pos(MAX_NPPR,MAX_NPFR),  &
                        IPF_RPt(MAX_NPFR),                                       &
                        XPeakFit(MAX_FITPT),        YPeakFit(MAX_FITPT)

      REAL              PkFnVal,                      PkFnEsd,                      &
                        PkFnCal,                                                    &
                        PkFnVarVal,                   PkFnVarEsd,                   &
                        PkAreaVal,                    PkAreaEsd,                    &
                        PkPosVal,                     PkPosEsd,                     &
                        PkPosAv
      COMMON /PEAKFIT2/ PkFnVal(MPkDes,Max_NPFR),     PkFnEsd(MPkDes,Max_NPFR),     &
                        PkFnCal(MPkDes,Max_NPFR),                                   &
                        PkFnVarVal(3,MPkDes),         PkFnVarEsd(3,MPkDes),         &
                        PkAreaVal(MAX_NPPR,MAX_NPFR), PkAreaEsd(MAX_NPPR,MAX_NPFR), &
                        PkPosVal(MAX_NPPR,MAX_NPFR),  PkPosEsd(MAX_NPPR,MAX_NPFR),  &
                        PkPosAv(MAX_NPFR)

      INTEGER     MVAL
      PARAMETER ( MVAL = 50 )
      INTEGER         NVAL
      REAL                  XVAL,       YVAL,       ZVAL,       EVAL
      COMMON /FUNVAL/ NVAL, XVAL(MVAL), YVAL(MVAL), ZVAL(MVAL), EVAL(MVAL)

      INTEGER I, NumFittedPFR

      NumFittedPFR = 0 ! The number of Peak Fit Ranges that have actually been fitted
! Loop over all hatched areas.
      DO I = 1, NumPeakFitRange
        IF (RangeFitYN(I)) THEN
          CALL INC(NumFittedPFR)
          PkFnCal(IPtPS,I) = ZVAL(NumFittedPFR)
        ENDIF
      ENDDO

      END SUBROUTINE FillPkFnCal
!
!*****************************************************************************
!
      SUBROUTINE Fit_Sigma(X,DX,N)

      IMPLICIT NONE

      INTEGER, INTENT (IN   ) :: N

      INCLUDE 'PARAMS.INC'

      INTEGER     MMPAR
      PARAMETER ( MMPAR = MVAR * MVAR )
      REAL X(MVAR), DX(MVAR)
  
      REAL COV(MMPAR)

      INTEGER         IBMBER
      COMMON /CCSLER/ IBMBER

      REAL Chisq_Sigma
      EXTERNAL Chisq_Sigma
      INTEGER I, II

! Observations
      CALL FillFUNVAL_COMMON(1)
! Variables
      DO I = 1, N
        X(I) = 0.01
        DX(I) = 0.01
      ENDDO
      CALL SIMOPT(X,DX,COV,N,Chisq_Sigma)
      IF (IBMBER .NE. 0) RETURN
      DO I = 1, N
        II = I + (I-1)*N
        DX(I) = SQRT(AMAX1(0.,COV(II)))
      ENDDO
      CALL FillPkFnCal(1)

      END SUBROUTINE Fit_Sigma
!
!*****************************************************************************
!
      SUBROUTINE Fit_Gamma(X,DX,N)

      IMPLICIT NONE

      INTEGER, INTENT (IN   ) :: N

      REAL Chisq_Gamma
      EXTERNAL Chisq_Gamma

      INCLUDE 'PARAMS.INC'

      INTEGER     MMPAR
      PARAMETER ( MMPAR = MVAR * MVAR )
      REAL X(MVAR),DX(MVAR),COV(MMPAR)

      INTEGER         IBMBER
      COMMON /CCSLER/ IBMBER

      INTEGER I, II

! Observations
      CALL FillFUNVAL_COMMON(2)
! Variables
      DO I = 1, N
        X(I) = 0.01
        DX(I) = 0.01
      ENDDO
      CALL SIMOPT(X,DX,COV,N,Chisq_Gamma)
      IF (IBMBER .NE. 0) RETURN
      DO I = 1, N
        II = I + (I-1) * N
        DX(I) = SQRT(AMAX1(0.,COV(II)))
      ENDDO
      CALL FillPkFnCal(2)

      END SUBROUTINE Fit_Gamma
!
!*****************************************************************************
!
      SUBROUTINE Fit_Constant(X,DX,N,IPtPS)

      IMPLICIT NONE

      INTEGER, INTENT (IN   ) :: N
      INTEGER, INTENT (IN   ) :: IPtPS

      REAL Chisq_Constant
      EXTERNAL Chisq_Constant

      INCLUDE 'PARAMS.INC'

      INTEGER     MMPAR
      PARAMETER ( MMPAR = MVAR * MVAR )
      REAL X(MVAR),DX(MVAR),COV(MMPAR)

      INTEGER IBMBER
      COMMON / CCSLER / IBMBER 

      INTEGER I, II

! Observations
      CALL FillFUNVAL_COMMON(IPtPS)
! Variables
      DO I = 1, N
        X(I) = 0.01
        DX(I) = 0.01
      ENDDO
      CALL SIMOPT(X,DX,COV,N,Chisq_Constant)
      IF (IBMBER .NE. 0) RETURN
      DO I = 1, N
        II = I + (I-1) * N
        DX(I) = SQRT(AMAX1(0.,COV(II)))
      ENDDO
      CALL FillPkFnCal(IPtPS)

      END SUBROUTINE Fit_Constant
!
!*****************************************************************************
!
      FUNCTION Chisq_Sigma(N,P)

      INTEGER     MVAR
      PARAMETER ( MVAR = 100 )
      REAL Chisq_Sigma, P(MVAR)

      INTEGER     MVAL
      PARAMETER ( MVAL = 50 )
      INTEGER         NVAL
      REAL                  XVAL,       YVAL,       ZVAL,       EVAL
      COMMON /FUNVAL/ NVAL, XVAL(MVAL), YVAL(MVAL), ZVAL(MVAL), EVAL(MVAL)

      Chisq_Sigma = 0.0
      DO I = 1, NVAL
        halfxi = 0.5 * XVAL(I)
        secth = 1.0 / COSD(halfxi)
        tanth = TAND(halfxi)
        ZVAL(I) = SQRT(MAX(0.0,(P(1)*secth)**2+(P(2)*tanth)**2))
        CTEM = (ZVAL(I)-YVAL(I))/EVAL(I)
        Chisq_Sigma = Chisq_Sigma + CTEM*CTEM
      ENDDO

      END FUNCTION Chisq_Sigma
!
!*****************************************************************************
!
      FUNCTION Chisq_Gamma(N,P)

      INTEGER     MVAR
      PARAMETER ( MVAR = 100 )
      REAL Chisq_Gamma, P(MVAR)

      INTEGER     MVAL
      PARAMETER ( MVAL = 50 )
      INTEGER         NVAL
      REAL                  XVAL,       YVAL,       ZVAL,       EVAL
      COMMON /FUNVAL/ NVAL, XVAL(MVAL), YVAL(MVAL), ZVAL(MVAL), EVAL(MVAL)

      Chisq_Gamma = 0.0
      DO I = 1, NVAL
        halfxi = 0.5 * XVAL(I)
        secth = 1.0 / COSD(halfxi)
        tanth = TAND(halfxi)
        ZVAL(I) = P(1) * secth + P(2) * tanth
        CTEM = (ZVAL(I)-YVAL(I)) / EVAL(I)
        Chisq_Gamma = Chisq_Gamma + CTEM * CTEM
      ENDDO

      END FUNCTION Chisq_Gamma
!
!*****************************************************************************
!
      FUNCTION Chisq_Constant(N,P)

      INTEGER     MVAR
      PARAMETER ( MVAR = 100 )
      REAL Chisq_Constant, P(MVAR)

      INTEGER     MVAL
      PARAMETER ( MVAL = 50 )
      INTEGER         NVAL
      REAL                  XVAL,       YVAL,       ZVAL,       EVAL
      COMMON /FUNVAL/ NVAL, XVAL(MVAL), YVAL(MVAL), ZVAL(MVAL), EVAL(MVAL)

      Chisq_Constant = 0.0
      DO I = 1, NVAL
        ZVAL(I) = P(1)
        CTEM = (ZVAL(I)-YVAL(I)) / EVAL(I)
        Chisq_Constant = Chisq_Constant + CTEM * CTEM
      ENDDO

      END FUNCTION Chisq_Constant
!
!*****************************************************************************
!
