!
!*****************************************************************************
!
      SUBROUTINE UPLOAD_RANGE()

      USE WINTERACTER
      USE DRUID_HEADER

      CHARACTER*8 chrfmt

      REAL             XPMIN,     XPMAX,     YPMIN,     YPMAX,       &
                       XPGMIN,    XPGMAX,    YPGMIN,    YPGMAX,      &
                       XPGMINOLD, XPGMAXOLD, YPGMINOLD, YPGMAXOLD,   &
                       XGGMIN,    XGGMAX
      COMMON /PROFRAN/ XPMIN,     XPMAX,     YPMIN,     YPMAX,       &
                       XPGMIN,    XPGMAX,    YPGMIN,    YPGMAX,      &
                       XPGMINOLD, XPGMAXOLD, YPGMINOLD, YPGMAXOLD,   &
                       XGGMIN,    XGGMAX

      LOGICAL, EXTERNAL :: FnPatternOK

      CALL PushActiveWindowID
      CALL WDialogSelect(IDD_Data_Properties)
      IF (.NOT. FnPatternOK()) THEN
        CALL WDialogClearField(IDF_xmin)
        CALL WDialogClearField(IDF_xmax)
        CALL WDialogClearField(IDF_ymin)
        CALL WDialogClearField(IDF_ymax)
        CALL PopActiveWindowID
        RETURN
      ENDIF
      atem1 = MAX(ABS(xpmin),ABS(xpmax))
      atem2 = 0.0001 * ABS(xpmax-xpmin)
      item1 = 0.5 + ALOG10(atem1)
      item2 = MAX(0.,0.5-ALOG10(atem2))
      item  = 2 + item1 + item2
      chrfmt(1:2) = '(F'
      IF (item .GE. 10) THEN
        CALL IntegerToString(item,chrfmt(3:4),'(I2)')
        inext = 5
      ELSE
        CALL IntegerToString(item,chrfmt(3:3),'(I1)')
        inext = 4
      END IF
      chrfmt(inext:inext) = '.'
      inext = inext + 1
      CALL IntegerToString(item2,chrfmt(inext:inext),'(I1)')
      inext = inext + 1
      chrfmt(inext:inext) = ')'
      CALL WDialogPutReal(IDF_xmin,xpmin,chrfmt(1:inext))
      CALL WDialogPutReal(IDF_xmax,xpmax,chrfmt(1:inext))
      atem1 = MAX(ABS(ypmin),ABS(ypmax))
      atem2 = 0.0001 * ABS(ypmax-ypmin)
      item1 = 0.5 + ALOG10(atem1)
      item2 = MAX(0.,0.5-ALOG10(atem2))
      item  = 2 + item1 + item2
      chrfmt(1:2) = '(F'
      IF (item.GE.10) THEN
        CALL IntegerToString(item,chrfmt(3:4),'(I2)')
        inext = 5
      ELSE
        CALL IntegerToString(item,chrfmt(3:3),'(I1)')
        inext = 4
      ENDIF
      chrfmt(inext:inext) = '.'
      inext = inext + 1
      CALL IntegerToString(item2,chrfmt(inext:inext),'(I1)')
      inext = inext + 1
      chrfmt(inext:inext) = ')'
      CALL WDialogPutReal(IDF_ymin,ypmin,chrfmt(1:inext))
      CALL WDialogPutReal(IDF_ymax,ypmax,chrfmt(1:inext))
      CALL PopActiveWindowID

      END SUBROUTINE UPLOAD_RANGE
!
!*****************************************************************************
!
