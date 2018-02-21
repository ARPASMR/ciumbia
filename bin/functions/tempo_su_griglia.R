library(ncdf4)
library(fields)

fun_dir <-Sys.getenv("fun_dir")
dirin  <-Sys.getenv("TMPCIU")
dirout <-Sys.getenv("XMLCIU")

#Saranno da commentare (e quindi li commentiamo)
#dirin <- '/home/meteo/ciumbia/tmp'
#dirout <- '/home/meteo/ciumbia/archivio'
#fun_dir <- '/home/meteo/ciumbia/bin/functions'

#Script accessori
source(paste(fun_dir,'/functions.R',sep=''))
source(paste(fun_dir,'/elabora_prev.R',sep=''))
source(paste(fun_dir,'/create_XML.R',sep=''))

args <- commandArgs(TRUE)
#directory di alloggiamento dei files temporanei
id_centro=args[1]


if(id_centro=='ecmwf') {
  suffix='EC'
} else {
  suffix='C5M'
}

if(suffix=='EC') {
ncfile_surf <- nc_open(paste(dirin,"/surf_",suffix,".nc",sep=''))
z   <- ncvar_get(ncfile_surf, "z")
sf  <- ncvar_get(ncfile_surf, "sf")
tp  <- ncvar_get(ncfile_surf, "tp")
t2m <- ncvar_get(ncfile_surf, "t2m")
d2m <- ncvar_get(ncfile_surf, "d2m")
u10 <- ncvar_get(ncfile_surf, "u10")
v10 <- ncvar_get(ncfile_surf, "v10")
tcc <- ncvar_get(ncfile_surf, "tcc")
hcc <- ncvar_get(ncfile_surf, "hcc")
mcc <- ncvar_get(ncfile_surf, "mcc")
lcc <- ncvar_get(ncfile_surf, "lcc")
mx2t3 <- ncvar_get(ncfile_surf, "mx2t3")
mn2t3 <- ncvar_get(ncfile_surf, "mn2t3")


	} else {
	ncfile_surf <- nc_open(paste(dirin,"/surf_",suffix,".nc",sep=''))
	z <- ncvar_get(ncfile_surf, "p3008")
	mx2t1 <- ncvar_get(ncfile_surf, "mx2t6")
	mn2t1 <- ncvar_get(ncfile_surf, "mn2t6")
	tp  <- ncvar_get(ncfile_surf, "tp")
	sf  <- ncvar_get(ncfile_surf, "lssf")
	t2m <- ncvar_get(ncfile_surf, "t2m")
	d2m <- ncvar_get(ncfile_surf, "d2m")
	u10 <- ncvar_get(ncfile_surf, "u10")
	v10 <- ncvar_get(ncfile_surf, "v10")
	tcc <- ncvar_get(ncfile_surf, "tcc")
	hcc <- ncvar_get(ncfile_surf, "hcc")
	mcc <- ncvar_get(ncfile_surf, "mcc")
	lcc <- ncvar_get(ncfile_surf, "lcc")
	
}



if (suffix=='EC') {

	ncfile_pres <- nc_open(paste(dirin,"/pres_",suffix,".nc",sep=''))
	t <- ncvar_get(ncfile_pres, "t")
	q <- ncvar_get(ncfile_pres, "q")

	#t[lon,lat,level,time]
	t500 <- t[,,1,]
	t700 <- t[,,2,]
	t850 <- t[,,3,]
	#t1000<- t[,,4,]
	
	
	#definisco i vari livelli di pressione
	p500 <- 500
	p700 <- 700
	p850 <- 850

	#r[lon,lat,level,time] 
	q500 <- q[,,1,] 
	q700 <- q[,,2,]
	q850 <- q[,,3,]
	
	#calcolo rh a partire da q,t e p (costante) 
	r500 <- q2r (q500,t500,p500)
	r700 <- q2r (q700,t700,p700)
	r850 <- q2r (q850,t850,p850)
	
	#calcolo il dewpoint che mi servira per il calcolo del K index
	td500 <- rh2dewpoint(r500,t500)
	td700 <- rh2dewpoint(r700,t700)
	td850 <- rh2dewpoint(r850,t850)

	#calcolo K index o indice di Whiting
	kind <- kindex(t850,t500,td850,t700,td700)
} else {

	ncfile_pres <- nc_open(paste(dirin,"/pres_",suffix,".nc",sep=''))
	t <- ncvar_get(ncfile_pres, "t")
	r <- ncvar_get(ncfile_pres, "r")
	
	#t[lon,lat,level,time]
	t500 <- t[,,1,]
	t700 <- t[,,2,]
	t850 <- t[,,3,]
#	t1000<- t[,,4,]
	
	#r[lon,lat,level,time] 
	rh500 <- r[,,1,] 
	rh700 <- r[,,2,]
	rh850 <- r[,,3,]
	#calcolo il dewpoint che mi servira per il calcolo del K index
	td500 <- rh2dewpoint(rh500,t500)
	td700 <- rh2dewpoint(rh700,t700)
	td850 <- rh2dewpoint(rh850,t850)

	#calcolo K index o indice di Whiting
	kind <- kindex(t850,t500,td850,t700,td700)
	
	}


