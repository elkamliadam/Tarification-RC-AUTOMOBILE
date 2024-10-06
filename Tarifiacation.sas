LIBNAME Tarif "C:\Users\user\OneDrive\Bureau\Tarification Non-Vie";
     RUN;
PROC IMPORT DATAFILE = "C:\Users\user\OneDrive\Bureau\Tarification Non-Vie\production.csv"
    DBMS = CSV
    OUT = TARIF.PROD REPLACE;
    DELIMITER = ";";
    GETNAMES = YES;
RUN;
 PROC PRINT DATA = TARIF.PROD(OBS=5);
        TITLE 'La base PRODUCTION';
    RUN;

  DATA TARIF.PROD;
	 	set TARIF.PROD(rename = (
	 	DNA = DATE_DE_NAISSANCE
	 	DMC = DATE_MISE_EN_CIRCULATION
	 	DOP = DATE_OBTENTION_PERMIS
	 	DPEF = DATE_PREMIER_EFFET
	 	));
	 RUN;

	 PROC MEANS DATA = TARIF.PROD
			NMISS;
	RUN;
	 PROC MEANS DATA = TARIF.PROD NMISS N NOPRINT;
	OUTPUT OUT = TARIF.Missing
	nmiss = /autoname;
    RUN;
    PROC TRANSPOSE DATA = TARIF.MISSING 
				OUT = TARIF.MISSING_TRANS;
    RUN; 
PROC SQL;
	create table TARIF.MISS as 
	select * ,
		COL1 / (select count(*) from TARIF.PROD)*100 as FREQ
	from TARIF.MISSING_TRANS;
    QUIT;
    /*Ce prochain bloque et pour la visualization de la table TARIF.MISS*/
    PROC PRINT DATA = tarif.MISS;
        title 'Valeurs manquante et fréquences';
    RUN;
	 PROC SQL;
	delete from TARIF.PROD
	where  DATE_OBTENTION_PERMIS < 0 OR DATE_OBTENTION_PERMIS IS NULL OR
			DATE_DE_NAISSANCE < 0 OR DATE_DE_NAISSANCE IS NULL OR
			DATE_PREMIER_EFFET < 0 OR DATE_PREMIER_EFFET IS NULL OR
			DATE_MISE_EN_CIRCULATION < 0 OR DATE_MISE_EN_CIRCULATION IS NULL OR
			DATE_MISE_EN_CIRCULATION < 0 OR DATE_MISE_EN_CIRCULATION IS NULL OR
			crm IS NULL OR
			exposition > 1 OR exposition <= 0;
QUIT;
  PROC SQL;
	delete from TARIF.PROD
        where  DATE_OBTENTION_PERMIS < 0 ;
    QUIT;

	 PROC SQL;
		  delete from TARIF.PROD
		  where  DATE_PREMIER_EFFET < 0 ;
		QUIT;
	PROC SQL;
	  delete from TARIF.PROD
		  where  DATE_MISE_EN_CIRCULATION < 0 OR DATE_MISE_EN_CIRCULATION IS NULL;
QUIT;
PROC SQL;
		delete from TARIF.PROD
		where  crm IS NULL or 
                exposition >1 or exposition <=0 or
                puissance_fiscale >100 or puissance_fiscale <0;
QUIT;
/*Creationd des variables*/
    data TARIF.PROD;
    set TARIF.PROD;
    if SEXE = "" then SEXE_missing = 1;
    else SEXE_missing = 0;
	IF COMBUSTION = "" THEN COM_MISSING = 1;
	ELSE COM_MISSING = 0;
run;
/*Calcul de la somme*/
	proc summary data=tarif.prod;
    var com_missing Sexe_missing;
    output out=work.sumC sum=;
    /*Affichage des resultats*/
run;
proc print data = sumC;
	run;
PROC SQL;
	delete from TARIF.prod
	where Sexe_missing = 1 ;
QUIT;
/*Conversion des types ey création des variables*/
    DATA TARIF.PROD ;
	SET TARIF.PROD;
	DATE_DE_NAISSANCE_CH = PUT(DATE_DE_NAISSANCE, 8.);
	DATE_MISE_EN_CIRCULATION_CH = PUT(DATE_MISE_EN_CIRCULATION, 8.);
	DATE_OBTENTION_PERMIS_CH = PUT(DATE_OBTENTION_PERMIS, 8.);
	DATE_PREMIER_EFFET_CH = PUT(DATE_PREMIER_EFFET, 8.);
    RUN;
