library("dplyr")
library("h2o")
library("rsample") 
library("Metrics")
library("densratio")
setwd("/home/z/***********/london/enriched_feature/moa2loa_RF_CV")

moa_data = get(load("/home/z/***********/london/enriched_feature/moa_enriched_covariates.Rdata"))


h2o.no_progress()
h2o.init(max_mem_size = "40g")

moa_data.h2o = as.h2o(moa_data)


loa_data_p= get(load("/home/z/***********/london/enriched_feature/loa_enriched_covariates.Rdata"))
moa_or_data= get(load("/home/z/***********/london/Rspace/pop/raw_pop_mid_london.Rdata"))
loa_or_data= get(load("/home/z/***********/london/Rspace/pop/raw_pop_london_low.Rdata"))


for (i in c(46:50))
{
  split <- h2o.splitFrame(moa_data.h2o,c(0.7))
  train.h2o <- h2o.assign(split[[1]], "train.hex")   
  test.h2o <- h2o.assign(split[[2]], "test.hex")  
  y <- "population"
  x <- setdiff(names(train.h2o), y)
  
  
  h2o.final <- h2o.randomForest(
    x = x,
    y = y,
    nfolds = 5,
    training_frame = train.h2o,
    mtries = -1,
    nbins = 30,
    ntrees = 7000, 
    max_depth = 150,
    sample_rate = 0.8,
    stopping_rounds = 20,
  )
  
  # directly apply on loa
  
  # convert test set to h2o object
  loa_data <- loa_data_p %>% dplyr::select(-population)
  loa_transferred.h2o <- as.h2o(loa_data)
  
  loa_transfer_predict = as.data.frame(h2o.predict(h2o.final, loa_transferred.h2o))
  predict_pop = loa_transfer_predict$predict
  real_pop =  loa_data_p$population
  
  # recorder
  singletime = NULL
  
  # rmse
  s_rmse = rmse(real_pop,predict_pop)
  
  # %rmse
  s_prmse=(rmse(real_pop,predict_pop)*length(real_pop))/sum(real_pop)
  
  #mae
  s_mae = mae(real_pop,predict_pop)
  
  # %mae
  s_pmae = (mae(real_pop,predict_pop) * length(real_pop))/sum(real_pop)
  
  
  # descale 
  
  sum_or_pop = sum(moa_or_data$population)
  
  sum_Scaled_pop = sum(loa_transfer_predict$predict)
  rough_ratio_red = sum_or_pop/sum_Scaled_pop
  descaled_direct_predict_pop = loa_transfer_predict$predict*rough_ratio_red
  # ratio_directly

  # estimate rmse
  d_rmse = rmse(loa_or_data$population,descaled_direct_predict_pop)
  d_prmse = (rmse(loa_or_data$population,descaled_direct_predict_pop)*length(loa_or_data$population))/sum(loa_or_data$population)
  d_mae = mae(loa_or_data$population,descaled_direct_predict_pop)
  d_pmae = (mae(loa_or_data$population,descaled_direct_predict_pop) * length(loa_or_data$population))/sum(loa_or_data$population)
  
  singletime = data.frame(s_rmse=s_rmse,s_prmse= s_prmse,s_mae=s_mae,s_pmae=s_pmae,ratio=rough_ratio_red,d_rmse=d_rmse,d_prmse=d_prmse,d_mae=d_mae,d_pmae=d_pmae)
  save(singletime,file = paste(i,"_moa2loa_RF.Rdata",sep = ""))
}