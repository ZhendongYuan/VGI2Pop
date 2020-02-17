library("mongolite")
library("rgdal")
library("sp")
library("rpostgis")

insertpostgis = function (point)
{

  conn <- dbConnect(drv = "PostgreSQL", host = "localhost",port = "5432", dbname = "london", user = "zhendong", password = "y1995z828d")
  
  pgInsert(conn, "englandtweets1415", point, new.id = "gid")
  dbDisconnect(conn)
}

convert2pointdf = function (mx)
{

  mx$GeoCoordinates = NULL
  temp = do.call(cbind.data.frame, mx)
  temp$`_id` = as.character(temp$`_id`)
  temp$Text = as.character(temp$Text)
  
  
  
  return(temp)
}

starttime = Sys.time()
count = 1
tweets_collection = mongo(collection = "LondonTweets1415midyearnight", db = "Tweetsdb")
it =tweets_collection$aggregate('{}',iterate = TRUE)
try(
  while(!is.null(tx <- it$batch(10000))){
    group_df = lapply(tx,function(x) convert2pointdf(x))
    group_df_df = do.call(rbind.data.frame, group_df)
    coordinates(group_df_df) <- ~Longitude + Latitude
    proj4string(group_df_df) <- "+init=epsg:4326"
    print(paste("finished: ",count))
    count = count+1
    print(paste("how many time? *10000 batch size:",count))
    insertpostgis(group_df_df)
    
  }
)
print("funished batch")
print("end at: ")
print(Sys.time())
print("sart at:")
print(starttime)




