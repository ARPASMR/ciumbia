#!/bin/bash
## script originali acquisizione/plottaggio Bolam U. Pellegrini
## piratati MS giugno 2014 per estrarre COSMO da arkimet e plottare
## Usage:
## extract-cosmo_I7.sh <data (aaaammgg)> <run (00-12)>
##Aggiornamento 01-2018 per implementazione cosmo 5M al posto di COSMO I7

. /home/meteo/ciumbia/conf/variabili_ambiente
. /home/meteo/.bashrc

usage="Utilizzo: `basename $0` <data(aaaammgg)> <run>"
usage1="Se non si specifica la data, viene usata quella odierna"

local_diroutput="/home/meteo/ciumbia/archivio/xml"
local_diroutput_eventi="/home/meteo/ciumbia/archivio/xml_eventi"
dir_appoggio="/home/meteo/ciumbia/archivio/xml_eventi/appoggio" 

dataoggi=$(date +%Y%m%d)
dataieri=$(date --d yesterday +%Y%m%d)

#parsing degli argomenti
if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
	echo $usage
	echo $usage1
	exit
fi

if [ ! $1 ]
then
	dataplot=$dataoggi
else
	dataplot=$1
fi

if [ ! $2 ]
then
	echo "manca il run"
	echo $usage
	echo $usage1
	exit
else
	run=$2
fi
 

# Coordinate geografiche che comprendono la Lombardia
min_lon_lomb=8.0
max_lon_lomb=11.5
min_lat_lomb=44.5
max_lat_lomb=47.0

#variabili
nomescript=`basename $0 .sh`
export fieldset=`basename $0 .sh |cut -d'-' -f2`
export fieldset="ciumbia"
control_plot_EC=$log_dir/control_ciumbia_ECMWF.$dataplot"_"$run && echo $control_plot_EC
control_plot_C5M=$log_dir/control_ciumbia_COSMO5M.$dataplot"_"$run && echo $control_plot_C5M
script_dir=$home_dir/bin/script_$fieldset && echo $script_dir # in attesa di capire perchè è stata usata questa variabile
day=`echo $dataplot |awk '{print substr($0,7,2)}'`
month=`echo $dataplot |awk '{print substr($0,5,2)}'`
year=`echo $dataplot |awk '{print substr($0,1,4)}'`
stringalog=$day" "$month" "$year
stringarun=$year$month$day$run
local_dir_png=$home_dir/mappe_$fieldset/png && echo $local_dir_png #Idem come sopra
file_index="index.html" # Idem



#Controllo se la procedura sia già in esecuzione: in tal caso esco.
export LOCKDIR=$tmp_dir/$nomescript-$dataplot-$run.lock && echo "lockdir -----> $LOCKDIR"

T_MAX=5400

if mkdir "$LOCKDIR" 2>/dev/null
then
        echo "acquisito lockdir: $LOCKDIR"
        echo $$ > $LOCKDIR/PID
else
        echo "Script \"$nomescript.sh\" già in esecuzione alle ore `date +%H%M` con PID: $(<$LOCKDIR/PID)"
        echo "controllo durata esecuzione script"
        ps --no-heading -o etime,pid,lstart -p $(<$LOCKDIR/PID)|while read PROC_TIME PROC_PID PROC_LSTART
        do
                SECONDS=$[$(date +%s) - $(date -d"$PROC_LSTART" +%s)]
                echo "------Script \"$nomescript.sh\" con PID $(<$LOCKDIR/PID) in esecuzione da $SECONDS secondi"
                if [ $SECONDS -gt $T_MAX ]
                then
                        echo "$PROC_PID in esecuzione da più di $T_MAX secondi, lo killo"
                        pkill -15 -g $PROC_PID
			logger -is -p user.warning "$nomescript: processo terminato per timeout $T_MAX" -t "CIUMBIA"
                fi
        done
        echo "*********************************************************"
        exit
fi


trap "rm -fvr "$LOCKDIR";
rm -fv $tmp_dir/$$"_"*;
echo;
echo \"** fine script `basename $0`: `date` ***************************************\";
exit" EXIT HUP INT QUIT TERM


##Controllo che i dati siano pronti per essere scaricati in locale
##ECMWF
echo
logger -is -p user.notice "$nomescript: inizio esecuzione" -t "PREVISORE"
echo "Controllo che i file grib di ECMWF  siano stati gia' scaricati su Bolognone virtuale"


filessh=$year$month$day$run'00.JND'
scp arpal@10.10.0.12:/tmp/arki/$filessh $tmp_dir/.
control_file_ecm=$?
ecmwf_flag=0

if [ $control_file_ecm == 0 ];
then
 #nscad=$(head -n 1 $tmp_dir/$filessh)
 #if [ "$nscad" == "" ];
 #then
  echo "I file grib di ECMWF sono presenti su arkimet"
  #echo "numero scadenze = "$nscad
  echo
  ecmwf_flag=1
  rm $tmp_dir/$filessh
 else
  #echo "ciumbia"
  #echo "I file grib di ECMWF non sono ancora stati scaricati"
  #rm $tmp_dir/$filessh
 #fi
