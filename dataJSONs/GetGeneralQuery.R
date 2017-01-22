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
  query.df<-data.frame(values,timestamps)
  query.df[,1]<-as.numeric(as.character(query.df[,1]))
  query.df[,2]<-with_tz(ymd_hms(as.character(query.df[,2])),"US/Pacific")
  return(query.df)
}