library(httr)
library(lubridate)

user<-"ou\\pi-api-public"
password<-"M53$dx7,d3fP8"

getAPIlink<-function(link){
  api.link<-GET(link,authenticate(user,password))
  return(api.link)
}

base<-"https://bldg-pi-api.ou.ad3.ucdavis.edu/piwebapi/streams/"
interp<-"/interpolated"

getQuery<-function(build,util,var,start="",end="",interval=""){
  the.url<-ucd.utils.df[ucd.utils.df[,1]==build&ucd.utils.df[,3]==util&ucd.utils.df[,4]==var,5]
  the.url<-paste0(base,the.url,interp)
  if(start!=""){
    the.url<-paste0(the.url,"?startTime=",start)
  }
  if(end!="" & start!=""){
    the.url<-paste0(the.url,"&endTime=",end)
  }
  if(interval!=""){
    the.url<-paste0(the.url,"&interval=",interval)
  }
  parsed.url<-content(getAPIlink(the.url))
  num.values<-length(parsed.url$Items)
  timestamps<-sapply(1:num.values,function(i)parsed.url$Items[[i]]$Timestamp)
  values<-sapply(1:num.values,function(i){
    if(length(parsed.url$Items[[i]]$Value)>1)
      return(NA)
    else
    return(parsed.url$Items[[i]]$Value)})
  if(is.list(values)==TRUE){
    return(NA)
  }
  query.df<-data.frame(values,timestamps)
  query.df[,1]<-as.numeric(as.character(query.df[,1]))
  query.df[,2]<-with_tz(ymd_hms(as.character(query.df[,2])),"US/Pacific")
  return(query.df)
}

getVar<-function(util,var,start="",end="",interval=""){
  building.subset<-ucd.utils.df[ucd.utils.df[,3]==util&ucd.utils.df[,4]==var,1]
  building.data<-lapply(1:length(building.subset),function(x){
    q<-getQuery(building.subset[x],util,var,start,end,interval)
    print(x)
    return(q)})
  building.df<-lapply(which(sapply(building.data,length)>1),function(x)cbind(building.subset[x],building.data[[x]]))
  building.df<-do.call(rbind,building.df)
  names(building.df)[1]<-"BuildingName"
  buildingsXY<-join(building.df,bxy2)
  buildingsXY<-buildingsXY[which(is.na(buildingsXY[,4])==FALSE),]
  return(buildingsXY)
}

getPlot<-function(time){
  
}

metaXY<-data.frame(CAAN=as.numeric(as.character(metadf$assetNumber)),latitude=as.numeric(as.character(metadf$latitude)),longitude=as.numeric(as.character(metadf$longitude)))