#Ricavo umidità relativa a 2m
rh2m <- dewpoint2rh(d2m,t2m)

#scumulo la pioggia e la neve
prec <- scumula(tp)
snow <- scumula(sf)

#ricavo i valori di latitudine, longitudine e tempo
lat  <- ncvar_get(ncfile_surf, "latitude")
lon  <- ncvar_get(ncfile_surf, "longitude")
time <- ncvar_get(ncfile_surf, "time")


t<-as.POSIXlt(time*3600, origin = "1900-01-01", tz = "GMT")


hours <- sprintf("%02d", t[[3]])
days <-sprintf("%02d", t[[4]])
month<-sprintf("%02d", t[[5]]+1)
year <-t[[6]]+1900
scadenze<-paste(sprintf("%02d", t[[3]]),sprintf("%02d", t[[3]]+6),sep='-')




if (suffix == 'EC') {
	nscad <-25	#Voglio solo le prime 72h di ECMWF
		} else {
			nscad <- dim(time)
}
nlat  <-dim(lat)
nlon  <-dim(lon)

###################################################################
#carico il file con i comuni italiani
#comuni<-read.csv('Coord_loc_2001_minimal_ll.csv')
#names(comuni)<-c("LOC2001","COD_REG","COD_PRO","PRO_COM","LOC","DENOM_LOC","CENTRO_CL","ALTITUDINE","POP2001","LONGITUDE","LATITUDE","TIPO_LOC")

comuni<-read.csv(paste(fun_dir,'/Comuni.csv',sep=''))
names(comuni)<-c("ID_REG","ID_PROV","ID_COMUNE","GLAT","PLAT","SLAT","GLON","PLON","SLON","ALT","ALT_MIN","ALT_MAX","SUP","POP","NOME","PROV")

#calcolo latitudine e longitudinein gradi sessagesimali
latitude <- comuni$GLAT + comuni$PLAT/60 + comuni$SLAT/3600
longitude <- comuni$GLON + comuni$PLON/60 + comuni$SLON/3600

#aggungo nel dataframe le colonne con le latitudini e le longitudini in gradi sessagesimali
comuni$LATITUDE <- latitude
comuni$LONGITUDE <- longitude

#carico solo i comuni lombardi
comuni_lomb<-comuni[which(comuni$ID_REG==3),]
ncomuni<-length(comuni_lomb[,1])

altezza<-comuni_lomb$ALT
lat_comuni<-comuni_lomb$LATITUDE
lon_comuni<-comuni_lomb$LONGITUDE
coord_comuni<-cbind(lon_comuni,lat_comuni)


#interpolazione sui punti stazione
z_int	<- interpola(z,lon,lat,coord_comuni)
t2m_int <- interpola(t2m,lon,lat,coord_comuni)
d2m_int <- interpola(d2m,lon,lat,coord_comuni)
u10_int <- interpola(u10,lon,lat,coord_comuni)
v10_int <- interpola(v10,lon,lat,coord_comuni)
tcc_int <- interpola(tcc,lon,lat,coord_comuni)
hcc_int <- interpola(hcc,lon,lat,coord_comuni)
mcc_int <- interpola(mcc,lon,lat,coord_comuni)
lcc_int <- interpola(lcc,lon,lat,coord_comuni)
prec_int <- interpola(prec,lon,lat,coord_comuni)
snow_int <- interpola(snow,lon,lat,coord_comuni)
kind_int <- interpola(kind,lon,lat,coord_comuni)
rh2m_int <- interpola(rh2m,lon,lat,coord_comuni)


