!
!*****************************************************************************
!
      INTEGER FUNCTION WriteSAParametersToFile(TheFileName)

      USE WINTERACTER
      USE DRUID_HEADER
      USE ZMVAR
      
      IMPLICIT NONE

      CHARACTER*(*), INTENT (IN   ) :: TheFileName

      INTEGER         nvar, ns, nt, maxevl, iseed1, iseed2
      COMMON /sapars/ nvar, ns, nt, maxevl, iseed1, iseed2

      REAL             PAWLEYCHISQ, RWPOBS, RWPEXP
      COMMON /PRCHISQ/ PAWLEYCHISQ, RWPOBS, RWPEXP

      INTEGER tFileHandle, I, kk, ifrg, ilen, II, Fixed
      REAL    R, x, lb, ub
      CHARACTER*80 tSDIFile
      CHARACTER*17 DateStr
      REAL    MaxMoves1, tMaxMoves
      INTEGER MaxMoves2
      CHARACTER*20, EXTERNAL :: Integer2String
      CHARACTER*20 MaxMovesStr
      INTEGER, EXTERNAL :: DateToday

      WriteSAParametersToFile = 1 ! Error
      CALL PushActiveWindowID
      tFileHandle = 10
      OPEN(tFileHandle,FILE=TheFileName,ERR=999)
      WRITE(tFileHandle,'("  Parameters for simulated annealing in DASH")',ERR=999)
      CALL Date2String(DateToday(),DateStr)
      WRITE(tFileHandle,'(A)',ERR=999) "  Date = "//DateStr(1:LEN_TRIM(DateStr))
      CALL WDialogSelect(IDD_SAW_Page1)
      CALL WDialogGetString(IDF_SA_Project_Name,tSDIFile)
      WRITE(tFileHandle,'("  SDI file = ",A)',ERR=999) tSDIFile(1:LEN_TRIM(tSDIFile))
! Profile range (including maximum resolution), wavelength, unit cell parameters, zero point

      CALL WDialogSelect(IDD_SA_input2)
      kk = 0
      DO ifrg = 1, maxfrg
        IF (gotzmfile(ifrg)) THEN
! Write the name of the file
          ilen = LEN_TRIM(frag_file(ifrg))
          WRITE(tFileHandle,'(A)',ERR=999) '  Z-matrix '//frag_file(ifrg)(1:ilen)
          DO ii = 1, izmpar(ifrg)
            kk = kk + 1
            ilen = LEN_TRIM(czmpar(ii,ifrg))
            CALL WGridGetCellReal    (IDF_parameter_grid,1,kk,x)
            CALL WGridGetCellCheckBox(IDF_parameter_grid,4,kk,Fixed)
            IF (Fixed .EQ. 1) THEN
              WRITE(tFileHandle,"('    ',A36,1X,F12.5,1X,A5)",ERR=999) czmpar(ii,ifrg),x,'Fixed'
            ELSE
              CALL WGridGetCellReal(IDF_parameter_grid,2,kk,lb)
              CALL WGridGetCellReal(IDF_parameter_grid,3,kk,ub)
              WRITE(tFileHandle,"('    ',A36,1X,F12.5,1X,F12.5,1X,F12.5)",ERR=999) czmpar(ii,ifrg),x,lb,ub
            ENDIF
          ENDDO
        ENDIF
      ENDDO
