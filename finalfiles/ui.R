#Shiny UI

library(shiny)
library(RCurl)

elec<-read.csv("https://raw.githubusercontent.com/ThisIsJeron/CEEDR/master/finalfiles/electricity.csv")
timestamp<-unique(elec[,3])

shinyUI(fluidPage(titlePanel("CEEDR Data Analysis"),
  sidebarPanel(sliderInput("slide",label="Choose timestamp",min=1,max=73,value=1)),
  mainPanel(plotOutput("plot"))
))