#!/bin/bash
corsa=$1 # passare l'xml della corsa in formato model_yyyymmddhhmm.xml

# pathxmlin="/home/meteo/Scrivania/previ_auto/xml_completi" # path dell'xml di input
# pathxmlout="/home/meteo/Scrivania/previ_auto/xml_province" # path degli xml di output
# pathhtmlout="/home/meteo/Scrivania/previ_auto/html_province" # path degli html di output

local_dirinput="/home/meteo/ciumbia/archivio/xml"  
local_diroutput="/home/meteo/ciumbia/archivio/xml_eventi"
dir_appoggio="/home/meteo/ciumbia/archivio/xml_eventi/appoggio"
xmlin=${local_dirinput}/${corsa}
daxml=${dir_appoggio}/daxml_papa.txt
body=${dir_appoggio}/body_previ_papa.txt
head=${dir_appoggio}/head_previ_papa.txt
foot=${dir_appoggio}/foot_previ_papa.txt

#Scelta nome file di output in base al tipo di modello (per completare correttamente la dicitura comprensiva del run)
if [ ${corsa:0:3} = "ecm" ]; then
xmlout=${local_diroutput}/${corsa:0:3}${corsa:5:13}.xml
else
xmlout=${local_diroutput}/${corsa:0:3}${corsa:5:13}.xml
fi

#htmlout=${pathhtmlout}/${corsa:0:18}_
#
#
### PRODUZIONE XML DEL COMUNE DI MILANO
#
# Estrae solo le righe di Milano (dall'xml originale solo le righe con id=146 e prov=015)
#
awk '$2 == "id=\"146\"" && $3== "prov=\"015\""' ${xmlin} > ${daxml}
#
# Aggiusta la sintassi (nell'originale manca "/" a chiusura del campo "Comune"
#
#sed -e 's/\">/\" \/>/g' ${daxml} > ${body}
#... se invece non si vuole aggiustare la sintassi si commenta la riga precedente e si attiva la seguente
cp ${daxml} ${body}
#
# Aggiunge header e footer (cioè i pezzi mancanti perchè l'xml prodotto sia formalmente corretto)
#
cat ${head} ${body} ${foot} > ${xmlout}
#
# if [ ${corsa:14:2} = "12" ]; then
 	# xmlbackup=${dir_appoggio}/${corsa:0:3}bk${corsa:5:9}0000.xml
	# awk '(NR < 3 ) || (NR > 4) { print $0 }' ${xmlout} > ${xmlbackup}
# fi
#
# PRODUZIONE HTML DEI CAPOLUOGHI DI PROVINCIA
#
# Pero
#awk -F "\"" '{print "<tr><td> "$6" <\/td><td width=50px><img src=\"ico\/"$10".png\"><\/img> <\/td><td> prec "$12"  mm <\/td><td> Tmin "$14" <\/td><td> Tmax "$16"<\/td><td> VV "$18" <\/td><td> DV "$20" <\/td><\/tr>"}' ${xmlout}Varese.xml > ${htmlout}Varese.html
#
### FINE script ---------------------------------------------------------------
#
#Memo:
#il file head_previ_expo.txt contiene le seguenti due righe:
# <?xml version='1.0' encoding="iso-8859-1" ?>
# <ARPALombardiaComuniForecast>
#
#il file foot_previ_expo.txt contiene la seguente riga:
# </ARPALombardiaComuniForecast>