/*Suppression des anciennes variables*/
    DATA TARIF.PROD(DROP = DATE_DE_NAISSANCE DATE_MISE_EN_CIRCULATION DATE_OBTENTION_PERMIS DATE_PREMIER_EFFET);
	SET TARIF.PROD;
    RUN;
 DATA TARIF.PROD;
		SET TARIF.PROD ;
  /*Extraction de l'année, mois et jours*/
		YEAR = SUBSTR(TRIM(LEFT(DATE_DE_NAISSANCE_CH)),1,4);
		MOIS = SUBSTR(TRIM(LEFT(DATE_DE_NAISSANCE_CH)),5,2);
		DAY = SUBSTR(TRIM(LEFT(DATE_DE_NAISSANCE_CH)),7,2);
  /* Conversion de date_de_naissance en format date*/
		DATE_DE_NAISSANCE = MDY(MOIS,DAY,YEAR);
		FORMAT DATE_DE_NAISSANCE YYMMDD10.;
		RUN;
  /*Suppression de l'ancienne variable*/
		DATA TARIF.PROD (DROP = YEAR MOIS DAY DATE_DE_NAISSANCE_CH);
		SET TARIF.PROD;
    RUN;
	DATA TARIF.PROD;
		SET TARIF.PROD;
		EXERCICE = MDY(1,1,EXERCICE);
		FORMAT EXERCICE YYMMDD10.; /*On transforme exercice à la même format de date que les autres dates YYMMDD10.*/
    RUN;
	DATA TARIF.PROD;
	SET TARIF.PROD;
		
		AGE_CONDUCTEUR = INTCK('YEAR', DATE_DE_NAISSANCE,EXERCICE);
		AGE_VEHICULE = INTCK('YEAR', DATE_MISE_EN_CIRCULATION,EXERCICE);
		ANCIENNETE_PERMIS = INTCK('YEAR', DATE_OBTENTION_PERMIS, EXERCICE);
		ANCIENNETE_POLICE = INTCK('YEAR', DATE_PREMIER_EFFET, EXERCICE);
run;
proc sql;
		create table TARIF.test as
		select numero_police,exercice, count(*) as repetition from TARIF.PROD
		group by numero_police,exercice
		order by repetition desc;
    QUIT;
	PROC SORT DATA = TARIF.PROD NODUPKEY OUT = TARIF.PROD;
		  BY NUMERO_POLICE EXERCICE ;
		RUN;
		PROC SQL;
		DELETE FROM TARIF.PROD
		WHERE AGE_CONDUCTEUR <18 OR AGE_CONDUCTEUR >100 OR AGE_CONDUCTEUR IS NULL;
		RUN;
		proc sql ;
		DELETE FROM TARIF.PROD
		WHERE AGE_VEHICULE <0 OR AGE_VEHICULE>100 OR AGE_VEHICULE IS NULL ;
		RUN;
		
		PROC SQL ;
		DELETE FROM TARIF.PROD
		WHERE ANCIENNETE_PERMIS <0 OR ANCIENNETE_PERMIS>80 OR ANCIENNETE_PERMIS IS NULL;
		RUN;
		
		PROC SQL ;
		DELETE FROM TARIF.PROD 
		WHERE ANCIENNETE_POLICE <0 OR ANCIENNETE_POLICE IS NULL;
		RUN;
		/*Creation de la variable*/
    PROC SQL;
	CREATE TABLE TARIF.PROD1 AS
	SELECT *,
	AGE_CONDUCTEUR - ANCIENNETE_PERMIS AS DIFF
	FROM TARIF.PROD;
    QUIT;
    /*Statistique descriptive sur la variable DIFF*/
    PROC UNIVARIATE DATA = TARIF.PROD1;
	VAR DIFF;
    RUN;
	 PROC SQL;
        DELETE FROM TARIF.PROD
        WHERE DIFF < 18;
    QUIT;
	 PROC IMPORT DATAFILE = "C:\Users\user\OneDrive\Bureau\Tarification Non-Vie\sinistre.csv"
		DBMS = CSV 
		OUT = TARIF.SIN REPLACE;
		DELIMITER = ";";
		GETNAMES = YES;
   RUN;
   		PROC SQL ;
		  DELETE FROM TARIF.SIN
		  WHERE CHARGE <0;
		RUN;
		  proc sql;
 	create table TARIF.SIN as
	select police ,exercice, count(*) as nombre , sum(CHARGE) as somme
	FROM TARIF.SIN
	GROUP BY EXERCICE,POLICE;
    QUIT;
	 PROC MEANS DATA = TARIF.SIN 
	NMISS;
    RUN;
	 DATA TARIF.PROD (DROP =  sexe_missing DIFF com_missing DATE_DE_NAISSANCE DATE_OBTENTION_PERMIS DATE_MISE_EN_CIRCULATION            
            DATE_PREMIER_EFFET);
	SET TARIF.PROD;
 RUN;
  PROC SQL ;
	CREATE TABLE TARIF.DATA AS 
	SELECT P.*, S.*
	FROM TARIF.PROD AS P
	LEFT JOIN TARIF.SIN AS S
	ON P.NUMERO_POLICE = S.POLICE;
	ALTER TABLE TARIF.DATA DROP VAR1;
	UPDATE TARIF.DATA 
		SET SOMME=0, NOMBRE=0
		WHERE SOMME = .; 
    QUIT;
	 proc sql;
	delete from TARIF.DATA
	where somme >66900.0 ;
