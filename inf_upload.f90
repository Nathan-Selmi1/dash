      SUBROUTINE INF_UPLOAD()

      USE WINTERACTER
      USE DRUID_HEADER

      INCLUDE 'PARAMS.INC'

      COMMON /FCSTOR/MAXK,FOB(150,MFCSTO)
      COMMON /FPINF2/ NTERMS
      COMMON /CHISTO/ KKOR,WTIJ(MCHIHS),S2S(MCHIHS),S4S(MCHIHS),&
        IKKOR(MCHIHS),JKKOR(MCHIHS)
      COMMON /POSNS/NATOM,X(3,150),KX(3,150),AMULT(150), &
        TF(150),KTF(150),SITE(150),KSITE(150), &
        ISGEN(3,150),SDX(3,150),SDTF(150),SDSITE(150),KOM17

      CALL WDialogSelect(IDD_input_data)
      CALL WDialogPutInteger(IDF_reflections,MAXK)
      CALL WDialogPutInteger(IDF_contributors,NTERMS)
      CALL WDialogPutInteger(IDF_correlations,KKOR)
      CALL WDialogPutInteger(IDF_numatoms,NATOM)

      END SUBROUTINE INF_UPLOAD