#else
 echo "I file grib di ECMWF non sono ancora stati scaricati"
fi

##COSMO 5M
echo "Controllo che i file grib di COSMO 5M siano stati gia' scaricati su Bolognone virtuale"


filessh=$year$month$day$run'00.cosmo_5M_ita'
scp arpal@10.10.0.12:/tmp/arki/$filessh $tmp_dir/. 
control_file_cos=$?
cosmo_flag=0

if [ $control_file_cos == 0 ]; 
then 
  echo "I file grib di COSMO 5M sono presenti su arkimet"
  echo
  cosmo_flag=1
  rm $tmp_dir/$filessh 
else 
  echo "I file grib di COSMO 5M non sono ancora stati scaricati"
fi

#Se entrambi i dataset non sono disponibili esco dalla procedura,
#altrimenti scarico e plotto quello che c'è già
if [ $ecmwf_flag -ne 1 ] && [ $cosmo_flag -ne 1 ];
then
  echo
  echo "I file grib di ECMWF e di COSMO 5M non sono ancora stati scaricati: esco dalla procedura"
  logger -is -p user.warning "$nomescript: file grib non presenti" -t "CIUMBIA"
  echo
  exit
fi



### controllo che i dati non siano già stati plottati (in questo caso esco)
if [ $ecmwf_flag -eq 1 ]
then
orainizio=$(date +%s)
if [ -s $control_plot_EC ]
then
	echo
	echo "Files xml ECMWF, data $dataplot corsa $run gia' creati. Passo a COSMO 5M"
	break