quit;
    PROC SQL;
		ALTER TABLE TARIF.DATA ADD FREQUENCE FLOAT(4);
		ALTER TABLE TARIF.DATA ADD SEVERITE FLOAT (4);
		
		UPDATE TARIF.DATA 
		SET FREQUENCE = NOMBRE / EXPOSITION,
		SEVERITE = SOMME / NOMBRE ;
		UPDATE TARIF.DATA
		SET SEVERITE = 0 
		WHERE SEVERITE = .;
    QUIT;
	 PROC SGPLOT DATA = TARIF.DATA; 
	VBAR  SEXE /STAT = PERCENT 
	FILLATTRS = (COLOR = CX4682B4);
RUN;
PROC SGPLOT DATA = TARIF.DATA; 
	VBAR  PUISSANCE_FISCALE /STAT = PERCENT 
	FILLATTRS = (COLOR = CX4682B4);
RUN;
PROC SGPLOT DATA = TARIF.DATA; 
	VBAR  COMBUSTION /STAT = PERCENT 
	FILLATTRS = (COLOR = CX4682B4);
RUN;
PROC SGPLOT DATA = TARIF.DATA; 
	HISTOGRAM  AGE_VEHICULE / 
	FILLATTRS = (COLOR = CX4682B4);
RUN;
PROC SGPLOT DATA = TARIF.DATA; 
	VBAR  AGE_VEHICULE /STAT = PERCENT 
	FILLATTRS = (COLOR = CX4682B4);
RUN;
PROC SGPLOT DATA = TARIF.DATA; 
	VBAR  NOMBRE /STAT = PERCENT 	
	FILLATTRS = (COLOR = CX4682B4);
RUN;
PROC SGPLOT DATA = TARIF.DATA; 
	histogram  somme /
	FILLATTRS = (COLOR = CX4682B4);
RUN;
    PROC SORT DATA = TARIF.DATA OUT = TARIF.DATA2;
BY NOMBRE;
RUN;
proc surveyselect data=tarif.data2 rate=0.8 outall out=TARIF.DATA3 seed=1234;
strata NOMBRE;
run;
data TARIF.DATA_train TARIF.DATA_test; 
set TARIF.DATA3; 
if selected =1 then output TARIF.DATA_train; 
else output TARIF.DATA_test; 
drop selected;
run;
    proc freq data=tarif.DATA_train;
table NOMBRE;
run;

proc freq data=TARIF.DATA_test;
table NOMBRE;
run;
    PROC SQL ;
	alter table TARIF.DATA ADD LOGEXPO FLOAT(4);
	UPDATE TARIF.DATA SET LOGEXPO = log(EXPOSITION);
	QUIT;
 PROC GENMOD DATA = TARIF.DATA_train;
 		CLASS SEXE COMBUSTION  ;
		MODEL NOMBRE = SEXE COMBUSTION PUISSANCE_FISCALE AGE_VEHICULE AGE_CONDUCTEUR ANCIENNETE_PERMIS ANCIENNETE_POLICE PUISSANCE_FISCALE CRM/
		DIST = POISSON LINK = LOG OFFSET = LOGEXPO;
		TITLE ' POISSON1';
		OUTPUT out = TARIF.P1 predicted = nombre_predi;
        STORE TARIF.P1;
