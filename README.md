# ciumbia
Creazione file .xml con dati meteo puntuali per tutti i comuni lombardi. 

## Cos'è Ciumbia?

Il processo CIUMBIA ha lo scopo di estrarre dall'output dei modelli **ECMWF** e **COSMO5M** (_in passato COSMOI7_) i valori dei principali parametri meteorologici in corrispondenza delle coordinate dei Comuni della Lombardia e metterli a disposizione in un file in formato xml per il successivo utilizzo. 

Al momento gli utilizzi più frequenti riguardano l'implementazione di previsioni automatiche su province sul sito di Arpa e la precompilazione dei bollettini per le trasmissioni RAI. 

Utilizzi meno frequenti riguardano la richiesta di previsioni per eventi e siti sensibili per periodi limitati di tempo. 

## Dove si trova Ciumbia?

La nuova versione, messa a punto da Riccardo Bonanno e ultimata da Matteo Zanetti, è presente su Gagliardo (10.10.0.15) nella cartella "ciumbia" al path "/home/meteo"

## Com'è strutturato Ciumbia?

Il processo è costruito per "girare" due volte al giorno una volta ultimati i processi di acquisizione dei principali modelli che vengono utilizzati. I file xml prodotti sono definiti quindi in base ai dati del modello di origine e alla data della "corsa". 
Es: ecmwf_201802190012 (dati dal modello ecmwf del giorno 19 febbraio 2018 con corsa delle ore 12:00)

## Uso di Ciumbia
```
inserire qui un esempio di run di Ciumbia
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
