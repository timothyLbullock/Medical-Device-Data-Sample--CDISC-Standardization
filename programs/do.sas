/*****************************************************************************************
  Device Observations (DO) Domain - CDISC SDTMIG for Medical Devices (v1.1)

  Purpose:
    The DO domain is used to capture device‐related observations and properties
    measured or recorded for each device unit under study.

  Structure:
    Each record in DO corresponds to one device property or test result per
    device (SPDEVID). Related records for a device can be grouped together
    via DOGRPID or other identifiers.

  Variable-Level Metadata:

    STUDYID   Study Identifier                          Char    Identifier    Unique identifier for a study.                                  Req
    DOMAIN    Domain Abbreviation                       Char    Identifier    Two-character abbreviation for the domain (“DO”).                Req
    SPDEVID   Sponsor Device Identifier                 Char    Identifier    Sponsor-defined identifier for each device unit under study.    Req
    DOSEQ     Sequence Number                           Num     Identifier    Unique sequence for each device record within subject.           Req
    DOGRPID   Group ID                                  Char    Identifier    Ties together related records in a single device domain.        Perm
    DOREFID   Reference ID                              Char    Identifier    Internal or external reference identifier (e.g., scan code).    Perm
    DOSPID    Sponsor-Defined Identifier                Char    Identifier    Sponsor-defined reference number for the record.                 Perm
    DOTESTCD  Device Property Short Name                Char    Topic         Short name of the test/measurement (≤8 chars, no leading digit).Req
    DOTEST    Device Property Test Name                 Char    Synonym Qual. Verbatim name of the test (≤40 chars).              Req
    DOCAT     Category for Device In-Use                Char    Grouping Qual.Defines a category of related records (e.g., “DIMENSIONS”).Perm
    DOSCAT    Subcategory for Device In-Use             Char    Grouping Qual.Further categorization within DOCAT (e.g., “LENGTH”).Perm
    DOORRES   Result or Finding in Original Units       Char    Result Qual.  Result or value of the property as originally observed.   Exp
    DOORRESU  Original Units                            Char    Variable Qual.Units in which DOORRES was collected (e.g., “cm”). Exp

  Core:
    Req  = Required  Exp = Expected  Perm = Permissible

  CDISC Notes:
    • DOTESTCD cannot exceed 8 characters, start with a digit, or include special characters.
    • DOTEST cannot exceed 40 characters.
    • SPDEVID must be unique for each device unit under study.
*****************************************************************************************/


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
proc sort data=work.DX(keep=STUDYID DOMAIN SPDEVID)
          out=work.DX_RTCGM
          nodupkey;
  where upcase(scan(SPDEVID,1,'-')) = 'RTCGM';
  by SPDEVID;
run;

/*=====================================================================
  3. Build the DO domain – two records per RTCGM device
=====================================================================*/
data work.DO(keep=STUDYID DOMAIN SPDEVID 
                  DOSEQ DOTESTCD DOTEST DOORRES DOORRESU);
  length STUDYID  $10
         DOMAIN   $2
         SPDEVID  $20
         DOSEQ    8
         DOTESTCD $8
         DOTEST   $50
         DOORRES  $50
         DOORRESU $20;

  set work.DX_RTCGM;

  /* Set the DO domain constant */
  DOMAIN = 'DO';

  /* Record #1: Software Version */
  DOSEQ    = 1;
  DOTESTCD = 'SFTWRVER';
  DOTEST   = 'Software Version';
  DOORRES  = '3.2.6.11';
  DOORRESU = '';
  output;

  /* Record #2: Device Output Blinding Status */
  DOSEQ    = 2;
  DOTESTCD = 'DVOPBLST';
  DOTEST   = 'Device Output Blinding Status';
  DOORRES  = 'SUBJECT-BLINDED';
  DOORRESU = '';
  output;
run;

/*=====================================================================
  4. Create Metadata Datasets for define.xml
=====================================================================*/

data defds_do;
  length DATASET $8
         DOMAIN  $8
         LABEL   $40
         STRUCTUR $200
         PURPOSE $200;

  DATASET   = "DO";
  DOMAIN    = "DO";
  LABEL     = "Device Observations";
  STRUCTUR  = "One record per device property or test result per device unit";
  PURPOSE   = "Captures device-related measurements and recorded properties under study";
  output;
run;

data dfvar_do;
  length Dataset $8 Variable $12 Label $50 Type $6 Role $15 Core $12 Length 8;
  Dataset = "DO";

  Variable="STUDYID";  Label="Study Identifier";         Type="Char"; Role="Identifier";  Core="Required";    Length=10; output;
  Variable="DOMAIN";   Label="Domain Abbreviation";      Type="Char"; Role="Identifier";  Core="Required";    Length=2;  output;
  Variable="SPDEVID";  Label="Sponsor Device Identifier";Type="Char"; Role="Identifier";  Core="Required";    Length=20; output;
  Variable="DOSEQ";    Label="Sequence Number";          Type="Num";  Role="Identifier";  Core="Required";    Length=. ; output;

  Variable="DOTESTCD"; Label="Device Property Short Name";Type="Char";Role="Topic";       Core="Required";    Length=8;  output;
  Variable="DOTEST";   Label="Device Property Test Name"; Type="Char";Role="Synonym";     Core="Required";    Length=40; output;
  Variable="DOORRES";  Label="Original Result";           Type="Char";Role="Result";      Core="Expected";    Length=50; output;
  Variable="DOORRESU"; Label="Original Units";            Type="Char";Role="Variable";    Core="Expected";    Length=20; output;
run;


/*---------------------------------------------------------------------
  5. Export DO and metadata datasets to SAS Transport files
---------------------------------------------------------------------*/
libname xptout xport "&pathn/Data/do_domain.xpt";
proc copy in=work out=xptout memtype=data;
  select DO;
run;
libname xptout clear;
libname xptout xport "&pathn/Data/do_defs.xpt";
proc copy in=work out=xptout memtype=data;
  select defds_do dfvar_do;
run;
libname xptout clear;