RUN;
proc corr data=TARIF.DATA outp=TARIF.corr_matrix ;
    var PUISSANCE_FISCALE AGE_VEHICULE AGE_CONDUCTEUR ANCIENNETE_POLICE ANCIENNETE_PERMIS CRM; 
run;
 PROC GENMOD DATA = TARIF.DATA_train ;
 		CLASS SEXE COMBUSTION  ;
		MODEL NOMBRE = SEXE COMBUSTION PUISSANCE_FISCALE AGE_VEHICULE AGE_CONDUCTEUR ANCIENNETE_POLICE*CRM ANCIENNETE_PERMIS /
		DIST = POISSON LINK = LOG OFFSET = LOGEXPO;
		TITLE ' POISSON2';
		OUTPUT OUT = TARIF.P2 predicted=predicted;
RUN;
data TARIF.DATA_TRAIN_G;
    set TARIF.DATA_TRAIN;
    
    if age_conducteur >= 18 AND  age_conducteur <30 then age_group = '[18-30[';
    else if age_conducteur >= 30 and age_conducteur < 80 then age_group = '[30-80[';
    else  age_group = '>+80';
run;
 PROC GENMOD DATA = TARIF.DATA_train_g plots = all;
 		CLASS SEXE COMBUSTION age_group    ;
		MODEL NOMBRE = SEXE COMBUSTION PUISSANCE_FISCALE anciennete_permis anciennete_police age_vehicule age_group CRM /
		DIST = POISSON LINK = LOG OFFSET = LOGEXPO;
		TITLE ' POISSON3';
		OUTPUT OUT = TARIF.P3 predicted=predicted;
    RUN;
	 proc genmod data=TARIF.DATA_TRAIN plots = all;
        Class SEXE combustion  ;
         Model nombre = SEXE COMBUSTION AGE_CONDUCTEUR anciennete_police*CRM PUISSANCE_FISCALE AGE_VEHICULE ANCIENNETE_PERMIS PUISSANCE_FISCALE  /
         dist = zip link = log offset=logexpo ;
        zeromodel / link = logit ;
        title "ZIP2 ";
        ods output modelfit = zip2;
     run;
	  proc genmod data=Tarif.data_train ;
        class Combustion SEXE;
        model nombre = puissance_fiscale Combustion anciennete_police*CRM  age_conducteur age_vehicule  SEXE anciennete_permis 
              / dist=negbin link=log;
        output out=TARIF.NB1 pred=pred_nombre;
    run;
	 proc genmod data=TARIF.DATA_TRAIN plots = all;
 Class SEXE combustion  ;
 Model nombre = SEXE COMBUSTION AGE_CONDUCTEUR  AGE_VEHICULE  ANCIENNETE_PERMIS PUISSANCE_FISCALE anciennete_police*CRM /
 dist = ziNB link = log offset=logexpo ;
 zeromodel / link = logit ;
 title "ZINB ";
 ods output modelfit = zinb;
 run;
 /*Création des variables ,calcul des résidus qu'on stock dans la table DATA_TEST_p2 */
  DATA TARIF.DATA_TEST_P2;
 	SET TARIF.DATA_TEST;
	LN = -0.9279+0.1720*(SEXE ='F')-0.0975*(COMBUSTION='E')+0.0151*PUISSANCE_FISCALE-0.0533*AGE_VEHICULE-0.0124*AGE_CONDUCTEUR+0.0109*ANCIENNETE_PERMIS
 +0.0456*ANCIENNETE_POLICE*CRM;
	EXP = EXP(LN);
	BIN = -1.6054+0.2659*(SEXE ='F')-0.0908*(COMBUSTION='E')+0.0086*
 PUISSANCE_FISCALE-0.0577*AGE_VEHICULE-0.0112*AGE_CONDUCTEUR+0.0170*ANCIENNETE_PERMIS+0.0831*ANCIENNETE_POLICE*CRM;
	BINN = EXP(BIN);
	RES_pois = ABS(EXP-nombre);
	RES_binn = ABS(BINN-nombre);
RUN;
/*Pour tracer le graphe des résidus*/
proc sgplot data=tarif.data_test_p2;
    scatter x=res_pois y=res_binn / markerattrs=(symbol=circlefilled);
    lineparm x=0 y=0 slope=1 / lineattrs=(color=red);
    xaxis label="Résidus du modèle de Poisson";
    yaxis label="Résidus du modèle Binomial Négative";
    title "Comparaison des résidus";
