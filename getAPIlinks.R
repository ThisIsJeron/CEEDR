#Access any link from the OSI API:

require(hittr)

user<-"ou\\pi-api-public"
password<-"M53$dx7,d3fP8"

getAPIlink<-function(link){
  api.link<-GET(link,authenticate(user,password))
  return(api.link)
}

#Example: Get the content from dataservers:

your.query<-getAPIlink("https://bldg-pi-api.ou.ad3.ucdavis.edu/piwebapi/dataservers/s09KoOKByvc0-uxyvoTV1UfQVVRJTC1QSS1Q/points")

#What list elements exist in your query?

str(your.query)

#Access the contents of the query

content(your.query)
