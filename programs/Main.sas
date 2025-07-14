
proc datasets library=work kill;
run;
quit;
/*---------------------------------------------------------------------
  1. Macro Variable Set up
---------------------------------------------------------------------*/
%let pathn    =/home/u64270181/Clinical;  /* root pathname */
%let seed    = 1045;                      /* RNG seed for reproducibility */
%let nSubj   = 45;                        /* Number of subjects to simulate */
%let startDT = '01FEB2019'd;              /* Earliest possible start exposure date */
%let endDT   = '31DEC2019'd;              /* Latest possible start exposure date */

%*put _GLOBAL_;
/*---------------------------------------------------------------------
  2. Run Programs that Create Individual Datasets and SAS Transport Files
---------------------------------------------------------------------*/

%include "&pathn/Final_Code/dx.sas";*This program initially creates the devices used by the programs below;
%include "&pathn/Final_Code/di.sas";
%include "&pathn/Final_Code/do.sas";
%include "&pathn/Final_Code/du.sas";

