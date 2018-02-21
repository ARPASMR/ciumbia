interpola<-function(var,lon,lat,punti) {

#-------------------------------------------------------
# Interpolazione sui punti stazione a partire da un 
# grigliato 
#-------------------------------------------------------
#var : grigliato tridimensionale che rappresenta la 
#variabile da interpolare var[nlon,nlat,nscad]
#lon e lat sono i vettori contenenti le latitudini e le 
#longitudini del grigliato
#punti: array contenente le longitudini e le latitudini dei
#comuni su cui interpolare la variabile
#nscad: numero di scadenze 

#restituisce un vettore npuntixnscad che contiene i valori
#interpolati della variabile sui punti stazione


# loop sulle scadenze per la creazione dei vettori interpolati
# sui punti

nlat  <-dim(lat)
nscad <-dim(var)[3]
npunti<-dim(punti)[1]

var_int<-array(0,c(npunti,nscad))

for (t in 1:nscad){
  var_obj<-list( x=lon, y=rev(lat), z=var[,nlat:1,t])
  var_int[,t]<-interp.surface(var_obj,punti)
}

return(var_int)

}

q2r<- function(q,t,p) {
# es <-  6.112 * exp((17.67 * temp)/(temp + 243.5))
# e <- qair * press / (0.378 * qair + 0.622)
# rh <- e / es
# rh[rh > 1] <- 1
# rh[rh < 0] <- 0
	
#Risolvo a pezzi la seguente formula:
#rh=0.263*p*100*q*[exp(17.67*(t-273.16)/(t-29.65))]^(-1)

espo=exp(17.67*(t-273.16)/(t-29.65))
invespo=1/espo
r=q*0.263*p*100*invespo	

# Uso quest'altra formula
#rh=160.7717*q*p/esat(t)

return (r)

}

dewpoint2rh<-function(td,t) {

 dptconst_b=17.627  #Alduchov and Eskridge, 1996 (*)
 dptconst_c=243.04  #Alduchov and Eskridge, 1996 (*)

 #conversione da kelvin a gradi centigradi 
 td=td-273.15
 t=t-273.15


 a=dptconst_b*td/(dptconst_c+td)
 b=dptconst_b*t/(dptconst_c+t)
 rh=100*exp(a-b)
   
 return(rh)

}

rh2dewpoint<-function(rh,t) {

 dptconst_b=17.627  #Alduchov and Eskridge, 1996 (*)
 dptconst_c=243.04  #Alduchov and Eskridge, 1996 (*)

 #conversione da kelvin a gradi centigradi 
 t=t-273.15

 gamma=log(0.01*max(0.01,rh))+dptconst_b*t/(dptconst_c+t)
 td=dptconst_c*gamma/(dptconst_b-gamma)
   
 return(td)

}

kindex <- function(t850,t500,td850,t700,td700) {
 k <- (t850-t500) + td850 - abs(t700-273.15-td700)

 return(k)
}

scumula <- function(var) {

 nscad <-dim(var)[3]
 nlon  <-dim(var)[1]
 nlat  <-dim(var)[2]

 var_scumulata <- array(0,c(nlon,nlat,nscad))

  for (t in 2:nscad){
   var_scumulata[,,t]<-var[,,t]-var[,,t-1]
  }

 return(var_scumulata)

}


