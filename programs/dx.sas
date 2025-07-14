/*****************************************************************************************
   Device Exposure (DX) Domain - CDISC SDTMIG for Medical Devices (v1.1)

   Purpose:
   The DX domain is used to record details of a subject's exposure to a medical device or 
   the output generated from that device. This includes treatments administered or outputs 
   delivered via medical devices over time.

   Structure:
   Each record in the DX domain corresponds to a unique exposure event per subject and per 
   device identifier (SPDEVID). Exposure is tracked across visits and time windows using 
   standardized variables.

   Key Variables:
   - STUDYID  (Req): Unique identifier for the clinical study.
   - DOMAIN   (Req): Abbreviation “DX” for Device Exposure.
   - USUBJID  (Req): Identifier that uniquely tags each subject across all datasets.
   - SPDEVID  (Req): Sponsor-defined device identifier, unique for each tracked device unit.
   - DXSEQ    (Req): Numeric sequence to ensure uniqueness of exposure records.
   - DXTRT    (Req): Name of the device or output administered.
   - DXCAT    (Perm): Category of device exposure.
   - VISITNUM (Perm): Visit sequence number.
   - VISIT    (Perm): Visit name.
   - DXDTC    (Exp): Date/time of device exposure.
   - DXSTTPT  (Perm): Descriptive reference time point for exposure start.
   - DXENTPT  (Perm): Descriptive reference time point for exposure end.

   Core Requirements:
   - Required (Req): Must be present for submission compliance.
   - Expected (Exp): Recommended for regulatory clarity.
   - Permissible (Perm): Optional but useful when applicable.

   Role in SDTM:
   The DX domain enables consistent documentation of device exposure throughout the clinical 
   trial lifecycle. It supports traceability with device identifiers (DI), timing domains, 
   and allows integration with other clinical observations (e.g., adverse events, lab results).
******************************************************************************************/

/*---------------------------------------------------------------------
  1. Generate DX Domain, Dropping Interim Variables
---------------------------------------------------------------------*/
data work.DX(
    drop = subj base_date ts_offset i nR nB
           seed_ds seed_ds2
    keep = STUDYID DOMAIN USUBJID SPDEVID DXSEQ DXTRT DXCAT
           VISITNUM VISIT DXDTC DXSTTPT DXENTPT
);
  length STUDYID $4 DOMAIN $2 USUBJID $4 SPDEVID $20 DXSEQ 8 DXTRT $5 DXCAT $15 VISITNUM 8 VISIT $20 DXDTC 8;
  format DXDTC    yymmdd10.
         DXSTTPT  yymmdd10.
         DXENTPT  yymmdd10.;

  /* 1. Constants & ID pools */
  retain STUDYID DOMAIN DXCAT nR nB;
  array idR[250] _temporary_;
  array idB[250] _temporary_;

  STUDYID = "T001";
  DOMAIN  = "DX";
  DXCAT   = "SUBJECT DEVICES";

  /* load macro seed into data variables */
  seed_ds  = &seed;         /* for rtCGM */
  seed_ds2 = &seed + 123;   /* for BGM */

  /* init counters */
  nR = 0; 
  nB = 0;

  /* fill pools 1–250 */
  do i = 1 to 250;
    idR[i] = i;
    idB[i] = i;
  end;

  /* shuffle pools using data-level seeds */
  call streaminit(seed_ds);
  call ranperm(seed_ds,  of idR[*]);
  call ranperm(seed_ds2, of idB[*]);

  /* init sequence */
  DXSEQ = 0;

  /* 2. Subject & Visit loops */
  do subj = 1 to &nSubj;
    USUBJID = put(subj, z4.);

    if mod(subj,2)=1 then do;
      nR + 1;
      SPDEVID = cats("RTCGM-", put(idR[nR], z4.));
      DXTRT   = "rtCGM";
    end;
    else do;
      nB + 1;
      SPDEVID = cats("BGM-", put(idB[nB], z4.));
      DXTRT   = "Blood Glucose Meter";
    end;

    ts_offset = rand("Uniform") * (&endDT - &startDT);
    base_date = &startDT + ts_offset;

  do VISITNUM = 1 to 13;

    /* Assign VISIT name based on VISITNUM */
    select;
      when (VISITNUM = 1)     VISIT = "SCREENING";
      when (VISITNUM = 2)     VISIT = "START OF STUDY";
      when (VISITNUM = 13)    VISIT = "END OF STUDY";
      otherwise               VISIT = cats("VISIT ", put(VISITNUM-1, best.));
    end;

    ts_offset = rand("Normal", 0, 4);
    DXDTC     = base_date + (VISITNUM-1)*30 + ts_offset;
    DXSTTPT   = base_date;
    DXENTPT   = DXDTC;

    DXSEQ + 1;
    output;
  end;
 end;