run;
    
 proc genmod data=TARIF.data_TRAIN;
 Class sexe  CombuStion ;
 Model severitE = sexe  CombUStion PUISSANCE_FISCALE AGE_VEHICULE anciennete_police ANCIENNETE_PERMIS  age_CONDUCTEUR CRM /
 dist = gamma link = log  ;
 ods output modelfit = Gam1;
 run;
   data TARIF.DATA_TRAIN;
    set TARIF.DATA_TRAIN;
    transformed_PF= log(PUISSANCE_FISCALE);
run;

  proc genmod data=TARIF.DATA_TRAIN plots = all ;
class  sexe combustion;
model Cout_moyen=  combustion sexe AGE_VEHICULE  AGE_CONDUCTEUR 
 anciennete_permis  
 transformed_pf anciennete_police*CRM /
dist =gamma link=log  ;
title'Ajustement par loi de GAMMA';
ods output modelfit=Gam;
output out=tarif.G6 pred=predicted_v;
run;
 data TARIF.DATA_TRAIN_svpf;
    set TARIF.DATA_TRAIN;
    
    /* Conditional logic to create age_group variable */
    if puissance_fiscale < 8    then PF_group = '<8';
	else if puissance_fiscale >= 8 and puissance_fiscale < 10 then pf_group = '[8-10[';
	else if puissance_fiscale >= 10 and puissance_fiscale < 14 then pf_group= '[10-14['.
    else  PF_group = '>=14';
run;
    proc genmod data=TARIF.data_TRAIN_svpf;
 Class sexe  CombuStion pf_group ;
 Model severitE = sexe  CombUStion pf_group AGE_VEHICULE anciennete_police ANCIENNETE_PERMIS*age_CONDUCTEUR CRM /
 dist = gamma link = log  ;
 ods output modelfit = Gam1;
 run;
  proc genmod data=TARIF.DATA_TRAIN plots = all;
    class SEXE COMBUSTION;
    model COUT_MOYEN = sexe combustion AGE_VEHICULE AGE_CONDUCTEUR anciennete_police ANCIENNETE_PERMIS PUISSANCE_FISCALE CRM  / dist=normal link=log;
    output out=TARIF.LN1 p=predicted PRED=PREDICTED_V;
run;
 DATA TARIF.DATA_Test;
 	SET TARIF.DATA_test;
	
		BIN = -1.6054+0.2659*(SEXE ='F')-0.0908*(COMBUSTION='E')+0.0086*PUISSANCE_FISCALE-0.0577*AGE_VEHICULE-0.0112*AGE_CONDUCTEUR+0.0170*ANCIENNETE_PERMIS+0.0831*ANCIENNETE_POLICE*CRM;

	frequence_predite = EXP(BIN)/ exposition;
	SEV =9.7295-0.1587*(SEXE = 'F')+0.0185*age_vehicule-0.0077*anciennete_police*CRM-0.0058*anciennete_permis+0.0033*age_conducteur-0.0058 transformed_pf;
	Severite_predite = EXP(sev);
	PRIME_predite = Severite_predite*frequence_predite;
	Res = abs(somme- Prime_predite);
        Res2 = abs(prime_acquise-prime_predite);
RUN;
 proc sgplot data=tarif.data_test;
    scatter x=somme y=Res/ markerattrs=(symbol=circlefilled);
    xaxis label="Charge des sinistres";
    yaxis label="Résidus";
    title "Résidus de la prime";
run;
     proc sql;
CREATE TABLE tarif.resume(
 nombre_total INT ,
 nombre_model INT
 );
 INSERT INTO tarif.resume (nombre_total, nombre_model) VALUES
 (0, 0);
 UPDATE tarif.resume set
 nombre_total = (select sum(nombre) from tarif.data_test),
 nombre_model = (select sum(frequence_predite*exposition) from tarif.data_test);

 quit;
 proc print data = tarif.resume;
 run;
   proc sql;
 CREATE TABLE tarif.cot (cot float(4));
 INSERT INTO cot (cot) VALUES (0);
 UPDATE Tarif.cot set
 cot = (select mean(somme)*count(*) from tarif.data where somme >66900 )/(select count(*) from tarif.data);
 quit;


