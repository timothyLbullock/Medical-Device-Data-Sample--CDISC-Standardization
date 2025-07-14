/************************************************************************
  Create DU (Device Use) Domain for RTCGM Devices

  - Reads DX from the transport file dx_all.xpt  
  - Filters to SCREENING visit & RTCGM devices  
  - Builds two DU records per device  
  - DUDTC = screening date – 14 days ± up to 5 days, with random time  
************************************************************************/

/*=====================================================================
  1. Read in DX from the transport file
=====================================================================*/
libname dxin xport "&pathn/Data/dx_domain.xpt";

proc copy in=dxin out=work memtype=data;
  select DX;
run;

libname dxin clear;

/*=====================================================================
  2. Extract unique RTCGM devices
=====================================================================*/
data work.SCREEN;
  set work.DX;
  where upcase(substr(SPDEVID,1,5)) = 'RTCGM'
    and upcase(VISIT) = 'SCREENING';

  /* Create a character version of DXDTC for INPUT */
  DXDTC_char = put(DXDTC, yymmdd10.);
  keep STUDYID USUBJID SPDEVID DXDTC_char;
run;

/*=====================================================================
  3. Build the DU domain – two records per RTCGM device
=====================================================================*/
data work.DU;
  length STUDYID $10
         DOMAIN  $2
         USUBJID $20
         SPDEVID $20
         DUSEQ   8
         DUTESTCD $8
         DUTEST   $50
         DUTSTDTL $4
         DUORRES  8
         DUORRESU $10
         DUSTRESC $10
         DUSTRESN 8
         DUSTRESU $10;
  format DUDTC e8601dt16.;  /* ISO8601 'YYYY-MM-DDThh:mm' */

  /* Initialize RNG once */
  if _n_ = 1 then call streaminit(&seed);

  set work.SCREEN;

  /* Convert char date to numeric SAS date */
  scr_date = input(DXDTC_char, yymmdd10.);

  /* Compute random offset: –14 days ± up to 5 days */
  offset_days = -14 + rand('integer', -5, 5);
  dt_date     = scr_date + offset_days;

  /* Random time-of-day */
  hour   = rand('integer', 0, 23);
  minute = rand('integer', 0, 59);

  DUDTC = dhms(dt_date, hour, minute, 0);

  STUDYID = STUDYID;  /* carried from SCREEN */
  DOMAIN  = 'DU';

  /* Record 1: HIGH threshold */
  DUSEQ     = 1;
  DUTESTCD  = 'GLUCALTH';
  DUTEST    = 'Glucose Alert Threshold';
  DUTSTDTL  = 'HIGH';
  DUORRES   = 240;
  DUORRESU  = 'mg/dL';
  DUSTRESC  = '240';
  DUSTRESN  = 240;
  DUSTRESU  = 'mg/dL';
  output;

  /* Record 2: LOW threshold */
  DUSEQ     = 2;
  DUTSTDTL  = 'LOW';
  DUORRES   =  80;
  DUSTRESC  = '80';
  DUSTRESN  =  80;
  output;

  /* Drop interim variables */
  drop DXDTC_char scr_date offset_days dt_date hour minute;
run;

/*=====================================================================
  4. Create Metadata Datasets for define.xml
=====================================================================*/

data defds_du;
  length DATASET $8
         DOMAIN  $8
         LABEL   $40
         STRUCTUR $200
         PURPOSE $200;

  DATASET   = "DU";
  DOMAIN    = "DU";
  LABEL     = "Device Use";
  STRUCTUR  = "One record per device per test per subject";
  PURPOSE   = "Captures device use parameters such as alert thresholds at specific time points";
  output;
run;

data dfvar_du;
  length Dataset $8 Variable $12 Label $50 Type $6 Role $15 Core $12 Length 8;
  Dataset = "DU";

  Variable="STUDYID";   Label="Study Identifier";               Type="Char"; Role="Identifier"; Core="Required";    Length=10; output;
  Variable="DOMAIN";    Label="Domain Abbreviation";            Type="Char"; Role="Identifier"; Core="Required";    Length=2;  output;
  Variable="USUBJID";   Label="Unique Subject Identifier";      Type="Char"; Role="Identifier"; Core="Required";    Length=20; output;
  Variable="SPDEVID";   Label="Sponsor Device Identifier";      Type="Char"; Role="Identifier"; Core="Required";    Length=20; output;
  Variable="DUSEQ";     Label="Sequence Number";                Type="Num";  Role="Identifier"; Core="Required";    Length=. ; output;

  Variable="DUTESTCD";  Label="Short Name of Test";             Type="Char"; Role="Topic";      Core="Required";    Length=8;  output;
  Variable="DUTEST";    Label="Device Use Test Name";           Type="Char"; Role="Synonym";    Core="Required";    Length=50; output;
  Variable="DUTSTDTL";  Label="Test Detail";                    Type="Char"; Role="Variable";   Core="Permissible"; Length=4;  output;

  Variable="DUORRES";   Label="Original Result";                Type="Num";  Role="Result";     Core="Expected";    Length=. ; output;
  Variable="DUORRESU";  Label="Original Units";                 Type="Char"; Role="Variable";   Core="Expected";    Length=10; output;
  Variable="DUSTRESC";  Label="Standardized Result (Char)";     Type="Char"; Role="Result";     Core="Expected";    Length=10; output;
  Variable="DUSTRESN";  Label="Standardized Result (Num)";      Type="Num";  Role="Result";     Core="Expected";    Length=. ; output;
  Variable="DUSTRESU";  Label="Standardized Units";             Type="Char"; Role="Variable";   Core="Expected";    Length=10; output;
run;

/*---------------------------------------------------------------------
  5. Export DO and metadata datasets to SAS Transport files
---------------------------------------------------------------------*/
libname xptout xport "&pathn/Data/du_domain.xpt";
proc copy in=work out=xptout memtype=data;
  select DU;
run;
libname xptout clear;
libname xptout xport "&pathn/Data/du_defs.xpt";
proc copy in=work out=xptout memtype=data;
  select defds_du dfvar_du;
run;
libname xptout clear;