# PREDICTIVE MODELING 

#Step 1: Clean up the data 
sum(is.na(metadf2$Key))
metadf2$Key <- NULL
#sum(is.na(metadf2$Demolished))
metadf2$featid <- NULL
data <- unique(metadf2)
data$Facilities.Code <- NULL
data$Architect <- NULL
data$Style <- NULL
data$City <- NULL
data$Address <- NULL
data$County <- NULL
data$State <- NULL
data$Country <- NULL
data$City.Code <- NULL
data$County.Code <- NULL
data$Zip.Code <- NULL
data$Perimeter <- NULL
data$Floor.Plans.DWG <- NULL


all <- merge(data, ucdutils2, by.x = "Official.Name", by.y = "BuildingName")
#Primary.Use, UBC.code, Planning, Condition, Floors, Height, Footprint,Prim..Usage..Percent.of.Net.Useable.,Primary.Usage..Type, Floor.Plans.PDF

all_eui <- ucdutils2[ucdutils2$Var == 'Electricity_EUI',]
user<-"ou\\pi-api-public"
password<-"M53$dx7,d3fP8"

getAPIlink<-function(link){
  api.link<-GET(link,authenticate(user,password))
  return(api.link)
}
str <- "https://bldg-pi-api.ou.ad3.ucdavis.edu/piwebapi/streams/"


base<-"https://bldg-pi-api.ou.ad3.ucdavis.edu/piwebapi/streams/"
interp<-"/interpolated"

ucd.utils.df  <- ucdutils2


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


namesR <- unique(ucdutils2$BuildingName)
getVar<-function(util,var,start="",end="",interval=""){
  building.subset<-ucd.utils.df[ucd.utils.df[,3]==util&ucd.utils.df[,4]==var,1]
  building.data<-lapply(1:length(building.subset),function(x){
    q<-getQuery(building.subset[x],util,var,start,end,interval)
    print(x)
    return(q)})
  building.df<-lapply(which(sapply(building.data,length)>1),function(x)cbind(building.subset[x],building.data[[x]]))
  building.df<-do.call(rbind,building.df)
  return(building.df)
}

## PLOTS
currVar <- getVar("Electricity", "Electricity_EUI","1/10","1/20","1h")
uniqueVar <- unique(currVar[,1])
allVars <- sapply(1:length(uniqueVar), function(y) mean(currVar[currVar[,1]==uniqueVar[y],2]))
plot(allVars, ylim = c(0,240))

total <- merge(currVar, data, by.x = "building.subset[x]", by.y = "Official.Name")
x <- total$Condition
y <- total$values
plot(x,y)

building1 <- total[1:241,]
x <- building1$timestamps
y <- building1$values
plot(x,y, type = 'o', ylim = c(50,60))

## PREDICTIVE MODEL
barplot(total$values)
library(randomForest)


sapply(total, function(x) if(is.na(x)) x = 0)
tot <- na.roughfix(total$Floor.Plans.PDF)
model <- total$values ~tot
plot(model)



output.forest <- randomForest(model, data = total)
predict(model)

x <- total$timestamps
y <- total$values
merge(x,y)
model <- y~x
plot(model)

library(forecast)
forecast()
