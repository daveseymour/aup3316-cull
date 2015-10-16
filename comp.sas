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

data final;
    merge milk am pm;
    by cow day;
    fat_day = (fat_am*am/100) + (fat_pm*pm/100);
    pro_day = (pro_am*am/100) + (pro_pm*pm/100);
    lac_day = (lac_am*am/100) + (lac_pm*pm/100);
    los_day = (los_am*am/100) + (los_pm*pm/100);

proc sort data = final;
    by tx day;

proc means data=final;
    var fat_day pro_day lac_day los_day;
    by tx day;
