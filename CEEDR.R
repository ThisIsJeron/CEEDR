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







  
