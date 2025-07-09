/************************************************************************
  Create DU (Device Use) Domain for RTCGM Devices

  - Reads DX from the transport file dx_all.xpt  
  - Filters to SCREENING visit & RTCGM devices  
  - Builds two DU records per device  
  - DUDTC = screening date – 14 days ± up to 5 days, with random time  
************************************************************************/

/* 1. Read in DX from the transport file */
libname dxin xport '/home/u64270181/Clinical/Data/dx_all.xpt';

proc copy in=dxin out=work memtype=data;
  select DX;
run;

libname dxin clear;

/* 2. Extract only RTCGM devices at SCREENING visit */
data work.SCREEN;
  set work.DX;
  where upcase(substr(SPDEVID,1,5)) = 'RTCGM'
    and upcase(VISIT) = 'SCREENING';

  /* Create a character version of DXDTC for INPUT */
  DXDTC_char = put(DXDTC, yymmdd10.);
  keep STUDYID USUBJID SPDEVID DXDTC_char;
run;

/* 3. Build DU domain */
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