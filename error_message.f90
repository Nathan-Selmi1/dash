!
	SUBROUTINE CHKMAXREF(PCXX)
! Checks if the maximum number of reflections has been exceeded
!
    USE WINTERACTER
	external PCXX
	INCLUDE 'REFLNS.INC'
      PARAMETER (MPPTS=15000,MKPTS=150000)
      COMMON /ZSTORE/ NPTS,ZARGI(MPPTS),ZOBS(MPPTS),ZDOBS(MPPTS),&
     ZWT(MPPTS),ICODEZ(MPPTS),KOBZ(MPPTS)
      COMMON /PRPKCN/ARGK,PKCNSP(6,9,5),&
      KPCNSP(6,9,5),DTDPCN(6),DTDWL,&
      NPKCSP(9,5),ARGMIN(5),ARGMAX(5),&
      ARGSTP(5),PCON
	  integer iorda(10)
	  real ardi(10)
	  common /mxrfcm/ aadd

	  logical routine_called
      save routine_called
	  data routine_called / .false. /
!
	aadd=0.
	if (maxk.gt.360) then
!.. We've too many reflections ... must reduce
       if (.not. routine_called) then
         CALL WMessageBox(OKOnly,InformationIcon,CommonOK,  &
         'DASH has a maximium limit of 350 reflections.'//&
		 'Only the 350 lowest angle reflections will be indexed and used','File truncation')
		 routine_called =.true.
	   endif
	  know=350
	  call pcxx(2)
	  arrt=argk
	  do ii=1,1
	    know=350+ii
		call PCXX(2)
		ardi(ii)=argk-arrt
	    arrt=argk
	  end do
	  call sortx(ardi,iorda,10)
	  item=iorda(10)
	  maxk=349+item
	  aadd=ardi(10)
	end if
!
	  know=maxk
! Calculate peak centre in argk, and its derivatives
	  call pcxx(2)
	  armx=argk+aadd
	  ii=1
  	  do while ((zargi(ii) .LT. armx) .AND. (ii .LE. MPPTS))
	    ii=ii+1
	  end do
	  npts=min(npts,ii)
	  if (aadd.ne.0.0) argmax(1)=armx
!
	END
!
!*****************************************************************************
!
      SUBROUTINE CHKMAXREF_2(PCXX)
! Checks if the maximum number of reflections has been exceeded
!
      USE WINTERACTER

      EXTERNAL PCXX

      INCLUDE 'PARAMS.INC'
      INCLUDE 'REFLNS.INC'

      INTEGER         NPTS
      REAL                  ZARGI,        ZOBS,        ZDOBS,        ZWT
      INTEGER                                                                    ICODEZ
      REAL                                                                                      KOBZ
      COMMON /ZSTORE/ NPTS, ZARGI(MPPTS), ZOBS(MPPTS), ZDOBS(MPPTS), ZWT(MPPTS), ICODEZ(MPPTS), KOBZ(MPPTS)

      COMMON /PRPKCN/ARGK,PKCNSP(6,9,5), KPCNSP(6,9,5),DTDPCN(6),DTDWL,&
      NPKCSP(9,5),ARGMIN(5),ARGMAX(5), ARGSTP(5), PCON

      INTEGER iorda(10)
      REAL    ardif(10) ! Difference
      REAL    aadd ! Add
      REAL    arrt ! Relative

      LOGICAL routine_called
      SAVE routine_called
      DATA routine_called / .FALSE. /
!
      aadd = 0.0
      IF (maxk .GT. 360) THEN
!.. We've too many reflections ... must reduce
        IF (.NOT. routine_called) THEN
          CALL WMessageBox(OKOnly,InformationIcon,CommonOK,  &
               'DASH has a maximium limit of 350 reflections.'//CHAR(13)//&
               'Only the 350 lowest angle reflections will be indexed and used','File truncation')
          routine_called = .TRUE.
        ENDIF
        know = 350   ! know is a global variable used by PCXX
        CALL PCXX(2) ! Changes argk
        arrt = argk
! JvdS I don't understand the following lines at all: it seems to search for the maximum _difference_
! in 2 theta between two reflections between reflections 350 and 360. WHY!?
!
! JvdS was:
!       DO II = 1, 1
        DO II = 1, 10
          know = 350 + II ! know is a global variable
          CALL PCXX(2)
          ardif(II) = argk - arrt  ! argk is a global variable
          arrt = argk
        END DO
        CALL sortx(ardif,iorda,10)
        maxk = 349 + iorda(10)
        aadd = ardif(10)
      END IF
      know = maxk
! Calculate peak centre of know in argk, and its derivatives
      CALL pcxx(2)
! argk already contains the peak position of the very very last reflection because
! maxk has already been updated: why are we adding aadd again?
      armx = argk + aadd
      II = 1
      DO WHILE ((zargi(II) .LT. armx) .AND. (II .LE. MPPTS))
        II = II + 1
      END DO
      npts = MIN(npts,II)
      IF (aadd .NE. 0.0) argmax(1) = armx

      END SUBROUTINE CHKMAXREF_2
!
!*****************************************************************************
!
