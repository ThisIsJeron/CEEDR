#OSI API Take 2

cefs<-content(getAPIlink("https://bldg-pi-api.ou.ad3.ucdavis.edu/piwebapi/elements/E0bgZy4oKQ9kiBiZJTW7eugwvgV_Y00J5BGt6DwVwsURwwVVRJTC1BRlxDRUZTXFVDREFWSVNcQlVJTERJTkdT/elements"))

meta2<-content(getAPIlink("https://bldg-pi-api.ou.ad3.ucdavis.edu/piwebapi/tables/B0bgZy4oKQ9kiBiZJTW7eugwJhSOEaMUUUyOuVv2CDalxgVVRJTC1BRlxBQ0VcVEFCTEVTW0JVSUxESU5HX0RBVEFd/data"))

getRow<-function(x){
  get.nulls<-which(sapply(1:length(meta2[[2]][[x]]),function(i)is.null(meta2[[2]][[x]][[i]]))==TRUE)
  new.data<-lapply(1:length(meta2[[2]][[x]]),function(j){
    if(j %in% get.nulls == TRUE)
      return(NA)
    else
      return(meta2[[2]][[x]][[j]])
  })
  names(new.data)<-names(meta2[[2]][[1]])
  return(data.frame(new.data))
}

meta2l<-lapply(1:length(meta2[[2]]),function(x)getRow(x))
metadf2<-rbind.fill(meta2l)
metadf2<-write.csv(metadf2,file="metadf2.csv",row.names=FALSE)

#For each building, scrape values first

getValues<-function(x){
  valuelink<-content(getAPIlink(cefs[[2]][[x]]$Links$Value))$Items
  if(length(valuelink)<21){
    valuedf<-data.frame(rbind(rep(NA,21)))
    names(valuedf)<-paste0("X",seq(1,21))
    return(valuedf)}
  values<-lapply(1:21,function(x)valuelink[[x]]$Value$Value)
  webids<-sapply(1:21,function(x)as.character(valuelink[[x]]$WebID))
  names<-sapply(1:21,function(x)valuelink[[x]]$Name)
  valuedf<-data.frame(values)[,1:21]
  names(valuedf)<-names
  #webids<-data.frame(webids)
  #names(webids)<-names
  print(x)
  print(ncol(valuedf))
  return(valuedf)
}

build.values<-lapply(1:133,function(x)getValues(x))

builddf<-rbind.fill(build.values)

name1<-content(getAPIlink(cefs[[2]][[1]]$Links$Value))$Items

names(builddf)<-sapply(1:21,function(i)name1[[i]]$Name)

buildjson<-toJSON(build.values)

#GO ONE LEVEL DEEPER

elelvl2<-lapply(1:133,function(x)content(getAPIlink(cefs[[2]][[x]]$Links$Elements)))

getUtilities<-function(x){
  numUtils<-length(elelvl2[[x]]$Items)
  utilNames<-sapply(1:numUtils,function(y)elelvl2[[x]]$Items[[y]]$Name)
  util.indicators<-as.numeric(key.utils %in% utilNames)
  return(util.indicators)
}

getUtilData<-function(x,utility){
  numUtils<-length(elelvl2[[x]]$Items)
  utilNames<-sapply(1:numUtils,function(y)elelvl2[[x]]$Items[[y]]$Name)
  choose.util<-which(utility %in% utilNames==TRUE)
  util.data<-content(getAPIlink(elelvl2[[x]]$Items[[choose.util]]$Links$InterpolatedData))
  data.names<-sapply(1:length(util.data$Items),function(x)util.data$Items[[x]]$Name)
  if("Electricity_EUI" %in% data.names == FALSE)
    return(NA)
  eui.number<-which("Electricity_EUI" %in% data.names)
  EUI<-sapply(1:length(util.data$Items[[eui.number]]),function(x)util.data$Items[[eui.number]]$Items[[x]]$Value)
  return(EUI)
}
#See the common utilities

table(unlist(lapply(1:133,function(x)getUtilities(x))))

#Based on these utilities, we'll use ChilledWater, Steam and Electricty

key.utils<-c("ChilledWater","Electricity","Steam")

