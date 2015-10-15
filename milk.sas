options linesize=80;

proc import /* Import data from Excel file */
    out=milk
    datafile='milk.xlsx'
    dbms=xlsx
    replace;
    sheet='total';
    getnames=yes;
run;

proc sort;
    by cow;

proc import
    out=cowcards
    datafile='cowcards.xlsx'
    dbms=xlsx
    replace;
    getnames=yes;
run;

proc sort;
    by cow;

data all; /* merge two datasets */
    merge milk cowcards;
    by cow;
    if cow = 4217 or cow = 4112 then delete; /* dropped from trial */
    if block > 4 then delete;

data pretrial trial;
    set all;
    if day < 0 then output pretrial;
        else output trial;

run;

proc means data = pretrial noprint; /* generate pretrial average my for covariate */
    var my;
    by cow;
    output out=covmy;
run;

proc sort data = milk;
    by day tx;
run;

proc means data = milk ; /* generate daily mean my by tx */
    var my;
    by day tx;
    output out=avmy;

data avmy;
    set avmy;
    if _STAT_ ne "MEAN" then delete;
    avmy = my;
    drop my _TYPE_ _FREQ_ _STAT_;

proc sort data = avmy;
    by tx day;
run;

data covmy;
    set covmy;
    if _STAT_ ne "MEAN" then delete;
    amy = my;
    drop my _TYPE_ _FREQ_ _STAT_;

data analysis;
    merge trial covmy;
    by cow;

proc mixed covtest data = analysis;
    class tx;
    model my = tx amy;
    random block parity dim;

run;

proc export
    data = avmy
    dbms = xlsx
    outfile = 'avmy.xlsx'
    replace;
run;
