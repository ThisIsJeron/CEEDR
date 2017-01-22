#Shiny server

library(shiny)
library(ggplot2)
library(RCurl)

elec<-read.csv("https://raw.githubusercontent.com/ThisIsJeron/CEEDR/master/finalfiles/electricity.csv")
timestamp<-unique(elec[,3])

shinyServer(function(input,output){
    output$plot<-renderPlot({
      dataInput<-reactive({
        data<-elec[elec[,3]==timestamp[input$slide],]
        return(data)})
      data<-dataInput()
      qplot(x=data[,5],y=data[,4],col=data[,7],main=paste0("Hourly Electricity Usage at ",as.character(timestamp[input$slide])),xlab="Longitude",
      ylab="Latitude")
    })
  })
