########################################################################
# .  /home/meteo/ciumbia/conf/variabili_ambiente_tempo_su_Iris
#  variabili settate
#  export LD_LIBRARY_PATH=/home/meteo/lib_per_R/lib:/usr/pgsql-9.6/lib:$LD_LIBRARY_PATH
#  export PATH=/home/meteo/lib_per_R/bin:$PATH
#
#  export HOST_dbIRS='10.10.0.19'
#  export PORT_dbIRS=5432
#  export USER_dbIRS='postgres'
#  expot PASS_dbIRS=xxxx
#
########################################################################

library(ncdf4)
library(fields)

#fun_dir <-Sys.getenv("fun_dir")
#dirin  <-Sys.getenv("TMPCIU")
#dirout <-Sys.getenv("XMLCIU")

#Creare un nuovo file env per ciumbia_iris con queste variabili
#quindi commentare questi valori

dirin <- '/home/meteo/ciumbia/tmp'
dirout <- '/home/meteo/ciumbia/archivio/csv_interp_stazioni/'
fun_dir <- '/home/meteo/ciumbia/bin/functions'

#Script accessori
source(paste(fun_dir,'/functions.R',sep=''))
source(paste(fun_dir,'/elabora_prev.R',sep=''))


set_string_values_insert <- function(df,df_corr,i,t,time_ini,str_date_CET,suffix_model) {
  
   id_sensore<-df[i,"idsensore"]
   id_stazione<-df[i,"idstazione"]
   nometipologia<-paste("'",df[i,"nometipologia"],"'",sep='')
   dh_m_s<-df[i,"diff_orogr"]
    

   name_scad <-str_date_CET[t]
   # per trattare meglio le date, converto le stringhe in oggetti time 
   data_e_ora_scad <-strptime(name_scad, "%Y%m%d%H",tz = "GMT")
   # quindi riconverto time in stringhe col formato adatto a postgres 
   data_e_ora_frcst <- paste("'",strftime(data_e_ora_scad, "%Y-%m-%d %H:%M",tz = "GMT"),"'",sep='')
  
   misura<-df[i,name_scad]

   misura_corr<-df_corr[i,name_scad]
  
   suffix_model <- paste("'",suffix_model,"'",sep='')
  
   data_run <- paste("'",strftime(time_ini, "%Y-%m-%d %H:%M"),"'",sep='')
  
   string_values_insert_tmp <-paste(id_sensore,id_stazione,nometipologia,data_e_ora_frcst,misura,misura_corr,suffix_model,dh_m_s,data_run,sep=',')
   string_values_insert <-paste("(",string_values_insert_tmp,")",sep='')
   return(string_values_insert)
  
}

set_string_delete <- function(tabella_db,data_e_ora_del,suffix_model,purge='False',n_days_del=14) {
   # La funzione elimina i forecast dei precedenti run (purge='False'), diversamente non si potrebbero inserire i forecast del run più recente per violazione chiave primaria data_e_ora_frcst.
   # se purge è True, vengono eliminati i forecast più vecchi di n_days_del (default 14 gg).  
   
   if  (purge) {
       data_e_ora_del_clean <- data_e_ora_del -60*60*24*n_days_del
       str_data_e_ora_del <- paste("'",strftime(data_e_ora_del_clean, "%Y-%m-%d %H:%M",tz = "GMT"),"'",sep='') 	   
       QueryDelete <-paste("DELETE FROM ", tabella_db, " WHERE data_e_ora_frcst < ",str_data_e_ora_del,sep='')
   } else {
       str_data_e_ora_del <- paste("'",strftime(data_e_ora_del, "%Y-%m-%d %H:%M",tz = "GMT"),"'",sep='') 
       QueryDelete <-paste("DELETE FROM ", tabella_db,
	   " WHERE data_e_ora_frcst >= ",str_data_e_ora_del, " AND suffix_model LIKE '%",suffix_model,"%'", sep='')
   } 
   return(QueryDelete) 
  
}

###############################################################################
#command line arguments

#args <- commandArgs(TRUE)
#directory di alloggiamento dei files temporanei
#id_centro=args[1]
id_centro<-'cosmo'
#id_centro<-'ecmwf'

if(id_centro=='ecmwf') {
  suffix='EC'
} else {
  suffix='C5M'
}

# flag se scrivere i dati interpolati in un csv
#w_df=args[2]
w_df='wcsv'

