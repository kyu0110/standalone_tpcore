!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !MODULE: gigc_environment_mod
!
! !DESCRIPTION: Module GIGC\_ENVIRONMENT\_MOD establishes the runtime 
!  environment for the Grid-Independent GEOS-Chem (aka "GIGC") model.  It is 
!  designed to receive model parameter and geophysical environment information 
!  and allocate memory based upon it.
!\\
!\\
!  It provides routines to do the following:
!
! \begin{itemize}
! \item Allocate geo-spatial arrays
! \item Initialize met. field derived type.
! \item Initialize Chemistry, Metorology, Emissions, and Physics States
! \end{itemize}
!
! !INTERFACE: 
!
MODULE GIGC_Environment_Mod
!
! !USES
!        
  IMPLICIT NONE
  PRIVATE
!
! !PUBLIC MEMBER FUNCTIONS:
!
  PUBLIC  :: GIGC_Allocate_All
  PUBLIC  :: GIGC_Init_All
!
!
! !REMARKS:
!  For consistency, we should probably move the met state initialization
!  to the same module where the met state derived type is contained.
!
! !REVISION HISTORY:
!  26 Jan 2012 - M. Long     - Created module file
!  13 Aug 2012 - R. Yantosca - Added ProTeX headers
!  19 Oct 2012 - R. Yantosca - Removed routine INIT_LOCAL_MET, this is now
!                              handled in Headers/gigc_state_met_mod.F90
!  22 Oct 2012 - R. Yantosca - Renamed to gigc_environment_mod.F90
!  20 Aug 2013 - R. Yantosca - Removed "define.h", this is now obsolete
!EOP
!------------------------------------------------------------------------------
!BOC
CONTAINS
!EOC        
!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: gigc_allocate_all
!
! !DESCRIPTION: Subroutine GIGC\_ALLOCATE\_ALL allocates all LAT/LON 
!  ALLOCATABLE arrays for global use by the GEOS-Chem either as a standalone 
!  program or module.
!\\
!\\
! !INTERFACE:
!
  SUBROUTINE GIGC_Allocate_All( am_I_Root,       Input_Opt,       &
                                RC,              value_I_LO,      &
                                value_J_LO,      value_I_HI,      &
                                value_J_HI,      value_IM,        &
                                value_JM,        value_LM,        &
                                value_IM_WORLD,  value_JM_WORLD,  &
                                value_LM_WORLD )
!
! !USES:
!
    USE CMN_Mod,            ONLY : Init_CMN
    USE CMN_DIAG_Mod,       ONLY : Init_CMN_DIAG
    USE CMN_FJ_Mod,         ONLY : Init_CMN_FJ
    USE CMN_NOX_Mod,        ONLY : Init_CMN_NOX
    USE CMN_O3_Mod,         ONLY : Init_CMN_O3
    USE CMN_SIZE_Mod,       ONLY : Init_CMN_SIZE
    USE COMODE_LOOP_Mod,    ONLY : Init_COMODE_LOOP
    USE COMMSOIL_Mod,       ONLY : Init_COMMSOIL
    USE GIGC_ErrCode_Mod  
    USE GIGC_Input_Opt_Mod
    USE JV_CMN_Mod,         ONLY : Init_JV_CMN
    USE VDIFF_PRE_Mod,      ONLY : Init_VDIFF_PRE

    IMPLICIT NONE
!
! !INPUT PARAMETERS:
!
    LOGICAL,        INTENT(IN)    :: am_I_Root        ! Are we on the root CPU?
    INTEGER,        OPTIONAL      :: value_I_LO       ! Min local lon index
    INTEGER,        OPTIONAL      :: value_J_LO       ! Min local lat index
    INTEGER,        OPTIONAL      :: value_I_HI       ! Max local lon index
    INTEGER,        OPTIONAL      :: value_J_HI       ! Max local lat index
    INTEGER,        OPTIONAL      :: value_IM         ! Local # of lons
    INTEGER,        OPTIONAL      :: value_JM         ! Local # of lats
    INTEGER,        OPTIONAL      :: value_LM         ! Local # of levels
    INTEGER,        OPTIONAL      :: value_IM_WORLD   ! Global # of lons
    INTEGER,        OPTIONAL      :: value_JM_WORLD   ! Global # of lats
    INTEGER,        OPTIONAL      :: value_LM_WORLD   ! Global # of levels
