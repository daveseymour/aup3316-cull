/* calculation of milk component yields */

options linesize=80;

/* Import milk yield data from Excel file */
proc import
    out=milk
    datafile='milk.xlsx'
    dbms=xlsx
    replace;
    sheet='total';
    getnames=yes;
run;

/* remove days with now component yield data */
data milk;
    set milk;
    if day < -1 then delete;
    if day > -1 and day < 9 then delete;
    if day = 14 then delete;
    drop fat protein lactose los;
run;

proc sort data = milk;
    by cow day;

/* Import component yield data from Excel file */
proc import
    out=comp
    datafile='components.xlsx'
    dbms=xlsx
    replace;
    getnames=yes;
run;

data am;
    set comp;
    if time ne 'am' then delete;
    if day = 14 then delete;
    fat_am = fat;
    pro_am = protein;
    lac_am = lactose;
    los_am = los;
    drop time fat protein lactose los;

proc sort;
    by cow day;

data pm;
    set comp;
    if time ne 'pm' then delete;
    if day = 14 then delete;
    fat_pm = fat;
    pro_pm = protein;
    lac_pm = lactose;
    los_pm = los;
    drop time fat protein lactose los;

proc sort;
    by cow day;

data total;
    merge milk am pm;
    by cow day;
    fat_day = (fat_am*am/100) + (fat_pm*pm/100);
    pro_day = (pro_am*am/100) + (pro_pm*pm/100);
    lac_day = (lac_am*am/100) + (lac_pm*pm/100);
    los_day = (los_am*am/100) + (los_pm*pm/100);
    fat_pct = (fat_day/my)*100;
    pro_pct = (pro_day/my)*100;
    lac_pct = (lac_day/my)*100;
    los_pct = (los_day/my)*100;

proc sort data = total;
    by tx day;

data pretrial;
    set total;
    if day ne -1 then delete;

proc means data=pretrial;
    title 'Pretrial';
    var fat_day pro_day lac_day los_day fat_pct pro_pct lac_pct los_pct;
    by tx;
    output out = pretrial;

data trial;
    set total;
    if day < 9 then delete;

proc means data = trial;
    title 'Trial';
    var fat_day pro_day lac_day los_day fat_pct pro_pct lac_pct los_pct;
    by tx;
    output out=trial;

data pretrial;
    set pretrial;
    prepost = 'pre';
    if _STAT_ = 'N' then delete;
    if _STAT_ = 'MIN' then delete;
    if _STAT_ = 'MAX' then delete;
    drop _TYPE_ _FREQ_;

data trial;
    set trial;
    prepost= 'post';
    if _STAT_ = 'N' then delete;
    if _STAT_ = 'MIN' then delete;
    if _STAT_ = 'MAX' then delete;
    drop _TYPE_ _FREQ_;

data final;
    set pretrial trial;

proc export
    data = final
    dbms = xlsx
    outfile = 'comps.xlsx'
    replace;

run;
