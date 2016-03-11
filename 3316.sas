options linesize = 80;

title 'Effects of Energy Restriction of Milk Protein Synthesis';

proc import
    out = cards
    datafile = '3316_sas.xlsx'
    dbms = xlsx
    replace;
    getnames = yes;
    sheet = 'cards';
run;

proc import
    out = milk
    datafile = '3316_sas.xlsx'
    dbms = xlsx
    replace;
    getnames = yes;
    sheet = 'milk';
run;

data milk;
    set milk;
    dmy = my_am + my_pm;

/* milk composition */

data pre;
    set milk;
    if day ne -1 then delete;

data post;
    set milk;
    if day < 9 or day > 13 then delete;

data comp;
    set pre post;
    fat_day = (fat_am*my_am/100) + (fat_pm*my_pm/100);
    pro_day = (pro_am*my_am/100) + (pro_pm*my_pm/100);
    lac_day = (lac_am*my_am/100) + (lac_pm*my_pm/100);
    los_day = (los_am*my_am/100) + (los_pm*my_pm/100);
    fat_pct = (fat_day/dmy)*100;
    pro_pct = (pro_day/dmy)*100;
    lac_pct = (lac_day/dmy)*100;
    los_pct = (los_day/dmy)*100;

proc sort data=comp;
    by tx;

proc means data = comp (where = (day = -1)) noprint;
    title2 'Pre-Trial Milk Composition';
    var fat_day pro_day lac_day los_day fat_pct pro_pct lac_pct los_pct;
    by tx;
    output out = pre_comp
        mean = fat_mu pro_mu lac_mu los_mu fat_pct_mu pro_pct_mu lac_pct_mu
            los_pct_mu
        std = fat_se pro_se lac_se los_se fat_pct_se pro_pct_se lac_pct_se
            los_pct_se;

proc means data = comp (where = (day ne -1)) noprint;
    title2 'Trial Milk Composition';
    var fat_day pro_day lac_day los_day fat_pct pro_pct lac_pct los_pct;
    by tx;
    output out = post_comp
        mean = fat_mu pro_mu lac_mu los_mu fat_pct_mu pro_pct_mu lac_pct_mu
            los_pct_mu
        std = fat_se pro_se lac_se los_se fat_pct_se pro_pct_se lac_pct_se
            los_pct_se;

data pre_comp;
    set pre_comp;
    period = 'pre';

data post_comp;
    set post_comp;
    period = 'pos';

data comp_means;
    set pre_comp post_comp;
    drop _TYPE_ _FREQ_;

proc export
    data = comp_means
    dbms = xlsx
    outfile = '3316_sas_out.xlsx'
    replace;
    sheet = 'comp';
run;

/* milk yield */

proc sort data=milk;
    by day;

/* the 'nway' option suppresses the computation of daily mean across class (i.e.
    average dmy across treatments) */

proc means data = milk nway noprint missing;
    title2 'Average Daily Milk Yield';
    class tx;
    by day;
    var dmy;
    output out=dmy_means mean=dmy_mu std=dmy_se;

data dmy_means;
    set dmy_means;
    drop _TYPE_ _FREQ_;

proc sort data=dmy_means;
    by tx day;

proc export
    data = dmy_means
    outfile = '3316_sas_out.xlsx'
    dbms = xlsx
    replace;
    sheet = 'dmy';
run;

proc sort data = milk;
    by cow;

proc sort data = cards;
    by cow;

data mixed;
    merge cards milk;
    by cow;
    if drop = 'yes' then delete;
    if day < -7 then delete;

proc means data=mixed(where=(day < 0)) noprint;
    var dmy;
    by cow;
    output out=cov_mixed mean=cov_dmy;

data mixed;
    merge mixed cov_mixed;
    by cow;
    drop _TYPE_ _FREQ_ start biopsy blood slaughter drop;

proc mixed covtest data = mixed(where=(day <= 0));
    class tx;
    model dmy = tx cov_dmy;
    random block parity dim;
    lsmeans tx;
run;
