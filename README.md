# ciumbia
Creazione file .xml con dati meteo puntuali per tutti i comuni lombardi. 

## Cos'è Ciumbia?

Il processo CIUMBIA ha lo scopo di estrarre dall'output dei modelli **ECMWF** e **COSMO5M** (_in passato COSMOI7_) i valori dei principali parametri meteorologici in corrispondenza delle coordinate dei Comuni della Lombardia e metterli a disposizione in un file in formato xml per il successivo utilizzo. 

Al momento gli utilizzi più frequenti riguardano l'implementazione di previsioni automatiche su province sul sito di Arpa e la precompilazione dei bollettini per le trasmissioni RAI. 

Utilizzi meno frequenti riguardano la richiesta di previsioni per eventi e siti sensibili per periodi limitati di tempo. 

## Dove si trova Ciumbia?

La nuova versione, messa a punto da Riccardo Bonanno e ultimata da Matteo Zanetti, è presente su Gagliardo (10.10.0.15) nella cartella "ciumbia" al path "/home/meteo"

## Com'è strutturato Ciumbia 2.0?

Il processo è costruito per "girare" due volte al giorno una volta ultimati i processi di acquisizione dei principali modelli che vengono utilizzati. I file xml prodotti sono definiti quindi in base ai dati del modello di origine e alla data della "corsa". 
Es: ecmwf_201802190012 (dati dal modello ecmwf del giorno 19 febbraio 2018 con corsa delle ore 12:00)

[Vedi la struttura di CIUMBIA](https://github.com/ARPASMR/ciumbia/blob/master/Ciumbia_structure_EC_COSMO5M.pdf)

## Uso di Ciumbia
```
Line 491: <comune id="146" prov="015" oraUTC="00-06" data="20180309" icona="03" precipitazione="  0.0" Tmin="  4.6" Tmax="  7.8" ModVento="  0.8" DirVento=" 231.09">
	Line 2037: <comune id="146" prov="015" oraUTC="06-12" data="20180309" icona="02" precipitazione="  0.0" Tmin="  4.7" Tmax=" 11.4" ModVento="  0.9" DirVento=" 201.78">
	Line 3583: <comune id="146" prov="015" oraUTC="12-18" data="20180309" icona="03" precipitazione="  0.0" Tmin=" 10.2" Tmax=" 12.3" ModVento="  0.8" DirVento=" 343.30">
	Line 5129: <comune id="146" prov="015" oraUTC="18-24" data="20180309" icona="04" precipitazione="  0.0" Tmin="  8.0" Tmax=" 10.2" ModVento="  1.6" DirVento="  18.94">
	Line 6675: <comune id="146" prov="015" oraUTC="00-06" data="20180310" icona="04" precipitazione="  0.5" Tmin="  7.1" Tmax="  8.0" ModVento="  1.0" DirVento="  34.12">
	Line 8221: <comune id="146" prov="015" oraUTC="06-12" data="20180310" icona="13" precipitazione="  2.6" Tmin="  6.9" Tmax="  8.0" ModVento="  0.6" DirVento="  70.49">
```

## Crontab
In gagliardo il processo crontab è il seguente:
```
# CIUMBIA 2.0 (nuova versione MZ)
#5-45/20 05-08 * * * /home/meteo/bin/ciumbia.sh `/bin/date -d today +\%Y\%m\%d` 00 >> /home/meteo/log/ciumbia_`/bin/date -d today +\%Y\%m\%d`.log 2>&1
#5-45/20 17-20 * * * /home/meteo/bin/ciumbia.sh `/bin/date -d today +\%Y\%m\%d` 12 >> /home/meteo/log/ciumbia_`/bin/date -d today +\%Y\%m\%d`.log 2>&1
5-45/20 05-08 * * * /home/meteo/ciumbia/bin/ciumbia.sh `/bin/date -d today +\%Y\%m\%d` 00 >> /home/meteo/log/ciumbia_`/bin/date -d today +\%Y\%m\%d`.log 2>&1
5-45/20 17-20 * * * /home/meteo/ciumbia/bin/ciumbia.sh `/bin/date -d today +\%Y\%m\%d` 12 >> /home/meteo/log/ciumbia_`/bin/date -d today +\%Y\%m\%d`.log 2>&1

```
