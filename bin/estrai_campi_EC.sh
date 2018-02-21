. /home/meteo/ciumbia/conf/variabili_ambiente
. /home/meteo/.bashrc


# Coordinate geografiche che comprendono la Lombardia
min_lon=8.0
max_lon=11.5
min_lat=44.5
max_lat=47.0

cdo=/usr/local/bin/cdo

#####################################################################################
############################Estrazione campi SUPERFICIALI############################
#####################################################################################

#Estraggo separatamente i campi di analisi al timestep 0 e quelli nei restanti timestep
#Infatti alcuni campi superficiali nonsono presenti nelle analisi (hcc,mcc,lcc) e quindi
#le cdo non riescono a maneggiare file con un numero di campi diverso a seconda della 
#scadenza condiderata. Devo utilizzare un accrocchio
grib_copy -w typeOfLevel=surface,stepRange!=0 $tmp_dir/tmp_EC.grb $TMPCIU/surf_EC.grb
grib_copy -w typeOfLevel=surface,stepRange=0  $tmp_dir/tmp_EC.grb $TMPCIU/surf_EC_anl.grb


for var in "2t" "2d" "tcc" "hcc" "mcc" "lcc" "tp" "sf" "10u" "10v" "mx2t3" "mn2t3"
do  	
  #Per tp, sf, hcc, mcc, lcc non ci sono i campi di analisi e quindi non li estraggo
  #Creo dei campi di analisi fittizi nella parte successiva della procedura
  if [ $var != "tp" ] && [ $var != "sf" ] && [ $var != "hcc" ] && [ $var != "mcc" ] && [ $var != "lcc" ] \
                                                           && [ $var != "mx2t3" ] && [ $var != "mn2t3" ]; then
    grib_copy -w shortName=$var  $TMPCIU/surf_EC_anl.grb $TMPCIU/"$var"_anl.grb
    /usr/local/bin/cdo sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} $TMPCIU/"$var"_anl.grb $TMPCIU/"$var"_anl_lomb.grb
  fi  
	
  grib_copy -w shortName=$var  $TMPCIU/surf_EC.grb  $TMPCIU/"$var".grb
  /usr/local/bin/cdo sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} $TMPCIU/"$var".grb  $TMPCIU/"$var"_lomb.grb
done

#isolamento variabile z

grib_copy -w shortName=z  $TMPCIU/surf_EC_anl.grb $TMPCIU/z_anl.grb

#Ciclo while per la crezione di un grb con gli step temporali che mi servono e ritaglio sulla Lombardia

range_number=0
		while [[ $range_number -le 72 ]]; do	
		echo $range_number
			grib_set -s stepRange=$range_number $TMPCIU/z_anl.grb $TMPCIU/z$range_number"_"steps.grb
			$cdo cat $TMPCIU/z$range_number"_"steps.grb $TMPCIU/z.grb
			range_number=$((range_number+3))
		done

/usr/local/bin/cdo sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} $TMPCIU/z.grb  $TMPCIU/z_lomb.grb


#Creo dei campi di analisi fittizi per hcc,mcc,lcc,tp e sf utilizzando la tcc e settando a 
#zero i valori di nuvolosita'.
/usr/local/bin/cdo -mulc,0 $TMPCIU/tcc_anl.grb $TMPCIU/tmp_anl.grb
for var in "hcc" "mcc" "lcc" "tp" "sf" "mx2t3" "mn2t3"
do
  grib_set -s shortName=$var $TMPCIU/tmp_anl.grb $TMPCIU/"$var"_anl.grb
  /usr/local/bin/cdo sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} $TMPCIU/"$var"_anl.grb $TMPCIU/"$var"_anl_lomb.grb
  rm $TMPCIU/"$var"_anl.grb
done

#Aggrego in un unico file
cat  $TMPCIU/*_lomb.grb > $TMPCIU/surf_EC.grb

#Converto in netcdf
grib_to_netcdf $TMPCIU/surf_EC.grb -o $TMPCIU/surf_EC.nc

#Rimozione file inutilizzati
rm $TMPCIU/*.grb

#################################################################################
#Estrazione delle variabili sui LIVELLI DI PRESSIONE (per il calcolo del K Index)
#################################################################################

for level in "1000" "850" "700" "500"
do
  grib_copy -w shortName=t,level=$level $tmp_dir/tmp_EC_2.grb $TMPCIU/t"$level"_pres.grb
  grib_copy -w shortName=q,level=$level $tmp_dir/tmp_EC_2.grb $TMPCIU/q"$level"_pres.grb
  /usr/local/bin/cdo sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} $TMPCIU/t"$level"_pres.grb  $TMPCIU/t"$level"_pres_lomb.grb
  /usr/local/bin/cdo sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} $TMPCIU/q"$level"_pres.grb $TMPCIU/q"$level"_pres_lomb.grb
  rm $TMPCIU/t"$level"_pres.grb $TMPCIU/q"$level"_pres.grb
done

#Aggrego in un unico file
cat $TMPCIU/*_pres_lomb.grb > $TMPCIU/pres_EC.grb

#Converto in netcdf
grib_to_netcdf $TMPCIU/pres_EC.grb -o $TMPCIU/pres_EC.nc

#Rimozione file inutilizzati
rm $TMPCIU/*.grb

exit
