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

#Solo tmin_2m e tmax_2m non sono presenti allo step temporale 0, quindi devo riproporli a 
#quella scadenza temporale con il solito trucco di settarli a 0(non li userò mai a questa scadenza).
#A differenza dei dati del centro Europeo i campi superficiali devono essere estratti con
#l'opzione typeOfLevel!=isobaricInhPa. Se utilizzo l'opzione typeOfLevel!=surface mi perdo
#i campi di 2t e 2d che per cosmo sono definiti con il typeOfLevel=heightAboveGround mentre
#per i dati da ECMWF come typeOfLevel=surface
grib_copy -w typeOfLevel!=isobaricInhPa,stepRange!=0 $tmp_dir/tmp_C5M.grb $TMPCIU/surf_C5M.grb
grib_copy -w typeOfLevel!=isobaricInhPa,stepRange=0  $tmp_dir/tmp_C5M.grb $TMPCIU/surf_C5M_anl.grb


for var in "2t" "2d" "clct" "clch" "clcm" "clcl" "tp" "snow_gsp" "10u" "10v" "tmin_2m" "tmax_2m"
do
  #Per tp, sf, hcc, mcc, lcc non grib_copy -w typeOfLevel!=isobaricInhPa,stepRange=0uindi non li estraggo
  #Creo dei campi di analisi fittizi nella parte successiva della procedura
  if [ $var != "tmin_2m" ] && [ $var != "tmax_2m" ]; then
    grib_copy -w shortName=$var  $TMPCIU/surf_C5M_anl.grb $TMPCIU/"$var"_anl.grb
    /usr/local/bin/cdo -sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} -remapbil,$conf_dir/grid_cosmo5M_antirot $TMPCIU/"$var"_anl.grb $TMPCIU/"$var"_anl_lomb.grb
  fi

  grib_copy -w shortName=$var  $TMPCIU/surf_C5M.grb  $TMPCIU/"$var".grb
  /usr/local/bin/cdo -sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} -remapbil,$conf_dir/grid_cosmo5M_antirot $TMPCIU/"$var".grb  $TMPCIU/"$var"_lomb.grb
done

#isolamento variabile z o hsurf (per nuova disseminazione)
grib_copy -w shortName=hsurf  $TMPCIU/surf_C5M_anl.grb $TMPCIU/hsurf_anl.grb

#Ciclo while per la crezione di un grb con gli step temporali che mi servono e ritaglio sulla Lombardia
range_number=0
		while [[ $range_number -le 72 ]]; do	
		echo $range_number
			grib_set -s stepRange=$range_number $TMPCIU/hsurf_anl.grb $TMPCIU/hsurf$range_number"_"steps.grb
			$cdo cat $TMPCIU/hsurf$range_number"_"steps.grb $TMPCIU/hsurf.grb
			range_number=$((range_number+1))
		done

/usr/local/bin/cdo sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} -remapbil,$conf_dir/grid_cosmo5M_antirot $TMPCIU/hsurf.grb  $TMPCIU/hsurf_lomb.grb


#Creo dei campi di analisi fittizi per tmin_2m e tmax_2m utilizzando la clct e settando a 
#zero i valori di temperatura minima e massima .
/usr/local/bin/cdo -mulc,0 $TMPCIU/clct_anl.grb $TMPCIU/tmp_anl.grb
for var in "tmin_2m" "tmax_2m"
do
  grib_set -s shortName=$var $TMPCIU/tmp_anl.grb $TMPCIU/"$var"_anl.grb
  /usr/local/bin/cdo -sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} -remapbil,$conf_dir/grid_cosmo5M_antirot $TMPCIU/"$var"_anl.grb $TMPCIU/"$var"_anl_lomb.grb
  rm $TMPCIU/"$var"_anl.grb
done

#Aggrego in un unico file
cat  $TMPCIU/*_lomb.grb > $TMPCIU/surf_C5M.grb

#Converto in netcdf
grib_to_netcdf $TMPCIU/surf_C5M.grb -o $TMPCIU/surf_C5M.nc

#Rimozione file inutilizzati
rm $TMPCIU/*.grb

#################################################################################
#Estrazione delle variabili sui LIVELLI DI PRESSIONE (per il calcolo del K Index)
#################################################################################

for level in "850" "700" "500"
do
  grib_copy -w shortName=t,level=$level $tmp_dir/tmp_C5M.grb $TMPCIU/t"$level"_pres.grb
  grib_copy -w shortName=r,level=$level $tmp_dir/tmp_C5M.grb $TMPCIU/rh"$level"_pres.grb
  /usr/local/bin/cdo -sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} -remapbil,$conf_dir/grid_cosmo5M_antirot $TMPCIU/t"$level"_pres.grb  $TMPCIU/t"$level"_pres_lomb.grb
  /usr/local/bin/cdo -sellonlatbox,${min_lon},${max_lon},${min_lat},${max_lat} -remapbil,$conf_dir/grid_cosmo5M_antirot $TMPCIU/rh"$level"_pres.grb $TMPCIU/rh"$level"_pres_lomb.grb
  rm $TMPCIU/t"$level"_pres.grb $TMPCIU/rh"$level"_pres.grb
done

#Aggrego in un unico file
cat $TMPCIU/*_pres_lomb.grb > $TMPCIU/pres_C5M.grb

#Converto in netcdf
grib_to_netcdf $TMPCIU/pres_C5M.grb -o $TMPCIU/pres_C5M.nc

#Rimozione file inutilizzati
rm $TMPCIU/*.grb

exit