if (suffix=='EC') {
	mx2t3_int <- interpola(mx2t3,lon,lat,coord_comuni)
	mn2t3_int <- interpola(mn2t3,lon,lat,coord_comuni)
	mx2t6_int <- interpola(mx2t3,lon,lat,coord_comuni)
	mn2t6_int <- interpola(mn2t3,lon,lat,coord_comuni)
	} else {
		mx2t1_int <- interpola(mx2t1,lon,lat,coord_comuni)
		mn2t1_int <- interpola(mn2t1,lon,lat,coord_comuni)
		mx2t6_int <- interpola(mx2t1,lon,lat,coord_comuni)
		mn2t6_int <- interpola(mn2t1,lon,lat,coord_comuni)
}



#L'obbiettivo rimane quello di costruire step esaorari. Per questo motivo è necessario trattare diversamente i due modelli (ecmwf lavora su step 3h, cosmo 5M su step 1h)
#Fisso quindi il passo (delta) e da dove iniziare (firststep)


if(id_centro=='ecmwf') {
  deltat=1
  firststep=2
} else {
  deltat=6
  firststep=1
}


datarun <- paste(year[1],month[1],days[1],sep='')
run <- hours[1]
if(suffix=='C5M'){
		nomefile <- paste("cosmo_",datarun,run,"00",sep="")
	} else {
		nomefile <- paste("ecmwf_",datarun,run,"00",sep="")
	}

#nomefile <- paste(id_centro,datarun,run,sep='_')


################################################################################
#################SCRITTURA FILE XML#############################################
################################################################################

#scrivo intestazione di file xml
intestazione <- paste("<?xml version='",sprintf("%2.1f",1.0),"' encoding='iso-",8859,"-",1,"' ?>",sep='')
write(intestazione,file=paste(dirout,'/',nomefile,'.xml',sep=''),sep='\n',append=TRUE)
write('<ARPALombardiaComuniForecast>',file=paste(dirout,'/',nomefile,'.xml',sep=''),sep='\n',append=TRUE)

#Il seguente ciclo permette di valutare tutti i parametri secondo le giuste scadenze in maniera tale da avere il riassunto delle informazioni ogni 6h
#Dove ho bisogno di riassumere 6 h (tmin, tmax e prec) valuto a parte...per gli altri parametri considero la scadenza temporale di mio interesse.

for (t in seq(from=firststep,to=nscad,by=deltat)){
  if(t==2) {
    tcc_int[,t-1]=tcc_int[t]
    hcc_int[,t-1]=hcc_int[t]
    mcc_int[,t-1]=mcc_int[t]
    lcc_int[,t-1]=lcc_int[t]
    t2m_int[,t-1]=t2m_int[t]
    d2m_int[,t-1]=d2m_int[t]
	
   } 	else if((t%%2 > 0)&&(t > 2)){ 
			if(suffix=='EC'){
   
		mx2t6_int[,t]=apply(mx2t3_int[,(t-1):t],1,max)
		mn2t6_int[,t]=apply(mn2t3_int[,(t-1):t],1,min)
		prec_int[,t]=apply(prec_int[,(t-1):t],1,sum)
			}					
		else  {
			mx2t6_int[,t]=apply(mx2t1_int[,(t-5):t],1,max)
			mn2t6_int[,t]=apply(mn2t1_int[,(t-5):t],1,min)
			prec_int[,t]=apply(prec_int[,(t-5):t],1,sum)
		}
	
	
	output<-elabora_prev(z_int[,t],t2m_int[,(t-1):t],d2m_int[,(t-1):t],u10_int[,(t-1):t],v10_int[,(t-1):t],
                         tcc_int[,(t-1):t],hcc_int[,(t-1):t],mcc_int[,(t-1):t],lcc_int[,(t-1):t],
                         prec_int[,t],snow_int[,t],kind_int[,(t-1):t],mx2t6_int[,t],mn2t6_int[,t],
                         rh2m_int[,(t-1):t],id_centro)
	
  date <- paste(year[t-1],month[t-1],days[t-1],sep='')


  prov <- sprintf("%03d",comuni_lomb$ID_PROV)
  id_comune <- sprintf("%03d",comuni_lomb$ID_COMUNE)
 
  if ( suffix=='C5M'){
  createXML(id_comune,prov,scadenze[t-6],date,output,nomefile,dirout)
  } else {
  createXML(id_comune,prov,scadenze[t-2],date,output,nomefile,dirout)	
  }
 }
}

#scrivo chiusura file xml
write('</ARPALombardiaComuniForecast>',file=paste(dirout,'/',nomefile,'.xml',sep=''),sep='\n',append=TRUE)
 