###############################################################################
# Decodifica forecast netcdf estraggo orografia (o geop di superficie), t2m , u10, v10  
# geop -> metri
conv_metri=0.101972 
if(suffix=='EC') {
ncfile_surf <- nc_open(paste(dirin,"/sorted_surf_",suffix,".nc",sep=''))
z   <- ncvar_get(ncfile_surf, "z")
z <- conv_metri*z

t2m <- ncvar_get(ncfile_surf, "t2m")
u10 <- ncvar_get(ncfile_surf, "u10")
v10 <- ncvar_get(ncfile_surf, "v10")




	} else {
	ncfile_surf <- nc_open(paste(dirin,"/sorted_surf_",suffix,".nc",sep=''))
	z <- ncvar_get(ncfile_surf, "p3008")
        # in cosmo5m  p3008 è gia' in metri.
	t2m <- ncvar_get(ncfile_surf, "t2m")
	u10 <- ncvar_get(ncfile_surf, "u10")
	v10 <- ncvar_get(ncfile_surf, "v10")
	
}


#ricavo i valori di latitudine, longitudine e tempo
lat  <- ncvar_get(ncfile_surf, "latitude")
lon  <- ncvar_get(ncfile_surf, "longitude")
time_nc <- ncvar_get(ncfile_surf, "time")



if (suffix == 'EC') {
	nscad <-25	#Voglio solo le prime 72h di ECMWF
		} else {
			nscad <- dim(time_nc)
}
nlat  <-dim(lat)
nlon  <-dim(lon)


###############################################################################
# Elaborazione variabili (Temperatura e Vento)

# Inperpolazione Temperatura 2m su stazioni rete INM pubbliche (formweb=Y)

#Carico l'anagrafica Stazioni Temperatura
stazioni<-read.csv("stazioni_T_formweb.csv", header = TRUE, sep=';',colClasses = "character")
names(stazioni)<-c("denominazione","idstazione","latitudine","longitudine","quota","altezza","idsensore","nometipologia")
#

#calcolo latitudine e longitudine in gradi sessadecimali
latitude <- stazioni$latitudine
longitude <- stazioni$longitudine

# alla quota eventualmente aggiungere il parametro altezza
quota<-stazioni$quota

coord_stazioni<-cbind(longitude,latitude)
npunti<-dim(coord_stazioni)[1]

#interpolazione sui punti stazione
z_int	<- interpola(z,lon,lat,coord_stazioni)
t2m_int <- interpola(t2m,lon,lat,coord_stazioni)



# Elaboro tutti i passi temporali codificati nel netcdf
# Attenzione, Cosmo passo temporale 1h, ecmwf 3h. 
deltat=1
# con firststep=1 considero anche l'analisi
firststep=1

time<-as.POSIXlt(time_nc*3600, origin = "1900-01-01", tz = "GMT")

hours <- sprintf("%02d", time$hour)
#days <-sprintf("%02d", time$mday)
#month<-sprintf("%02d", time$mon+1)
#year <-time$year+1900
#datarun <- paste(year[1],month[1],days[1],sep='')

datarun <-strftime(time[1], "%Y%m%d%H")

hhrun <- hours[1]
#to do: se voglio elaborare solo i run delle 00, mettere quit(save = "default", status = 0) nel caso di hhrun==12


#dimensioni temporali finali
nscad_wrt=1+((nscad-firststep)/deltat)

#sistemo i dati da scrivere sul dataframe T
var_write<-array(0,c(npunti,nscad_wrt))
var_write_corr<-array(0,c(npunti,nscad_wrt))

# Lapse rate per correzione della temperatura per differenza tra orografia del modello e quota stazione . 
# Attenzione potrebbe non essere ottimale nelle valli chiuse o in situazioni di inversione, 
# Eventualmente diversificare per notte e giorno nelle valli. 
fatt_corr=0.0065
# Se non si vuole correggere la temperatura con la quota, mettere a zero il lapse rate!
#fatt_corr=0.0

i=1
ini<-"T"
for (t in seq(from=firststep,to=nscad,by=deltat)){
  # per qualche motivo l'opzione tz = "CET" non funziona, 
  # quindi aggiungo 1h e lascio esplicita l'opzione tz = "GMT"  
  date_CET <- time[t] + 3600
  sdate_CET <- strftime(date_CET, "%Y%m%d%H",tz = "GMT")
  #print(paste(t,sdate_CET,sep=' '))
  if (ini) {
    stringDate_CET <- sdate_CET
    date_CET_ini<-date_CET
    model_orogr<-z_int[,t]
    diff_orogr<-as.integer(model_orogr)-as.integer(quota)
    Tcorrection<-diff_orogr*fatt_corr 
    ini<-"F"
  } else {
    stringDate_CET<-paste(stringDate_CET,sdate_CET,sep=',')

  } 

  var_write[,i]<-t2m_int[,t] -273.15
  var_write_corr[,i]<-t2m_int[,t] + Tcorrection -273.15
  i<-i+1  
}

var_write<-round(var_write,1)
var_write_corr<-round(var_write_corr,1)

#elaborazione stringhe date scadenze
str_date_CET_tmp<-strsplit(stringDate_CET, ",")
str_date_CET<-str_date_CET_tmp[[1]]