!
! !INPUT/OUTPUT PARAMETERS:
!
    TYPE(OptInput), INTENT(INOUT) :: Input_Opt        ! Input Options object
!
! !OUTPUT PARAMETERS:
!
    INTEGER,        INTENT(OUT)   :: RC               ! Success or failure?
!
! !REMARKS:
!  For error checking, return up to the main routine w/ an error code.
!  This can be improved upon later.
!
! !REVISION HISTORY: 
!  26 Jan 2012 - M. Long     - Initial version
!  13 Aug 2012 - R. Yantosca - Added ProTeX headers
!  17 Oct 2012 - R. Yantosca - Add am_I_Root, RC as arguments
!  22 Oct 2012 - R. Yantosca - Renamed to GIGC_Allocate_All
!  30 Oct 2012 - R. Yantosca - Now pass am_I_Root, RC to SET_COMMSOIL_MOD
!  01 Nov 2012 - R. Yantosca - Now zero the fields of the Input Options object
!  16 Nov 2012 - R. Yantosca - Remove this routine from the #ifdef DEVEL block
!  27 Nov 2012 - R. Yantosca - Now pass Input_Opt to INIT_COMODE_LOOP
!  03 Dec 2012 - R. Yantosca - Now pass am_I_Root, RC to INIT_CMN_SIZE
!  03 Dec 2012 - R. Yantosca - Add optional arguments to accept dimension
!                              size information from the ESMF interface
!  13 Dec 2012 - R. Yantosca - Remove reference to obsolete CMN_DEP_mod.F
!EOP
!------------------------------------------------------------------------------
!BOC

    ! Initialize fields of the Input Options object
    CALL Set_GIGC_Input_Opt( am_I_Root, Input_Opt, RC )
    IF ( RC /= GIGC_SUCCESS ) THEN
       WRITE( 6, '(a)' ) 'ERROR initializing Input_Opt'
       RETURN
    ENDIF

    !-----------------------------------------------------------------------
    !                   %%%%% TRADITIONAL GEOS-Chem %%%%%
    !
    ! Current practice in the standard GEOS-Chem is to set dimension sizes
    ! from parameters IGLOB, JGLOB, LGLOB in CMN_SIZE_mod.F.  Therefore,
    ! we do not need to call INIT_CMN_SIZE with optional parameters as is
    ! done when connecting to the ESMF interface.  
    !-----------------------------------------------------------------------

    ! Set dimensions in CMN_SIZE
    CALL Init_CMN_SIZE( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    ! Set dimensions in CMN_DEP_mod.F and allocate arrays
    CALL Init_CMN( am_I_Root, RC )  
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_CMN_DIAG( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_CMN_FJ( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_CMN_NOX( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_CMN_O3( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_COMMSOIL( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_COMODE_LOOP( am_I_Root, Input_Opt, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_JV_CMN( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN

    CALL Init_VDIFF_PRE( am_I_Root, RC )
    IF ( RC /= GIGC_SUCCESS ) RETURN
          
  END SUBROUTINE GIGC_Allocate_All
!EOC
!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: gigc_init_all
!
! !DESCRIPTION: Subroutine GIGC\_INIT\_ALL initializes the top-level data 
!  structures that are either passed to/from GC or between GC components 
!  (emis->transport->chem->etc)
!\\
!\\
! !INTERFACE:
!
  SUBROUTINE GIGC_Init_All( am_I_Root, Input_Opt, State_Chm, State_Met, RC )
!
! !USES:
!
    USE CMN_Size_Mod,       ONLY : IIPAR, JJPAR, LLPAR, NBIOMAX
    USE Comode_Loop_Mod,    ONLY : IGAS
    USE GIGC_ErrCode_Mod
    USE GIGC_Input_Opt_Mod
    USE GIGC_State_Chm_Mod
    USE GIGC_State_Met_Mod
!
! !INPUT PARAMETERS:
!
    LOGICAL,        INTENT(IN)    :: am_I_Root   ! Are we on the root CPU?
    TYPE(OptInput), INTENT(IN)    :: Input_Opt   ! Input Options object
!
! !INPUT/OUTPUT PARAMETERS:
!
    TYPE(MetState), INTENT(INOUT) :: State_Met   ! Meteorology State object
    TYPE(ChmState), INTENT(INOUT) :: State_Chm   ! Chemistry State object
!
! !OUTPUT PARAMETERS:
!
    INTEGER,        INTENT(OUT)   :: RC          ! Success or failure
!
! !REMARKS:
!  Need to add better error checking, currently we just return upon error.
!
! !REVISION HISTORY: 
!  26 Jan 2012 - M. Long     - Initial version
!  13 Aug 2012 - R. Yantosca - Added ProTeX headers
!  16 Oct 2012 - R. Yantosca - Renamed LOCAL_MET argument to State_Met
!  16 Oct 2012 - R. Yantosca - Renamed GC_STATE  argument to State_Chm
!  16 Oct 2012 - R. Yantosca - Call Init_Chemistry_State (in gc_type2_mod.F90,
!                              which was renamed from INIT_CHEMSTATE)
!  19 Oct 2012 - R. Yantosca - Now reference gigc_state_met_mod.F90
!  19 Oct 2012 - R. Yantosca - Now reference gigc_state_chm_mod.F90
!  19 Oct 2012 - R. Yantosca - Now reference gigc_errcode_mod.F90
!  19 Oct 2012 - R. Yantosca - Now reference IGAS in Headers/comode_loop_mod.F
!  22 Oct 2012 - R. Yantosca - Renamed to GIGC_Init_All
!  26 Oct 2012 - R. Yantosca - Now call Get_nSchm, nSchmBry to find out the
!                              number of strat chem species and Bry species
!  01 Nov 2012 - R. Yantosca - Now use LSCHEM from logical_mod.F
!  09 Nov 2012 - R. Yantosca - Now pass Input Options object for GIGC
!  26 Feb 2013 - R. Yantosca - Now pass Input_Opt to Init_GIGC_State_Chm
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES
!
    INTEGER :: nSchm, nSchmBry, N_TRACERS
    LOGICAL :: LSCHM

    !=======================================================================
    ! Copy fields from Input_Opt to local variables
    !=======================================================================
    
    ! Get # of tracers 
    N_TRACERS = Input_Opt%N_TRACERS

    !=======================================================================
    ! Initialize object for met fields
    !=======================================================================
    CALL Init_GIGC_State_Met( am_I_Root  = am_I_Root,   &
                              IM         = IIPAR,       &
                              JM         = JJPAR,       &
                              LM         = LLPAR,       &
                              State_Met  = State_Met,   &
                              RC         = RC          )

    ! Return upon error
    IF ( RC /= GIGC_SUCCESS ) RETURN

    !=======================================================================
    ! Initialize object for chemical state
    !=======================================================================

    ! Initialize chemistry state
    CALL Init_GIGC_State_Chm(  am_I_Root  = am_I_Root,  &  ! Root CPU (Y/N)?
                               IM         = IIPAR,      &  ! # of lons
                               JM         = JJPAR,      &  ! # of lats
                               LM         = LLPAR,      &  ! # of levels
                               nTracers   = N_TRACERS,  &  ! # of tracers
                               nBioMax    = NBIOMAX,    &  ! # biomass species
                               nSpecies   = IGAS,       &  ! # chemical species
                               nSchm      = nSchm,      &  ! # strat chem spec
                               nSchmBry   = nSchmBry,   &  ! # bromine species
                               Input_Opt  = Input_Opt,  &  ! Input Options
                               State_Chm  = State_Chm,  &  ! Chemistry State
                               RC         = RC         )   ! Success or failure
    
    ! Return upon error
    IF ( RC /= GIGC_SUCCESS ) RETURN

  END SUBROUTINE GIGC_Init_All
!EOC
END MODULE GIGC_Environment_Mod
