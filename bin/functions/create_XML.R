createXML <- function(id_comune,prov,scadenza,date,output,nomefile,dirout) {


ncomuni<-length(id_comune)
riga = character(ncomuni)

for (n in 1:ncomuni){
  riga[n]<-paste('<comune id=',id_comune[n],' prov=',prov[n],' oraUTC=',scadenza,' data=',date,
                 ' icona=',sprintf("%02d",output$field_icone[n]),
                 ' precipitazione=',sprintf("%5.1f",output$field_precipitazione[n]),
                 ' Tmin=',sprintf("%5.1f",output$field_temperatura_min[n]),
                 ' Tmax=',sprintf("%5.1f",output$field_temperatura_max[n]),
                 ' ModVento=',sprintf("%5.1f",output$field_vento_mod[n]),
                 ' DirVento=',sprintf("%7.2f",output$field_vento_dir[n]),'>',sep='"') 

  write(riga[n],file=paste(dirout,'/',nomefile,'.xml',sep=''),sep='\n',append=TRUE)
}

}

