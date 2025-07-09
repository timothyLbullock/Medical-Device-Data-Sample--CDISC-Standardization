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
libname dxin xport '/home/u64270181/Clinical/Data/dx_all.xpt';

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