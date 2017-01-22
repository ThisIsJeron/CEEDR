#Server
library(shiny)
library(dplyr)
library(rdrop2)
testvector<-read.csv("testvector.csv")
load("token.rda")

options(shiny.maxRequestSize = 10*1024^2)
fit.rate<-reactiveValues(fit=0)

shinyServer(function(input, output) {
  output$text1<-renderText({
    inFile <- input$file1
    if(is.null(inFile))
      return(NULL)
    return("Accuracy Rate:")
  })
  output$text2<-renderText({
    inFile <- input$file1
    if(is.null(inFile))
      return(NULL)
    return("Confusion Matrix:")
  })
  output$text3<-renderText({
    inFile <- input$file1
    if(is.null(inFile))
      return(NULL)
    return("The rows contain the actual values, the columns contain your predicted values.")
  })
  output$fit <- renderText({
    inFile <- input$file1
    if(is.null(inFile))
      return(NULL)
    predict<-read.csv(inFile$datapath, header = input$header,
                      sep = input$sep, quote = input$quote)
    if(identical(dim(testvector),dim(predict))==FALSE)
      return("The dimensions of your file do not match the number of votes.")
    fit<-sum(testvector==predict)/nrow(testvector)
    fit.rate$fit<-100*round(fit,4)
    return(paste0("Your model's accuracy rate is ",100*round(fit,4),"%."))
  })
  output$matrix <- renderTable({
    inFile <- input$file1
    if (is.null(inFile))
      return(NULL)
    predict<-read.csv(inFile$datapath, header = input$header,
             sep = input$sep, quote = input$quote)
    if(identical(dim(testvector),dim(predict))==FALSE)
      return(NULL)
    compare<-cbind(testvector,predict)
    table(compare[,1],compare[,2])
  })
  observeEvent(input$send,{
    result<-data.frame(Sys.time(),input$select,isolate(fit.rate$fit),input$file1$name)
    names(result)<-c("Timestamp","Team","Accuracy","Filename")
    file.name<-paste0(gsub(" ","",tolower(input$select)),as.integer(Sys.time()),".csv")
    write.csv(result,row.names=FALSE,file=file.name)
    drop_upload(file.name,dest="results",dtoken=token)
  })
  output$leaderboard <- renderTable({
    csv.paths<-drop_search('csv',path="/results",dtoken=token)$path
    if(length(csv.paths)==0)
      return(NULL)
    csv.list<-lapply(csv.paths,drop_read_csv)
    leaderboard<-do.call(rbind,csv.list)
    leaderboard<-leaderboard %>% group_by(Team) %>% slice(which.max(Accuracy))
    leaderboard<-leaderboard[order(leaderboard$Accuracy,decreasing=TRUE),]
    rownames(leaderboard)<-NULL
    leaderboard
  })
})