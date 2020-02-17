Varplot<-function(feature,Importance, colours = NA,no_features=15){
  
  library("tidyverse")
  options(warn=-1)
  
  if (length(feature) != length(Importance)) {
    message("The variables and importance values vectors do not have the same length.")
    stop(message(paste("There are",length(feature),"variables and",length(Importance),"Importance values!")))
  }
  if (is.na(colours)) {
    
    colours <- "#35B779FF"
  } 
  
  
  if (length(feature) < no_features) {
    no_features <- length(feature)
  } 
  
  
  data<-data.frame( feature,Importance)
  
  #output <- out[1: no_features,] 
  
  data<-data[1: no_features,]
  
  p=data%>%ggplot(aes(x=reorder(feature,Importance)
                      ,y=Importance))+
    
    geom_col(fill=colours,width = 0.2)+                             
    
    #geom_segment(aes(xend=feature,yend=0))+
    #geom_point()
    
    coord_flip()+
    #viridis_pal(option = "D")(10)
    
    labs(x="Feature",y="Importance")+
    
    labs(title = paste0("Variables Importance. (", no_features, " / ", length(feature), " plotted)"))+
    
    
    geom_label(aes(label=round(Importance,2),vjust=0.5))+
    
    #geom_label_repel(aes(label=round(Importance,0),vjust=-0.2,size=4))+
    
    scale_x_discrete(expand = c(0, 0))+
    theme(
      legend.position="none",
      legend.direction="horizontal",
      #legend.title = element_text("Above or below IQR"), # remove element_blank() x axis ticks and labels
      legend.title = element_blank(),
      text=element_text(size=12,  family="Times"),
      #axis.ticks.x = element_blank(),
      #axis.text.x = element_blank(), #remove x-qxis text
      #axis.title.x = element_blank(),
      legend.text = element_text(size = 7),# legend title size
      #legend.text = element_blank(),# remove legend text
      plot.title = element_text(hjust = 0.5), #position legend in the middle
      plot.subtitle = element_text(hjust = 0.5,colour = "red"),
      axis.text.x = element_text(angle = 30, hjust = 1)
    )
  
  return(p)  
}