! Total number of parameters for this problem
! Number of atoms
      CALL WDialogSelect(IDD_SA_input3)
      CALL WDialogGetInteger(IDF_SA_RandomSeed1,I)
      WRITE(tFileHandle,'("  Random seed 1 = ",I5)',ERR=999) I
      CALL WDialogGetInteger(IDF_SA_RandomSeed2,I)
      WRITE(tFileHandle,'("  Random seed 2 = ",I5)',ERR=999) I
      CALL WDialogGetReal(IDF_SA_T0,R)
      IF (R .EQ. 0.0) THEN
        WRITE(tFileHandle,'("  Initial temperature = to be estimated by DASH")',ERR=999)
      ELSE
        WRITE(tFileHandle,'("  Initial temperature = ",F9.2)',ERR=999) R
      ENDIF
      CALL WDialogGetReal(IDF_SA_Tredrate,R)
      WRITE(tFileHandle,'("  Cooling rate = ",F8.4)',ERR=999) R
      CALL WDialogGetInteger(IDF_SA_NS,I)
      WRITE(tFileHandle,'("  N1 = ",I5)',ERR=999) I
      CALL WDialogGetInteger(IDF_SA_NT,I)
      WRITE(tFileHandle,'("  N2 = ",I5)',ERR=999) I
      CALL WDialogGetInteger(IDF_SA_Moves,I)
      WRITE(tFileHandle,'("  Number of moves at each temperature = ",I5)',ERR=999) I
      CALL WDialogGetInteger(IDF_SA_MaxRepeats,I) ! Number of runs
      IF (I .EQ. 1) THEN
        WRITE(tFileHandle,'("  Single run, runs until user stops it")',ERR=999)
      ELSE
        WRITE(tFileHandle,'("  Number of runs = ",I5)',ERR=999) I
        CALL WDialogGetReal(IDF_MaxMoves1,MaxMoves1)
        IF (MaxMoves1 .LT.   0.001) MaxMoves1 =   0.001
        IF (MaxMoves1 .GT. 100.0  ) MaxMoves1 = 100.0
        CALL WDialogGetInteger(IDF_MaxMoves2,MaxMoves2)
        IF (MaxMoves2 .LT. 1) MaxMoves2 = 1
        IF (MaxMoves2 .GT. 8) MaxMoves2 = 8
        tMaxMoves = MaxMoves1 * (10**FLOAT(MaxMoves2))
        IF (tMaxMoves .LT. 10.0) tMaxMoves = 10.0
        IF (tMaxMoves .GT.  2.0E9) tMaxMoves = 2.0E9
        I = NINT(tMaxMoves)
        MaxMovesStr = Integer2String(I)
        ilen = LEN_TRIM(MaxMovesStr)
! 1000000000 ==> 1000000,000
        IF (ilen .GT. 3) THEN
          MaxMovesStr(ilen-1:ilen+1) = MaxMovesStr(ilen-2:ilen)
          MaxMovesStr(ilen-2:ilen-2) = ','
        ENDIF
! 1000000,000 ==> 1000,000,000
        IF (ilen .GT. 6) THEN
          MaxMovesStr(ilen-4:ilen+2) = MaxMovesStr(ilen-5:ilen+1)
          MaxMovesStr(ilen-5:ilen-5) = ','
        ENDIF
! 1000,000,000 ==> 1,000,000,000
        IF (ilen .GT. 9) THEN
          MaxMovesStr(ilen-7:ilen+3) = MaxMovesStr(ilen-8:ilen+2)
          MaxMovesStr(ilen-8:ilen-8) = ','
        ENDIF
        WRITE(tFileHandle,'("  Maximum number of moves per run = ",A)',ERR=999) MaxMovesStr(1:LEN_TRIM(MaxMovesStr))
        CALL WDialogGetReal(IDF_SA_ChiTest,R)
        WRITE(tFileHandle,'("  A run will stop when the profile chi� is less than ",   &
                F6.2," � ",F7.3," = ",F8.4)',ERR=999) R, PAWLEYCHISQ, R*PAWLEYCHISQ
      ENDIF

      CLOSE(tFileHandle)
      CALL PopActiveWindowID
      WriteSAParametersToFile = 0 ! success
      RETURN
  999 CALL ErrorMessage('Could not access temporary file.')
      CLOSE(tFileHandle)
      CALL PopActiveWindowID

      END FUNCTION WriteSAParametersToFile
