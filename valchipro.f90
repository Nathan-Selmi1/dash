      SUBROUTINE VALCHIPRO(chivalpro)
!
      USE WINTERACTER
      USE DRUID_HEADER
!

      INCLUDE 'PARAMS.INC'
	  COMMON /FCSPEC/ NLGREF,IREFH(3,MFCSPE),LOGREF(8,MFCSPE)
!     COMMON /FCSPEC/NPHSPC,TREFH(3,10000),PHSPEC(5,10000)
      COMMON /FCSTOR/MAXK,FOB(150,MFCSTO)

      COMMON /SAREFLNS/AIOBS(MSAREF),AICALC(MSAREF)

      COMMON /CHISTOP/ NOBS,NFIT,IFIT(MCHSTP),CHIOBS,&
      WT(MCHSTP),XOBS(MCHSTP),YOBS(MCHSTP),YCAL(MCHSTP),ESD(MCHSTP)
	  common /chibest/ ycalbest(MCHSTP)
      COMMON /FPINF/PIK(0:50,MFPINF),KMINST(MFPINF),KMAXST(MFPINF)
      COMMON /FPINF1/ KREFT(MFPINF),KNIPT(50,MFPINF),PIKVAL(50,MFPINF)

!
      include 'statlog.inc'
!
      include 'AllFFCalc.inc'
!
      SUM1=0.
      SUM2=0.
      DO II=1,NFIT
        I=IFIT(II)
        YCALC=0.
        DO K=1,KREFT(I)
          KK=KNIPT(K,I)
          YCALC=YCALC+AICALC(KK)*PIKVAL(K,I)
        END DO
!!        DO K=KMINST(I),KMAXST(I)
!!          KD=K-KMINST(I)
!!          YCALC=YCALC+AICALC(K)*PIK(KD,I)
!!        END DO
!        WY=WT(I)*YCALC
!        SUM1=SUM1+WY*YCALC
!        SUM2=SUM2+WY*YOBS(I)
        YCAL(I)=YCALC
        SUM1=SUM1+YCALC
        SUM2=SUM2+YOBS(I)
      END DO
      RESCL=SUM2/SUM1
      CVP=0.
      DO II=1,NFIT
        I=IFIT(II)
        CVP=CVP+WT(I)*(YOBS(I)-RESCL*YCAL(I))**2
        ycalbest(i)=rescl*ycal(i)
      END DO
!
!
!      CHIVALPRO=CHIOBS!-SUM2*SUM2/SUM1
!
      CHIVALPRO = CVP/FLOAT(NFIT-2)
!
!
!. Now output the new chi-squared
      CALL WDialogSelect(IDD_Profile_Status)
      CALL WDialogPutReal(IDF_profile_chisq,chivalpro,'(f15.2)')
!
      END