utils<-t(sapply(1:133,function(x)getUtilities(x)))

utilsdf<-data.frame(builddf$CAAN,builddf$BuildingName,utils)
names(utilsdf)<-c("CAAN","name",key.utils)
utilsjson<-toJSON(as.list(utilsdf))
write_lines(utilsjson,path="./utils.JSON")

#Get EUIs

EUI.data<-sapply(which(utilsdf[,4]==1),function(x)getUtilData(x,"Electricity"))

#Create some functions that extract data from a variable

getName<-function(n,k){
  return(elec.pages[[n]]$Items[[k]]$Name)
}

getNames<-function(n){
  names<-sapply(1:length(elec.pages[[n]]$Items),function(x)getName(n,x))
  return(names)
}

getKeyInfo<-function(n,k,r){
  value<-elec.pages[[n]]$Items[[k]]$Items[[r]]$Value
  timestamp<-elec.pages[[n]]$Items[[k]]$Items[[r]]$Timestamp
  return(c(value,timestamp))
}

getData<-function(n,k){
  values<-data.frame(t(sapply(1:length(elec.pages[[n]]$Items[[k]]$Items),function(x)getKeyInfo(n,k,x))))
  values[,1]<-as.numeric(as.character(values[,1]))
  values[,2]<-ymd_hms(as.character(values[,2]))
  values[,2]<-with_tz(values[,2],"US/Pacific")
  names(values)<-c(getName(n,k),"timezone")
  return(values)
}

getAllVars<-function(n){
  numVars<-length(elec.pages[[n]]$Items)
  var.list<-lapply(1:numVars,function(x)getData(n,x))
  names(var.list)<-getNames(n)
  print(n)
  return(var.list)
}

electricity<-lapply(1:131,function(x)getAllVars(x))
names(electricity)<-builddf$BuildingName[which(utilsdf[,4]==1)]

elec.json<-toJSON(electricity)

elec.var.names<-unique(unlist(sapply(1:131,function(x)names(electricity[[x]]))))

#BIG GOAL: Get WebID's for all possible queries.

getWebID<-function(n,k){
  return(elec.pages[[n]]$Items[[k]][[1]])
}

#For the nth building's kth variable in electricity, we can get the webURL

#Create a generalized utility function

key.utils<-c("ChilledWater","Electricity","Steam")

getWebID<-function(u,n,k){
  return(u[[n]]$Items[[k]][[1]])
}

getName<-function(u,n,k){
  return(u$Items[[n]]$Items[[k]]$Name)
}

getNames<-function(u,n){
  names<-sapply(1:length(u[[n]]$Items),function(x)getName(n,x))
  return(names)
}

getUtilData<-function(x,utility){
  numUtils<-length(elelvl2[[x]]$Items)
  utilNames<-sapply(1:numUtils,function(y)elelvl2[[x]]$Items[[y]]$Name)
  choose.util<-which(utilNames %in% utility)
  util.data<-content(getAPIlink(elelvl2[[x]]$Items[[choose.util]]$Links$InterpolatedData))
  num.var<-length(util.data$Items)
  var.names<-sapply(1:num.var,function(i)util.data$Items[[i]]$Name)
  web.id<-sapply(1:num.var,function(i)util.data$Items[[i]]$WebId)
  bu.df<-data.frame(rep(builddf$BuildingName[x],num.var),rep(builddf$CAAN[x],num.var),rep(utility,num.var),var.names,web.id)
  names(bu.df)<-c("BuildingName","CAAN","Utility","Var","WebUrl")
  return(bu.df)
}

getMainUtils<-function(x){
  util.list<-lapply(1:3,function(i){
    if(utilsdf[x,2+i]==1){
      udf<-getUtilData(x,key.utils[i])
      return(udf)
    }
  })
  util.df<-do.call(rbind,util.list)
  print(x)
  return(util.df)
}

ucd.utilities<-lapply(1:133,function(x)getMainUtils(x))

ucd.util.df<-rbind.fill(ucd.utilities)

cefs.names<-sapply(1:133,function(x)cefs[[2]][[x]]$Name)

getData<-function(building,utility,var,interval){
  
}