!
!*****************************************************************************
!
      SUBROUTINE ViewZmatrix(ifrg)

      USE WINTERACTER
      USE DRUID_HEADER
      USE VARIABLES
      USE ZMVAR
      USE SAMVAR

      IMPLICIT NONE

      INTEGER, INTENT (IN   ) :: ifrg

      INTEGER I
      CHARACTER*85 temp_file
      CHARACTER*2  AtmElement(1:MAXATM_2)
      REAL*8 CART(1:3,1:MAXATM)
      INTEGER IHANDLE
      INTEGER, EXTERNAL :: WriteMol2
      LOGICAL, EXTERNAL :: Get_ColourFlexibleTorsions
      INTEGER atom
      INTEGER Element
      INTEGER NumOfFlexTorsions
      INTEGER tLength, BondNr

      natcry = NATOMS(ifrg)
      CALL MAKEXYZ_2(natcry,BLEN(1,ifrg),ALPH(1,ifrg),BET(1,ifrg),IZ1(1,ifrg),IZ2(1,ifrg),IZ3(1,ifrg),CART)
! Conversion of asym to aelem : very dirty, but works
      DO I = 1, natcry
        axyzo(I,1) = SNGL(CART(1,I))
        axyzo(I,2) = SNGL(CART(2,I))
        axyzo(I,3) = SNGL(CART(3,I))
        AtmElement(I)(1:2) = asym(I,ifrg)(1:2)
        atomlabel(I) = OriginalLabel(I,ifrg)
      ENDDO
      CALL AssignCSDElement(AtmElement)
      nbocry = NumberOfBonds(ifrg)
      DO BondNr = 1, nbocry
        btype(BondNr)  = BondType(BondNr,ifrg)
        bond(BondNr,1) = Bonds(1,BondNr,ifrg)
        bond(BondNr,2) = Bonds(2,BondNr,ifrg)
      ENDDO
! Q & D hack to display flexible torsion angles in different colors by forcing different
! element types.
      IF (Get_ColourFlexibleTorsions() .AND. (natcry.GE.4)) THEN
        DO I = 1, natcry
          aelem(I) = 1       ! Carbon        Grey
        ENDDO
        NumOfFlexTorsions = 0
        DO atom = 4, natcry
          IF (ioptt(atom,ifrg) .EQ. 1) THEN
            NumOfFlexTorsions = NumOfFlexTorsions + 1
            SELECT CASE(NumOfFlexTorsions)
              CASE (1)
                Element = 23 ! Cobalt        Blue
              CASE (2)
                Element = 64 ! Oxygen        Red
              CASE (3)
                Element = 81 ! Sulphur       Yellow
              CASE (4)
                Element = 21 ! Chlorine      Green
              CASE (5)
                Element = 56 ! Nitrogen      Light blue
              CASE (6)
                Element = 16 ! Bromine       Brown
              CASE (7)
                Element = 43 ! Iodine        Pink
              CASE (8)
                Element =  2 ! Hydrogen      White
              CASE (9)
                Element = 66 ! Phosphorus
            END SELECT
            aelem(atom) = Element
            aelem(IZ1(atom,ifrg)) = Element
            aelem(IZ2(atom,ifrg)) = Element
            aelem(IZ3(atom,ifrg)) = Element
          ENDIF
        ENDDO
      ENDIF
      tLength = LEN_TRIM(frag_file(ifrg))
      temp_file = frag_file(ifrg)(1:tLength-8)//'_temp.mol2'
! Show the mol2 file
      IF (WriteMol2(temp_file) .EQ. 1) CALL ViewStructure(temp_file)
      CALL IOSDeleteFile(temp_file)
! Show the Z-matrix file in an editor window
      CALL WindowOpenChild(IHANDLE)
      CALL WEditFile(frag_file(ifrg),Modeless,0,FileMustExist+ViewOnly+NoToolbar+NoFileNewOpen,4)
      CALL SetChildWinAutoClose(IHANDLE)

      END SUBROUTINE ViewZmatrix
!
!*****************************************************************************
!
      SUBROUTINE SA_Parameter_Set

      USE WINTERACTER
      USE DRUID_HEADER
      USE ZMVAR

      IMPLICIT NONE

      INCLUDE 'GLBVAR.INC'
      INCLUDE 'lattice.inc'

      INTEGER    MVAR
      PARAMETER (MVAR = 100)
      DOUBLE PRECISION XOPT,       C,       XP,       FOPT
      COMMON /sacmn /  XOPT(MVAR), C(MVAR), XP(MVAR), FOPT