# elaboro e ordino tutti i dati per costruire un dataframe con anagrafica e valori di forecast

idstazione <- as.integer(stazioni$idstazione)
idsensore<- as.integer(stazioni$idsensore)
nometipologia <- stazioni$nometipologia
anagrf <- data.frame("idstazione" = idstazione, "idsensore" = idsensore,"nometipologia" = nometipologia,"latitudine"=as.numeric(stazioni$latitudine),"longitudine"=as.numeric(stazioni$longitudine),"diff_orogr"=diff_orogr,stringsAsFactors=FALSE)
values<- data.frame(var_write,stringsAsFactors=FALSE)
colnames(values, do.NULL = FALSE)
colnames(values) <- str_date_CET
df_T<-cbind(anagrf,values)

# creo df per valori corretti di VV
values_T_corr<- data.frame(var_write_corr,stringsAsFactors=FALSE)
colnames(values_T_corr, do.NULL = FALSE)
colnames(values_T_corr) <- str_date_CET

####################################################################################
#Carico l'anagrafica Stazioni Vento (sensori VV e DV)
stazioni<-read.csv("stazioni_V_formweb.csv", header = TRUE, sep=';',colClasses = "character")
names(stazioni)<-c("denominazione","idstazione","latitudine","longitudine","quota","altezza","idsensore1","nometipologia1","idsensore2","nometipologia2")

#calcolo latitudine e longitudine in gradi sessadecimali
latitude <- stazioni$latitudine
longitude <- stazioni$longitudine

# alla quota eventualmente aggiungere il parametro altezza
quota<-stazioni$quota

coord_stazioni<-cbind(longitude,latitude)
npunti<-dim(coord_stazioni)[1]

#interpolazione vento sui punti stazione
#il vento del cosmo e' stato antiruotato in fase di ritaglio del dominio
z_int	<- interpola(z,lon,lat,coord_stazioni)
u10_int <- interpola(u10,lon,lat,coord_stazioni)
v10_int <- interpola(v10,lon,lat,coord_stazioni)
#

#sistemo i dati da scrivere sul dataframe VV e DV
conv_rad2deg=(90./acos(0.))

var_write_VV<-array(0,c(npunti,nscad_wrt))
var_write_DV<-array(0,c(npunti,nscad_wrt))

var_write_VV_corr<-array(0,c(npunti,nscad_wrt))
var_write_DV_corr<-array(0,c(npunti,nscad_wrt))

library("numbers")
i=1
ini<-"T"
for (t in seq(from=firststep,to=nscad,by=deltat)){

  if (ini) {
     model_orogr<-z_int[,t]
     ini<-"F"
  }

  #var_write_VV[,i]<-norm(c(u10_int[,t],v10_int[,t]), type="2")
  var_write_VV[,i]<-sqrt((u10_int[,t])^2+(v10_int[,t])^2)
  var_write_DV[,i]<-270.-atan2(v10_int[,t],u10_int[,t])*conv_rad2deg
  # approssimo e riconduco le direzioni all'intervallo 0 - 360 
  var_write_DV[,i]<-round(var_write_DV[,i],0)
  var_write_DV[,i]<-(mod(var_write_DV[,i],360))
  i<-i+1  
}

var_write_VV<-round(var_write_VV,1)

# se in futuro voglio applicare all'output diretto dal modello una correzione o un filtro, inserire qui!  
var_write_VV_corr <- var_write_VV
var_write_DV_corr <- var_write_DV

# elaboro e ordino tutti i dati per costruire un dataframe con anagrafica e valori di forecast di VV e DV

idstazione <- as.integer(stazioni$idstazione)
idsensore<- as.integer(stazioni$idsensore1)

diff_orogr<-as.integer(model_orogr) - as.integer(quota)

nometipologia <- stazioni$nometipologia1
anagrf <- data.frame("idstazione" = idstazione, "idsensore" = idsensore,"nometipologia" = nometipologia,"latitudine"=as.numeric(stazioni$latitudine),"longitudine"=as.numeric(stazioni$longitudine),"diff_orogr"=diff_orogr,stringsAsFactors=FALSE)
values<- data.frame(var_write_VV,stringsAsFactors=FALSE)
colnames(values, do.NULL = FALSE)
colnames(values) <- str_date_CET
#write.csv(var_write, file = nomefile, row.names = FALSE)
df_VV<-cbind(anagrf,values)

# creo df per valori corretti di VV
values_VV_corr<- data.frame(var_write_VV_corr,stringsAsFactors=FALSE)
colnames(values_VV_corr, do.NULL = FALSE)
colnames(values_VV_corr) <- str_date_CET

