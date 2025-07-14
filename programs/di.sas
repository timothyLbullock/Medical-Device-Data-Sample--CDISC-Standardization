/*****************************************************************************************
  Device Identifiers (DI) Domain - CDISC SDTMIG for Medical Devices (v1.1)

  Purpose:
    The DI domain captures unique identifying attributes for each device unit used 
    in a study, such as device type, description, manufacturer, and model number.

  Structure:
    Each record corresponds to a specific identifying parameter (DIPARMCD) for a 
    single device unit (SPDEVID). The combination of STUDYID, SPDEVID, and DIPARMCD 
    ensures traceability across domains.

  Assumptions:
    - The WORK.DX dataset is available and includes SPDEVID values for all devices.
    - Devices are categorized into at least two types: RTCGM (real-time CGMs) and BGM (blood glucose meters).
    - All device metadata values are fabricated for testing and submission simulation purposes.

  Key Variables:
    STUDYID   : Study identifier (Required)
    DOMAIN    : Fixed as "DI"
    SPDEVID   : Sponsor-defined unique identifier for device (Required)
    DISEQ     : Sequence number for multiple attributes (Expected)
    DIPARMCD  : Short name of device parameter (Required)
    DIPARM    : Descriptive name of parameter (Required)
    DIVAL     : Value for the parameter (Required)

******************************************************************************************/

/*
=====================================================================
  1. Read in DX from the transport file and find unique devices
=====================================================================*/
libname dxin xport "&pathn/Data/dx_domain.xpt";

proc copy in=dxin out=work memtype=data;
  select DX;
run;

libname dxin clear;

proc sort data=work.DX(keep=STUDYID SPDEVID) out=devices nodupkey;
  by SPDEVID;
run;

data work.DI;
  length STUDYID DOMAIN SPDEVID $20
         DISEQ 8
         DIPARMCD $12
         DIPARM   $40
         DIVAL    $100;

  retain STUDYID DOMAIN DISEQ;
  set devices;

  DOMAIN  = "DI";
  STUDYID = "T001";  /* static for this example */
  DISEQ   = 1;       /* same across attributes */

  /* Determine device type based on SPDEVID prefix */
  if upcase(scan(SPDEVID,1,"-")) = "RTCGM" then do;
    /* rtCGM devices */
    DIPARMCD = "DEVTYPE";   DIPARM = "Device Type";                DIVAL = "Non-Invasive Continuous Glucose Monitors (CGMs)"; output;
    DIPARMCD = "SPDEVDSC";  DIPARM = "Sponsor Device Description"; DIVAL = "rtCGM";                                           output;
    DIPARMCD = "MANUF";     DIPARM = "Manufacturer";               DIVAL = "Gluctech";                                       output;
    DIPARMCD = "MODEL";     DIPARM = "Model Number";               DIVAL = "GLU233-1232.1";                                  output;
  end;

  else if upcase(scan(SPDEVID,1,"-")) = "BGM" then do;
    /* BGM devices */
    DIPARMCD = "DEVTYPE";   DIPARM = "Device Type";                DIVAL = "Self-monitoring meters";                         output;
    DIPARMCD = "SPDEVDSC";  DIPARM = "Sponsor Device Description"; DIVAL = "Blood Glucose Meter";                            output;
    DIPARMCD = "MANUF";     DIPARM = "Manufacturer";               DIVAL = "DiaTechnology";                                  output;
    DIPARMCD = "MODEL";     DIPARM = "Model Number";               DIVAL = "3433SMBG43333";                                  output;
  end;
run;
/*=====================================================================
  2. Create Metadata Datasets for define.xml
=====================================================================*/

data defds_di;
  length DATASET $8
         DOMAIN  $8
         LABEL   $40
         STRUCTUR $200
         PURPOSE $200;

  DATASET   = "DI";
  DOMAIN    = "DI";
  LABEL     = "Device Identifiers";
  STRUCTUR  = "One record per device per identifying parameter";
  PURPOSE   = "Defines device-specific attributes for traceability across domains";
  output;
run;

data dfvar_di;
  length Dataset $8 Variable $12 Label $50 Type $6 Role $15 Core $12 Length 8;
  Dataset = "DI";

  Variable="STUDYID";  Label="Study Identifier";         Type="Char"; Role="Identifier";  Core="Required";    Length=10; output;
  Variable="DOMAIN";   Label="Domain Abbreviation";      Type="Char"; Role="Identifier";  Core="Required";    Length=2;  output;
  Variable="SPDEVID";  Label="Sponsor Device Identifier";Type="Char"; Role="Identifier";  Core="Required";    Length=20; output;
  Variable="DISEQ";    Label="Sequence Number";          Type="Num";  Role="Identifier";  Core="Expected";    Length=. ; output;
  Variable="DIPARMCD"; Label="Device Parameter Code";    Type="Char"; Role="Topic";       Core="Required";    Length=12; output;
  Variable="DIPARM";   Label="Device Parameter";         Type="Char"; Role="Synonym";     Core="Required";    Length=40; output;
  Variable="DIVAL";    Label="Device Parameter Value";   Type="Char"; Role="Result";      Core="Required";    Length=100;output;
run;

/*---------------------------------------------------------------------
  3. Export DI and metadata datasets to SAS Transport files
---------------------------------------------------------------------*/
libname xptout xport "&pathn/Data/di_domain.xpt";
proc copy in=work out=xptout memtype=data;
  select DI;
run;
libname xptout clear;
libname xptout xport "&pathn/Data/di_defs.xpt";
proc copy in=work out=xptout memtype=data;
  select defds_di dfvar_di;
run;
libname xptout clear;