! JCC Handle via the PDB standard
      DOUBLE PRECISION f2cpdb
      COMMON /pdbcat/ f2cpdb(3,3)

      DOUBLE PRECISION x,lb,ub,vm,xpreset
      COMMON /values/ x(mvar),lb(mvar),ub(mvar),vm(mvar)
      COMMON /presetr/ xpreset(mvar)

      DOUBLE PRECISION prevub, prevlb ! For saving the previous range
      COMMON /pvalues/ prevub(mvar), prevlb(mvar)

      LOGICAL log_preset
      COMMON /presetl/ log_preset

      DOUBLE PRECISION T0,rt
      COMMON /saparl/ T0,rt
      INTEGER         nvar, ns, nt, maxevl, iseed1, iseed2
      COMMON /sapars/ nvar, ns, nt, maxevl, iseed1, iseed2

      CHARACTER*36 parlabel(mvar)
      DOUBLE PRECISION dcel(6)
      INTEGER I, II, KK, ifrg, tk, iOption

      CALL PushActiveWindowID
      DO I = 1, 6
        dcel(I) = DBLE(CellPar(I))
      ENDDO
      CALL frac2cart(f2cmat,dcel(1),dcel(2),dcel(3),dcel(4),dcel(5),dcel(6))
      CALL frac2pdb(f2cpdb,dcel(1),dcel(2),dcel(3),dcel(4),dcel(5),dcel(6))
      CALL CREATE_FOB()
! Per Z-matrix, determine whether to use quaternions or a single axis
      CALL WDialogSelect(IDD_SAW_Page2)
      DO ifrg = 1, maxfrg
        IF (gotzmfile(ifrg)) THEN
          CALL WGridGetCellMenu(IDF_RotationsGrid,1,ifrg,iOption)
          UseQuaternions(ifrg) = (iOption .NE. 3)
          IF (.NOT. UseQuaternions(ifrg)) THEN
            CALL WGridGetCellReal(IDF_RotationsGrid,2,ifrg,zmSingleRotationAxis(1,ifrg))
            CALL WGridGetCellReal(IDF_RotationsGrid,3,ifrg,zmSingleRotationAxis(2,ifrg))
            CALL WGridGetCellReal(IDF_RotationsGrid,4,ifrg,zmSingleRotationAxis(3,ifrg))
          ENDIF
        ENDIF
      ENDDO
      kk = 0
      tk = 0
! JCC Run through all possible fragments
      DO ifrg = 1, maxfrg
! Only include those that are now checked
        IF (gotzmfile(ifrg)) THEN
          DO ii = 1, izmpar(ifrg)
            kk = kk + 1
            x(kk) = xzmpar(ii,ifrg)
            parlabel(kk) = czmpar(ii,ifrg)
            SELECT CASE (kzmpar(ii,ifrg))
              CASE (1) ! position
                lb(kk) = 0.0
                ub(kk) = 1.0
              CASE (2,6) ! quaternion
                IF (UseQuaternions(ifrg)) THEN
                  kzmpar(ii,ifrg) = 2 ! quaternion instead of single axis 
                  lb(kk) = -1.0
                  ub(kk) =  1.0
                ELSE
                  kzmpar(ii,ifrg) = 6 ! single axis instead of quaternion 