#DV
idsensore<- as.integer(stazioni$idsensore2)
nometipologia <- stazioni$nometipologia2
anagrf <- data.frame("idstazione" = idstazione, "idsensore" = idsensore,"nometipologia" = nometipologia,"latitudine"=as.numeric(stazioni$latitudine),"longitudine"=as.numeric(stazioni$longitudine),"diff_orogr"=diff_orogr,stringsAsFactors=FALSE)
values<- data.frame(var_write_DV,stringsAsFactors=FALSE)
colnames(values, do.NULL = FALSE)
colnames(values) <- str_date_CET
#write.csv(var_write, file = nomefile, row.names = FALSE)
df_DV<-cbind(anagrf,values)

# creo df per valori corretti di DV
values_DV_corr<- data.frame(var_write_DV_corr,stringsAsFactors=FALSE)
colnames(values_DV_corr, do.NULL = FALSE)
colnames(values_DV_corr) <- str_date_CET

###################################################################################
# Unisco i dataframe T, VV e DV eventualmente salvo in un file csv 

df_T_VV_DV <- rbind(df_T, df_VV,df_DV)

df_corr <- rbind(values_T_corr, values_VV_corr,values_DV_corr)

# 
if (w_df=='wcsv') {

if(suffix=='C5M'){
		nomefile <- paste(dirout,"cosmo_T_VV_DV.csv",sep="")
		nomefile_corr <- paste(dirout,"cosmo_T_VV_DV_corr.csv",sep="")
	} else {
		nomefile <- paste(dirout,"ecmwf_T_VV_DV.csv",sep="")
		nomefile_corr <- paste(dirout,"ecmwf_T_VV_DV_corr.csv",sep="")
	}
	
#print (paste("salvo i dati interpolati in ",file,sep=""))
write.csv(df_T_VV_DV, file = nomefile,row.names = FALSE)
write.csv(df_corr, file = nomefile_corr,row.names = FALSE)
}


###################################################################################
# Salvo su dbIris
store_interp=TRUE
#store_interp=FALSE
if(store_interp) {

library(DBI)
# Connect to a specific postgres database 
#db = 'iris_devel'
db = 'iris_base'
tabella_db='realtime.m_modelli_forec'

#HOST_dbIRS='10.10.0.19'
#PORT_dbIRS=5432
#USER_dbIRS='postgres'
#PASS_dbIRS='p0stgr3S'

HOST_dbIRS  <-Sys.getenv("HOST_dbIRS")
PORT_dbIRS  <-Sys.getenv("PORT_dbIRS")
USER_dbIRS  <-Sys.getenv("USER_dbIRS")
PASS_dbIRS  <-Sys.getenv("PASS_dbIRS")



conn <- dbConnect(RPostgres::Postgres(),
                 dbname = db, 
                 host = HOST_dbIRS,
                 port = PORT_dbIRS,
                 user = USER_dbIRS,     # se fosse shell interattiva:  rstudioapi::askForPassword("Database user")
                 password = PASS_dbIRS) #rstudioapi::askForPassword("Database password")


ini_db='False'
# affinche' non ci siano violazioni sulla chiave primaria data_e_ora_frcst nel db Iris cancello i record con data_e_ora_frcst >= data_run
QueryDelete<-set_string_delete(tabella_db,date_CET_ini,suffix,purge='False',n_days_del=14)
# cancellare i record con data < data_run -14 gg
#print(QueryDelete)
query <- dbSendQuery(conn,QueryDelete)

# Elimino anche i dati interpolati più vecchi di 14 gg per non appesantire il db, in analogia con la pulizia dei dati osservati. 
QueryDelete<-set_string_delete(tabella_db,date_CET_ini,suffix,purge='True',n_days_del=14)
query <- dbSendQuery(conn,QueryDelete)
#print(QueryDelete)
ini_db='True'
#Fine inizializzazione db Iris 

#Preparo la INSERT dei dati interpolati 
string_insert<-paste("INSERT into",tabella_db,sep=' ')
string_fields_insert<-"(id_sensore,id_stazione,nometipologia,data_e_ora_frcst,misura,misura_corr,suffix_model,dh_m_s,data_run)"

# Ciclo su tutti i sensori interpolati (idx i) e su tutte le scadenze (idx t) 
#i=nrow(df_T_VV_DV)

data_run=time[1]
print (paste('Scrivo i dati interpolati da ',suffix,', corsa', data_run,'in', db,sep=' '))

for(i in 1:nrow(df_T_VV_DV)){
     for(t in 1:nscad_wrt){
        string_values_insert <-set_string_values_insert (df_T_VV_DV,df_corr,i,t,time[1],str_date_CET,suffix)
        Query_Insert<-paste(string_insert,string_fields_insert,"VALUES",string_values_insert ,sep=' ')
        #print(Query_Insert)
        query <- dbSendQuery(conn,Query_Insert)    
        }

}

# Disconnetto R dal db Iris
dbDisconnect(conn)

}

 