run;
/*---------------------------------------------------------------------
  2. Metadata for define.xml
---------------------------------------------------------------------*/
/* Dataset‐level metadata */
data defds_dx;
  length DATASET $8
         DOMAIN  $8
         LABEL   $40
         STRUCTUR $200    /* 8-char name to comply with transport format */
         PURPOSE $200;

  DATASET   = "DX";
  DOMAIN    = "DX";
  LABEL     = "Device Exposure";
  STRUCTUR  = "One record per subject per device per visit";
  PURPOSE   = "Tracks subject exposure to medical devices";
  output;
run;

/* Variable‐level metadata */
data dfvar_dx;
  length Dataset $8 Variable $12 Label $50 Type $6 Role $15 Core $12 Length 8;
  Dataset = "DX";

  /* Required identifiers */
  Variable="STUDYID"; Label="Study Identifier";        Type="Char"; Role="Identifier"; Core="Required"; Length=10; output;
  Variable="DOMAIN";  Label="Domain Abbreviation";    Type="Char"; Role="Identifier"; Core="Required"; Length=2;  output;
  Variable="USUBJID"; Label="Unique Subject Identifier";Type="Char";Role="Identifier"; Core="Required"; Length=20; output;
  Variable="SPDEVID"; Label="Sponsor Device Identifier";Type="Char";Role="Identifier"; Core="Required"; Length=20; output;
  Variable="DXSEQ";   Label="Sequence Number";        Type="Num";  Role="Identifier"; Core="Required"; Length=. ; output;

  /* Topic */
  Variable="DXTRT";   Label="Name of Device Exposure";Type="Char"; Role="Topic";      Core="Required"; Length=200; output;

  /* Grouping */
  Variable="DXCAT";   Label="Category for Device Exposure";Type="Char";Role="Grouping";Core="Permissible";Length=40; output;

  /* Timing */
  Variable="VISITNUM";Label="Visit Number";            Type="Num";  Role="Timing";     Core="Permissible";Length=. ; output;
  Variable="VISIT";   Label="Visit Name";              Type="Char"; Role="Timing";     Core="Permissible";Length=40; output;
  Variable="DXDTC";   Label="Device Exposure Date";    Type="Char"; Role="Timing";     Core="Expected";   Length=10; output;
  Variable="DXSTTPT"; Label="Start Reference Time Point";Type="Char";Role="Timing";   Core="Permissible";Length=10; output;
  Variable="DXENTPT"; Label="End Reference Time Point";Type="Char";Role="Timing";     Core="Permissible";Length=10; output;
run;

/*---------------------------------------------------------------------
  3. Export DX, defds_dx, dfvar_dx to SAS Transport files
---------------------------------------------------------------------*/
libname xptout xport "&pathn/Data/dx_domain.xpt";
proc copy in=work out=xptout memtype=data;
  select DX;
run;
libname xptout clear;
libname xptout xport "&pathn/Data/dx_defs.xpt";
proc copy in=work out=xptout memtype=data;
  select defds_dx dfvar_dx;
run;
libname xptout clear;