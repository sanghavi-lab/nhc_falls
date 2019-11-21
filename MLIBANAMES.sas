*MedPAR File Libnames;
libname mpar '\\prfs.cri.uchicago.edu\konetzka-lab\Outputdata\Medpar'; *<----Medpar raw datasets directory for year 2011 to 2015;

*MDS File Libnames;
libname mdsout '\\prfs.cri.uchicago.edu\sanghavi-lab\Pan\NH\datasets\sas\mds_analysis\MMDS3'; *<----MDS xwalked yearly files directory after running MMDS3;
libname mdsfac '\\prfs.cri.uchicago.edu\konetzka-lab\Outputdata\MDS'; *MDS facility file;
libname mdsxwalk '\\prfs.cri.uchicago.edu\sanghavi-lab\Pan\NH\datasets\sas\mds_xwalk'; *<----MDS xwalked yearly files directory;
libname mds3date '\\prfs.cri.uchicago.edu\sanghavi-lab\Pan\NH\datasets\sas\mds_analysis\MMDS3DATES';*<----MDS files with los;
libname mdsstar '\\prfs.cri.uchicago.edu\konetzka-lab\Data\5stars\NHCRatings\SAS';*<----MDS star rating files;

*OSCAR&CAPSER Libnames;
libname capin '\\prfs.cri.uchicago.edu\konetzka-lab\Data\CASPER\CASPER data files\SAS';*<---CASPER Files;
libname ltc '\\prfs.cri.uchicago.edu\konetzka-lab\Outputdata\HS' ;*<---Formatted LTCfocus data;

*Analysis Output Lib'names;
libname nhout '\\prfs.cri.uchicago.edu\sanghavi-lab\Pan\NH\datasets\sas\final\output10042018';*<--- output datasets;

*Log/List Options *;
options pagesize=1500 linesize=240 replace mprint symbolgen spool validvarname=upcase 
        sasautos=macro mautosource nocenter noovp orientation=landscape mergenoby=error nofmterr;