! At the moment a Z-matrix containing more than one atom is read in, four
! parameters are reserved for 'rotations'. When the rotation is restricted to
! a single axis, only two of these parameters are necessary. By setting
! upper bound - lower bound to 0.000001, these parameters will be considered 'fixed'
! and will not be picked during the SA, nor will they be optimised during the simpex minimisation.
                  tk = tk + 1
                  SELECT CASE (tk)
                    CASE (1,2) 
                      lb(kk) = -1.0
                      ub(kk) =  1.0
                    CASE (3,4) 
                      lb(kk) =  0.0
                      ub(kk) =  0.000001
                  END SELECT
                  IF (tk .EQ. 4) tk = 0
                ENDIF
              CASE (3) ! torsion
                IF      (x(kk) .LT. 0.0 .AND. x(kk) .GT. -180.0) THEN
                  lb(kk) =  -180.0
                  ub(kk) =   180.0
                ELSE IF (x(kk) .GT. 0.0 .AND. x(kk) .LT.  360.0) THEN
                  lb(kk) =   0.0
                  ub(kk) = 360.0
                ELSE 
                  lb(kk) = x(kk) - 180.0
                  ub(kk) = x(kk) + 180.0
                ENDIF              
              CASE (4) ! angle
                lb(kk) = x(kk) - 10.0
                ub(kk) = x(kk) + 10.0
                vm(kk) = 1.0
              CASE (5) ! bond
                lb(kk) = 0.9*x(kk)
                ub(kk) = x(kk)/0.9
            END SELECT
          ENDDO
!JCC End of check on selection
        ENDIF
      ENDDO
      nvar = kk
! Now fill the grid
      CALL WDialogSelect(IDD_SA_input2)
      CALL WGridRows(IDF_parameter_grid,nvar)
      DO i = 1, nvar
        CALL WGridLabelRow(IDF_parameter_grid,i,parlabel(i))
        CALL WGridPutCellReal(IDF_parameter_grid,1,i,SNGL(x(i)),'(F12.5)')
        CALL WGridPutCellReal(IDF_parameter_grid,2,i,SNGL(lb(i)),'(F12.5)')
        CALL WGridPutCellReal(IDF_parameter_grid,3,i,SNGL(ub(i)),'(F12.5)')
        CALL WGridPutCellCheckBox(IDF_parameter_grid,4,i,Unchecked)
        CALL WGridPutCellCheckBox(IDF_parameter_grid,5,i,Checked)
        CALL WGridStateCell(IDF_parameter_grid,1,i,Enabled)
        CALL WGridStateCell(IDF_parameter_grid,2,i,Enabled)
        CALL WGridStateCell(IDF_parameter_grid,3,i,Enabled)
        prevub(i) = ub(i)
        prevlb(i) = lb(i)
      ENDDO
      CALL PopActiveWindowID

      END SUBROUTINE SA_Parameter_Set
