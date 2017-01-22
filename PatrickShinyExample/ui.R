#UI
library(shiny)
team.names<-c("EightThirtyFive","S.H.Y.","I Saw the Sin","Xiaofeifei",
              "KSMP","Data Rocker","Mad Scientist","StartR Pack",
              "The Reckless Challenge","Data Science @ Sac State","Alice Q",
              "Coloni","Mank Demes","Data Ninjas","X^n","data ninjas2")
shinyUI(fluidPage(
  titlePanel("iidata PMC Model Fit Test"),
  sidebarLayout(
    sidebarPanel(
      fileInput('file1', 'Choose file to upload',
                accept = c(
                  'text/csv',
                  'text/comma-separated-values',
                  'text/tab-separated-values',
                  'text/plain',
                  '.csv',
                  '.tsv'
                )
      ),
      selectInput("select",label="Which team are you submitting for?",choices=team.names,selected=team.names[1]),
      actionButton("send","Send Results"),
      p("Once you submit your model, refresh the application to see the updated leaderboard."),
      tags$hr(),
      checkboxInput('header', 'Header', TRUE),
      radioButtons('sep', 'Separator',
                   c(Comma=',',
                     Semicolon=';',
                     Tab='\t'),
                   ','),
      radioButtons('quote', 'Quote',
                   c(None='',
                     'Double Quote'='"',
                     'Single Quote'="'"),
                   '"'),
      tags$hr()
    ),
    mainPanel(
      h1(textOutput('text1')),
      p(textOutput('fit')),
      h1(textOutput('text2')),
      tableOutput('matrix'),
      p(textOutput('text3')),
      h1("Leaderboard:"),
      tableOutput('leaderboard')
    )
  )
))