elabora_prev <-function(z_int,t2m_int,d2m_int,u10_int,v10_int,tcc_int,hcc_int,mcc_int,lcc_int,prec_int,snow_int,kind_int,mx2t6_int,mn2t6_int,rh2m_int,id_centro) {

    icona_sereno=1
    icona_poconuvoloso=2
    icona_nuvoloso=3
    icona_coperto=4
    icona_velato=5
    icona_nebbia=6
    icona_nebbianubi=7
    icona_pioggiadebolesole=8
    icona_pioggiafortesole=9
    icona_pioggianevesole=10
    icona_nevedebolesole=11
    icona_nevefortesole=12
    icona_pioggiadebolenubi=13
    icona_pioggiafortenubi=14
    icona_pioggianevenubi=15
    icona_nevedebolenubi=16
    icona_nevefortenubi=17
    icona_temporalesole=18
    icona_temporalenubi=19
    icona_mancante=-999
    

    soglia_tcc_sereno=0.2
    soglia_tcc_poconuvoloso=0.5
    soglia_tcc_coperto=0.9
    soglia_tcc_velato=0.5
    soglia_lcc_velato=0.1
    soglia_rh_nebbia=98.
    soglia_tot_prec_piove=1.
    soglia_tot_prec_pioveforte=10.
    soglia_vento_direzione_variabile=0.5
    soglia_solounafase_prec=0.1
    soglia_kindex_temporale=35


    conv_rad2deg=(90/acos(0))
    icona_mancante=-999
    ncomuni<-length(t2m_int[,1])

    #####################################################################  
    ###################IMPOSTAZIONE DELLE ICONE DEL TEMPO################  
    #####################################################################

    zero_celsius=273.15
    real_missing=-999.99
    field_icone=icona_mancante
    field_icone=99
    field_temperatura_min=-17.0
    field_temperatura_max=34.0
	fatt_corr=0.65
	conv_metri=0.101972

    #Conversione in mm... se necessario. Lo e' per l'ECMWF
    if(id_centro=='ecmwf'){
      field_precipitazione=abs(prec_int*1000)
      field_nevicata=snow_int*1000
	  field_tcc=tcc_int
	  field_hcc=hcc_int
	  field_lcc=lcc_int
	  field_mcc=mcc_int
    } else {
      field_precipitazione=abs(prec_int)
      field_nevicata=snow_int
	  field_tcc=tcc_int/100
	  field_hcc=hcc_int/100
	  field_lcc=lcc_int/100
	  field_mcc=mcc_int/100
    }
    field_rh2m=rh2m_int
    #field_tcc=tcc_int
    #field_hcc=hcc_int
    #field_mcc=mcc_int
    #field_lcc=lcc_int
    field_u10m=u10_int
    field_v10m=v10_int
    field_kindex=kind_int
    field_mint2m=mn2t6_int
    field_maxt2m=mx2t6_int
    field_vento_mod=17.0
    field_vento_dir=17.0
    log_temporale=FALSE
    log_precipita=FALSE
    log_precipitaforte=FALSE

	#####################################################################
    ############IMPOSTAZIONE DELLE TEMPERATURE MASSIME E MINIME##########
    #####################################################################
	correzione=1
	
	for (ipunto in 1:ncomuni) {
			if (altezza[ipunto] > 200){
				correzione=(abs((altezza[ipunto]-(z_int[ipunto]*conv_metri))/100))*fatt_corr
				if (altezza[ipunto]<=z_int[ipunto]*10){
					field_temperatura_min[ipunto]=(field_mint2m[ipunto]-zero_celsius) + correzione
					field_temperatura_max[ipunto]=(field_maxt2m[ipunto]-zero_celsius) + correzione
					}
					else {
					field_temperatura_min[ipunto]=(field_mint2m[ipunto]-zero_celsius) - correzione
					field_temperatura_max[ipunto]=(field_maxt2m[ipunto]-zero_celsius) - correzione
				}	
			}
			else{
			field_temperatura_min[ipunto]=field_mint2m[ipunto]-zero_celsius
			field_temperatura_max[ipunto]=field_maxt2m[ipunto]-zero_celsius
			}
	}
	
	#####################################################################
    ############ALGORITMO SCELTA ICONA DEL TEMPO##########
    #####################################################################
    
    for (ipunto in 1:ncomuni) {

      log_precipita=field_precipitazione[ipunto]>soglia_tot_prec_piove
      log_precipitaforte=(field_precipitazione[ipunto]>soglia_tot_prec_pioveforte)

      log_nebbia=all(field_rh2m[ipunto,]>soglia_rh_nebbia)
      log_coperto=(all(field_tcc[ipunto,]>soglia_tcc_coperto) &
                   all(field_lcc[ipunto,]>soglia_tcc_poconuvoloso) &
                   all(field_mcc[ipunto,]>soglia_tcc_poconuvoloso))
      log_sereno=all(field_tcc[ipunto,]<=soglia_tcc_sereno)
      log_velato=(all(field_tcc[ipunto,]<soglia_tcc_velato)&
                  all(field_mcc[ipunto,]<soglia_lcc_velato) &
                  all(field_lcc[ipunto,]<soglia_lcc_velato))
      log_temporale=log_precipitaforte & (max(field_kindex[ipunto,])>soglia_kindex_temporale)
    

      if(log_precipita) {
        if(log_temporale) {
          if(log_coperto) {
            field_icone[ipunto]=icona_temporalenubi
          } else {
            field_icone[ipunto]=icona_temporalesole
          }
        } else {

          quanta_precipitazione=field_precipitazione[ipunto]
          quanta_neve=field_nevicata[ipunto]

          frac=quanta_neve/quanta_precipitazione
          log_nevica=(frac>(1.-soglia_solounafase_prec))
          log_piove=(frac<soglia_solounafase_prec)

          if(log_nevica) {
			if((field_temperatura_min[ipunto] <= 2 ) && (field_temperatura_max[ipunto] <= 2 )){
				if(log_coperto & log_precipitaforte) {
				field_icone[ipunto]=icona_nevefortenubi
				} 	else if(log_coperto) {
					field_icone[ipunto]=icona_nevedebolenubi
				} 	else if(log_precipitaforte) {
					field_icone[ipunto]=icona_nevefortesole
				} else {
					field_icone[ipunto]=icona_nevedebolesole
				}
			} else {
				if(log_coperto & log_precipitaforte) {
				field_icone[ipunto]=icona_pioggiafortenubi
				} 	else if(log_coperto) {
				field_icone[ipunto]=icona_pioggiadebolenubi
				} 	else if(log_precipitaforte) {
				field_icone[ipunto]=icona_pioggiafortesole
					} 	
				else {
				field_icone[ipunto]=icona_pioggiadebolesole
				}
			}
          } else if(log_piove) {
            if(log_coperto & log_precipitaforte) {
              field_icone[ipunto]=icona_pioggiafortenubi
            } else if(log_coperto) {
              field_icone[ipunto]=icona_pioggiadebolenubi
            } else if(log_precipitaforte) {
              field_icone[ipunto]=icona_pioggiafortesole
            } else {
              field_icone[ipunto]=icona_pioggiadebolesole
            }
          } else {
            if(log_coperto) {
              field_icone[ipunto]=icona_pioggianevenubi
            } else {
              field_icone[ipunto]=icona_pioggianevesole
            }
          }
        }
      } else {
        if(log_nebbia) {
          if(all(field_tcc[ipunto,]>soglia_tcc_poconuvoloso)) {
            field_icone[ipunto]=icona_nebbianubi
          } else {
            field_icone[ipunto]=icona_nebbia
          }
        } else {
          if(log_sereno) {
            field_icone[ipunto]=icona_sereno
          } else if(log_coperto) {
            field_icone[ipunto]=icona_coperto
          } else if(log_velato) {
            field_icone[ipunto]=icona_velato
          } else if (mean(field_tcc[ipunto,])<=soglia_tcc_poconuvoloso) {
            field_icone[ipunto]=icona_poconuvoloso
          } else {
            field_icone[ipunto]=icona_nuvoloso
          }
        }
      }
    }
    
	
    #####################################################################
    #################INTENSITA' E DIREZIONE DEL VENTO####################
    #####################################################################

    #scelta del vento massimo ultime 3 scadenze prese in considerazione
	for (ipunto in 1:ncomuni) {
      vec_vento_mod_istantanee=sqrt(field_u10m[ipunto,]^2+field_v10m[ipunto,]^2)
      field_vento_mod[ipunto]=max(vec_vento_mod_istantanee)
      
      #umedio=mean(field_u10m[ipunto,])
      #vmedio=mean(field_v10m[ipunto,])
      indice=which(vec_vento_mod_istantanee==max(vec_vento_mod_istantanee))[1]

      if(sqrt(field_u10m[ipunto,indice]^2+field_v10m[ipunto,indice]^2)<soglia_vento_direzione_variabile*field_vento_mod[ipunto]) {
        field_vento_dir[ipunto]=real_missing
      } else {

      #direzione corrispondente alla scadenza con velocità del vento medio
      #massima
      field_vento_dir[ipunto]=270-atan2(field_v10m[ipunto,indice],field_u10m[ipunto,indice])*conv_rad2deg
      if(field_vento_dir[ipunto]>360) {
         field_vento_dir[ipunto]=field_vento_dir[ipunto]-360
      }
      }
    

   #   if(sqrt(umedio^2+vmedio^2)<soglia_vento_direzione_variabile*field_vento_mod[ipunto]) {
   #     field_vento_dir[ipunto]=real_missing
   #   } else {
   #     #Calcolo della direzione in gradi sessagesimali ed espressione in azimut:
   #     #il fattore moltiplicativo e' la conversione da radianti in gradi
   #     #sessagesimali, il segno e l'addendo sono il cambiamento di sistema
   #     #di riferimento
   #     if(umedio<0 & vmedio>0) {
   #        field_vento_dir[ipunto]=90-atan2(vmedio,umedio)*conv_rad2deg+360
   #     } else {
   #        field_vento_dir[ipunto]=90-atan2(vmedio,umedio)*conv_rad2deg
   #     }
   #   }


    }

output <- array(0,c(ncomuni,6))

output<-cbind(field_icone,field_precipitazione,field_temperatura_max,field_temperatura_min,field_vento_mod,field_vento_dir)


return(as.data.frame(output))



}#fine function