!
!*****************************************************************************
!
! JCC This subroutine handles the various types of status error that can arise 
! during a reading of a file and produces a suitable message to say what went wrong.
      SUBROUTINE FileErrorPopup(FileName, ErrorStatus)

      USE WINTERACTER

      INCLUDE 'iosdef.for'

      INTEGER       ErrorStatus
      CHARACTER*(*) FileName
      INTEGER       lenstr

      lenstr = LEN_TRIM(FileName)
      SELECT CASE(ErrorStatus)
        CASE (FOR$IOS_FILNOTFOU) 
          CALL ErrorMessage("The file "//CHAR(13)//FileName(1:lenstr)//CHAR(13)//" does not exist.")
        CASE (FOR$IOS_OPEFAI)
          CALL ErrorMessage("The file "//CHAR(13)//FileName(1:lenstr)//CHAR(13)//" could not be opened.")
        CASE (FOR$IOS_PERACCFIL)
          CALL ErrorMessage("You do not have permission to access the file "//FileName(1:lenstr))
        CASE DEFAULT
          CALL ErrorMessage("The file "//CHAR(13)//FileName(1:lenstr)//CHAR(13)//"was not read successfully.")
      END SELECT

      END SUBROUTINE FileErrorPopup
!
!*****************************************************************************
!
      SUBROUTINE UpdateZmatrixSelection

      USE WINTERACTER
      USE DRUID_HEADER
      USE ZMVAR

      IMPLICIT NONE

      INTEGER         NATOM
      REAL                   X
      INTEGER                          KX
      REAL                                        AMULT,      TF
      INTEGER         KTF
      REAL                      SITE
      INTEGER                              KSITE,      ISGEN
      REAL            SDX,        SDTF,      SDSITE
      INTEGER                                             KOM17
      COMMON /POSNS / NATOM, X(3,150), KX(3,150), AMULT(150), TF(150),  &
     &                KTF(150), SITE(150), KSITE(150), ISGEN(3,150),    &
     &                SDX(3,150), SDTF(150), SDSITE(150), KOM17

      INTEGER NumberOfDOF, izmtot, ifrg

      CALL PushActiveWindowID
      CALL WDialogSelect(IDD_SAW_Page1)
      nfrag  = 0
      izmtot = 0
      ntatm  = 0
      DO ifrg = 1, maxfrg
        IF (gotzmfile(ifrg)) THEN
          nfrag = nfrag + 1
          ntatm = ntatm + natoms(ifrg)
          IF (natoms(ifrg) .EQ. 1) THEN
            NumberOfDOF = 3 ! It's an atom
          ELSE
            NumberOfDOF = izmpar(ifrg) - 1 ! Count the quaternions as three, not four
          ENDIF
          izmtot = izmtot + NumberOfDOF
          CALL WDialogPutInteger(IDFZMpars(ifrg),NumberOfDOF)
          CALL WDialogPutString(IDFZMFile(ifrg),frag_file(ifrg))
! Enable 'View' button
          CALL WDialogFieldState(IDBZMView(ifrg),Enabled)
          CALL WDialogFieldState(IDBZMDelete(ifrg),Enabled)
        ELSE
          izmpar(ifrg) = 0
          natoms(ifrg) = 0
          CALL WDialogClearField(IDFZMpars(ifrg))
          CALL WDialogClearField(IDFZMFile(ifrg))
! Disable 'View' button
          CALL WDialogFieldState(IDBZMView(ifrg),Disabled)
          CALL WDialogFieldState(IDBZMDelete(ifrg),Disabled)
        ENDIF
      ENDDO
! JvdS @@ Following is wrong (we need a valid .sdi as well), but 
! a. identical to release version
! b. it's difficult to keep track of the validity of the .sdi file
      IF (nfrag .NE. 0) THEN
        CALL WDialogFieldState(IDNEXT,Enabled)
      ELSE
        CALL WDialogFieldState(IDNEXT,Disabled)
      ENDIF
      natom = ntatm
      IF (izmtot .EQ. 0) THEN            
        CALL WDialogClearField(IDF_ZM_allpars)
      ELSE
        CALL WDialogPutInteger(IDF_ZM_allpars,izmtot)
      ENDIF
      CALL PopActiveWindowID

      END SUBROUTINE UpdateZmatrixSelection
!
!*****************************************************************************
!
      SUBROUTINE ImportZmatrix
 
      USE WINTERACTER
      USE DRUID_HEADER
      USE VARIABLES

      IMPLICIT NONE

      INTEGER            I, iFlags, iSelection, Ilen, Istart, Istat
      INTEGER            POS
      CHARACTER(LEN=4)   :: EXT4
      CHARACTER(LEN=255) :: FilterStr, F
      CHARACTER(LEN=512) :: Zmfiles
      CHARACTER(LEN=5)   :: fmt     
      CHARACTER(LEN=512) :: Info = 'You can import molecules from res, cssr, mol2, mol or pdb files into DASH.'//CHAR(13)//&
                                   'When you click on OK, you will be prompted for a file in one'//CHAR(13)//&
                                   'of these formats. DASH will create separate Z-matrix files for'//CHAR(13)//&
                                   'each chemical residue present in the first entry in the file.'//CHAR(13)//&
                                   'In multiple entry files the first entry will be read only.'
      INTEGER, EXTERNAL :: Res2Mol2, CSSR2Mol2

      CALL InfoMessage(Info)
      IF (WInfoDialog(ExitButtonCommon) .NE. CommonOK) RETURN
      iFlags = LoadDialog + DirChange + AppendExt
      FilterStr = "All files (*.*)|*.*|"//&
                  "Molecular model files|*.pdb;*.mol2;*.ml2;*.mol;*.mdl;*.res;*.cssr|"//&
                  "Protein DataBank files (*.pdb)|*.pdb|"//&
                  "Mol2 files (*.mol2, *.ml2)|*.mol2;*.ml2|"//&
                  "mdl mol files|*.mol;*.mdl|"//&
                  "SHELX files (*.res)|*.res|"//&
                  "cssr files (*.cssr)|*.cssr|"
      iSelection = 2
      FNAME = ' '
      CALL WSelectFile(FilterStr, iFlags, FNAME,"Select a file for conversion",iSelection)
      Ilen = LEN_TRIM(FNAME)
      IF (Ilen .EQ. 0) RETURN
! Find the last occurence of '.' in TheFileName
      POS = Ilen-1 ! Last character of TheFileName is not tested
! The longest extension allowed is four
      DO WHILE ((POS .NE. 0) .AND. (FNAME(POS:POS) .NE. '.') .AND. (POS .NE. (Ilen-5)))
        POS = POS - 1
      ENDDO
! If we haven't found a '.' by now, we cannot deal with the extension anyway
      IF (FNAME(POS:POS) .NE. '.') THEN
        CALL ErrorMessage('Invalid extension.')
        RETURN
      ENDIF
      EXT4 = '    '
      EXT4 = FNAME(POS+1:Ilen)
      CALL ILowerCase(EXT4)
      SELECT CASE (EXT4)
        CASE ('cssr')
          ISTAT = CSSR2Mol2(FNAME)
          IF (ISTAT .NE. 1) RETURN
! Replace 'cssr' by 'mol2'
          FNAME = FNAME(1:Ilen-4)//'mol2'
          Ilen = LEN_TRIM(FNAME)
          fmt = '-mol2'
        CASE ('res ')
          ISTAT = Res2Mol2(FNAME)
          IF (ISTAT .NE. 1) RETURN
! Replace 'res' by 'mol2'
          FNAME = FNAME(1:Ilen-3)//'mol2'
          Ilen = LEN_TRIM(FNAME)
          fmt = '-mol2'
        CASE ('pdb ')
          fmt = '-pdb'
        CASE ('mol2','ml2 ')
          fmt = '-mol2'
        CASE ('mol ','mdl ')
          fmt = '-mol'
      END SELECT
! Run silently, 
      CALL IOSDeleteFile('MakeZmatrix.log')
      Istat = InfoError(1) ! Clear any errors 
      Istart = 1
      DO I = 1, Ilen
        IF (FNAME(I:I) .EQ. DIRSPACER) Istart = I + 1
      ENDDO
      CALL WCursorShape(CurHourGlass)
      CALL IOSCommand(InstallationDirectory(1:LEN_TRIM(InstallationDirectory))//'zmconv.exe'// &
        ' '//fmt(1:LEN_TRIM(fmt))//' "'//FNAME(Istart:Ilen)//'"',3)
      CALL WCursorShape(CurCrossHair)
! Check return status
      OPEN(UNIT=145, FILE='MakeZmatrix.log',STATUS='OLD',IOSTAT = ISTAT)
      IF ((InfoError(1) .EQ. ErrOSCommand) .OR. (ISTAT .NE. 0)) THEN
! An error occurred
        CALL ErrorMessage("Sorry, could not create Z-matrices.")
! Prompt with files created
      ELSE ! All Ok: Need to read in the file names
        F = ''
        Ilen = 1
        DO WHILE (Ilen .LT. 512)
          READ (145,'(A)',ERR=20,END=20) F
          ZmFiles(Ilen:512) = CHAR(13)//F(1:LEN_TRIM(F))
          Ilen = LEN_TRIM(ZmFiles) + 1
        ENDDO
 20     CONTINUE
        IF (LEN_TRIM(F) .EQ. 0) THEN
          CALL ErrorMessage("Sorry, could not create Z-matrices.")
        ELSE
          CALL InfoMessage("Generated the following Z-matrices successfully:"//CHAR(13)//&
                           ZmFiles(1:Ilen)//CHAR(13)//CHAR(13)//&
                           "You can load them by clicking on the Z-matrix browse buttons"//CHAR(13)//&
                           "in the Molecular Z-Matrices window.")
        ENDIF
        CLOSE(145)
      ENDIF

      END SUBROUTINE ImportZmatrix
!
!*****************************************************************************
!