else
	echo 
        echo "----Lancio script 'arkiquery.sh' per estrarre grib del modello ECMWF data $dataplot corsa $run: "
	logger -is -p user.info "$nomescript: lancio arkiquery ECMWF $year-$month-$day $run" -t "CIUMBIA"
        echo "/home/meteo/bin/arkiquery.sh \"ecmwf\" \"$year-$month-$day $run\" \"/home/meteo/scratch/\" \"tmp.grb\" \" \" \" \" \" \""
	$bin_dir/arkiquery.sh -d "ifs_ita010" -r "$year-$month-$day $run" -o "$tmp_dir" -f "tmp_EC.grb" " " " " " "
        if [ "$?" -ne "0" ]
        then
        	echo "codice uscita arkyq diverso da 0"
		logger -is -p user.err "$nomescript: codice uscita arkyquery diverso da 0" -t "CIUMBIA"
        	echo
        	exit
	fi

        rm $TMP_CIU/*.nc
        #Procedura per la produzione dei files netcdf che dovranno essere utilizzati
        #dallo script in R. La procedura estrae i campi necessari e li ritaglia sulla 
        #Lombardia
        $binciu_dir/estrai_campi_EC.sh


        ##Esecuzione script per creazione tipi di tempo
        Rscript $fun_dir/tempo_su_griglia.R 'ecmwf' $TMPCIU $XMLCIU
        echo
        echo "OK Ciumbia ECMWF  $dataplot" > $control_plot_EC
        echo
        echo "fine Ciumbia ECMWF $data $datagrib alle ore: `date`"
		
		# #------------------- INIZIO COPIATURA SU CARTELLE UTILI ECMWF --------------------------
 echo $stringarun
 if [ -s ${local_diroutput}/ecmwf_${stringarun}00.xml ]; then
		# #gpm-commentato-il-20160616 $HOME/script/ciumbia/xml4expo.sh cosmo_${modelrun}.xml
		# #gpm-commentato-il-20160616 $HOME/script/ciumbia/xml4bollexpo.sh cosmo_${modelrun}.xml
		# # produce xml con solo Comune di Milano
		/home/meteo/ciumbia/bin/xml4milano.sh ecmwf_${stringarun}00.xml		
		# # copia l'xml completo su Previsore
		cd ${local_diroutput}
		smbclient //10.10.0.10/f -U ARPA/<user>%<password> -c 'cd precompilazione\Prov; prompt; mput '"ecmwf_${stringarun}00.xml"
		# #gpm-commentato-il-20160616 scp previ_expo.xml meteoweb@172.16.1.10:/var/www/meteo/expo/xml
		# #scp cosmo_${modelrun}.xml meteoweb@172.16.1.10:/var/www/meteo/expo/meteo_expo_xml
		# # copia l'xml di Milano su Previsore e su #webserver
		cd ${local_diroutput_eventi}
		# #gpm-commentato-il-20160616 smbclient //10.10.0.10/f -U ARPA/<user>%<password> -c 'cd precompilazione\xml; prompt; mput '"cosex_${modelrun}.xml"
		smbclient //10.10.0.10/f -U ARPA/<user>%<password> -c 'cd precompilazione\eventi; prompt; mput '"ecm_${stringarun}00.xml"
		# #gpm-commentato-il-20160616 scp cosex_${modelrun}.xml meteoweb@172.16.1.10:/var/www/meteo/expo/meteo_expo_xml
		# #scp cosis_${modelrun}.xml meteoweb@172.16.1.10:/var/www/meteo/iseo/xml
	 fi
# #------------------- FINE COPIATURA ----------------------------------------------


  fi
fi


### controllo che i dati non siano già stati plottati (in questo caso esco)
if [ $cosmo_flag -eq 1 ]
then
orainizio=$(date +%s)
if [ -s $control_plot_C5M ] 
then
        echo
        echo "Files xml COSMO 5M, data $dataplot corsa $run gia' creati. Esco dalla procedura"
        echo
        exit
else
        echo
        echo "----Lancio script 'arkiquery.sh' per estrarre grib del modello COSMO 5M data $dataplot corsa $run: "
	logger -is -p user.info "$nomescript: lancio arkyquery COSMO5M per $year-$month-$day $dataplot corsa $run" -t "CIUMBIA"
        echo "/home/meteo/bin/arkiquery.sh \"cosmo_5M_ita\" \"$year-$month-$day $run\" \"/home/meteo/scratch/\" \"tmp.grb\" \" \" \" \" \" \""
        $bin_dir/arkiquery.sh -d "cosmo_5M_ita" -r "$year-$month-$day $run" -o "$tmp_dir" -f "tmp_C5M.grb" " " " " " "
        if [ "$?" -ne "0" ]
        then
                echo "codice uscita arkyq diverso da 0"
                echo
		logger -is -p user.err "$nomescript: codice uscita arkyquery diverso da 0" -t "CIUMBIA"
                exit
        fi

        rm $TMP_CIU/*.nc
        #Procedura per la produzione dei files netcdf che dovranno essere utilizzati
        #dallo script in R. La procedura estrae i campi necessari, li antiruota e  li 
        #ritaglia sulla Lombardia
        $binciu_dir/estrai_campi_C5M.sh   
    
        #rm $XMLCIU/*.xml
        ##Esecuzione script per creazione tipi di tempo
        Rscript $fun_dir/tempo_su_griglia.R 'cosmo_5M_ita' $TMPCIU $XMLCIU 

        ##Esecuzione script per creazione tipi di tempo

        echo
        echo "OK Ciumbia COSMO 5M  $dataplot" > $control_plot_C5M
        echo
        echo "fine Ciumbia COSMO 5M $data $datagrib alle ore: `date`"
		
		# ------------------- INIZIO COPIATURA SU CARTELLE UTILI COSMO --------------------------
 # echo $stringarun
  if [ -s ${local_diroutput}/cosmo_${stringarun}00.xml ]; then
		# gpm-commentato-il-20160616 $HOME/script/ciumbia/xml4expo.sh cosmo_${modelrun}.xml
		# gpm-commentato-il-20160616 $HOME/script/ciumbia/xml4bollexpo.sh cosmo_${modelrun}.xml
		# produce xml con solo Comune di Milano
		/home/meteo/ciumbia/bin/xml4milano.sh cosmo_${stringarun}00.xml	
		#cd ${local_diroutput_eventi}
		#smbclient //10.10.0.10/f -U ARPA/<user>%<password> -c 'cd precompilazione\eventi; prompt; mput '"cos_${stringarun}.xml"		
		# copia l'xml completo su Previsore
		cd ${local_diroutput}
		smbclient //10.10.0.10/f -U ARPA/<user>%<password> -c 'cd precompilazione\Prov; prompt; mput '"cosmo_${stringarun}00.xml"
		# gpm-commentato-il-20160616 scp previ_expo.xml meteoweb@172.16.1.10:/var/www/meteo/expo/xml
		# scp cosmo_${modelrun}.xml meteoweb@172.16.1.10:/var/www/meteo/expo/meteo_expo_xml
		# copia l'xml di Milano su Previsore e su #webserver
		cd ${local_diroutput_eventi}
		smbclient //10.10.0.10/f -U ARPA/<user>%<password> -c 'cd precompilazione\eventi; prompt; mput '"cos_${stringarun}00.xml"
		# gpm-commentato-il-20160616 smbclient //10.10.0.10/f -U ARPA/<user>%<password> -c 'cd precompilazione\xml; prompt; mput '"cosex_${modelrun}.xml"
		# gpm-commentato-il-20160616 scp cosex_${modelrun}.xml meteoweb@172.16.1.10:/var/www/meteo/expo/meteo_expo_xml
		# scp cosis_${modelrun}.xml meteoweb@172.16.1.10:/var/www/meteo/iseo/xml
 fi
# ------------------- FINE COPIATURA ----------------------------------------------
# eseguo script tempo_su_griglia_Iris.R per interpolare T e V di cosmo_5m sui punti stazione della rete IMN.  

. /home/meteo/ciumbia/conf/variabili_ambiente_tempo_su_Iris
cd $fun_dir
Rscript tempo_su_griglia_Iris.R
cd- 
  fi
fi



orafine=$(date +%s)
differenza=$(($orafine - $orainizio))
tempo_minuti=$(($differenza / 60)) && echo "tempo di estrazione, copia e plottaggio in minuti: $tempo_minuti min"

logger -is -p user.notice "$nomescript: fine esecuzione $data $datagrib in minuti $tempo_minuti" -t "PREVISORE"
echo "******fine script: `basename $0` alle ore: `date` ************************"

exit


