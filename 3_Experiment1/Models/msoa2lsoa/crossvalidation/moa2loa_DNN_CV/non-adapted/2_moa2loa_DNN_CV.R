library(keras)
library("Metrics")
library("dplyr")
library("BBmisc")
#2_moa2loa_DNN_CVd
setwd("D:/londonPop/enriched_feature/crossValidation")
moa_data = get(load("D:/londonPop/enriched_feature/moa_enriched_covariates.Rdata"))
loa_data = get(load("D:/londonPop/enriched_feature/loa_enriched_covariates.Rdata"))
target_x <- loa_data %>% dplyr::select(-population) %>% as.matrix()
target_y <- loa_data$population

moa_or_data= get(load("D:/londonPop/enriched_feature/raw_pop_mid_london.Rdata"))
loa_or_data= get(load("D:/londonPop/enriched_feature/raw_pop_london_low.Rdata"))
sum_or_pop = sum(moa_or_data$population)

for (i in c(1:50))
{
  split <- rsample::initial_split(moa_data, prop = .8, strata = "population")
  train <- rsample::training(split)
  test  <- rsample::testing(split)
  
  # Create & standardize feature sets
  # training features
  train_x <- train %>% dplyr::select(-population)
  train_x = as.matrix(train_x)
  
  # testing features
  test_x <- test %>% dplyr::select(-population)
  test_x = as.matrix(test_x)
  # Create & transform response sets
  train_y <- train$population
  test_y  <- test$population
  
  model <- keras_model_sequential() %>%
    # network architecture
    layer_dense(units = 10, activation = "relu", input_shape = ncol(train_x)) %>%
    #layer_batch_normalization() %>%
    
    layer_dense(units = 5, activation = "relu") %>%
    #layer_batch_normalization() %>%
    layer_dense(units = 3, activation = "relu") %>%
    layer_dense(units = 1) %>%
    
    
    # backpropagation
    compile(
      optimizer = "RMSprop",
      loss = "MSE",
      metrics = c("mae")
    )
  
  
  # train our model
  learn <- model %>% fit(
    x = train_x,
    y = train_y,
    epochs = 60,
    batch_size = 32,
    validation_split = .2,
    verbose = FALSE,
    callbacks = list(
      callback_early_stopping(patience = 10),
      callback_reduce_lr_on_plateau()
    )
  )
  
  predict_pop = predict(model,target_x)
  predict_pop[predict_pop<0]=0
  real_pop =  target_y
  
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
  
  # descaled
  sum_loa_transferred_predict = sum(predict_pop)
  rough_ratio_red = sum_or_pop/sum_loa_transferred_predict
  descaled_loa_transferred_predict = predict_pop*rough_ratio_red
  # ratio transferred
  ratio = rough_ratio_red
  # estimate rmse
  d_rmse = rmse(loa_or_data$population,descaled_loa_transferred_predict)
  d_prmse = (rmse(loa_or_data$population,descaled_loa_transferred_predict)*length(loa_or_data$population))/sum(loa_or_data$population)
  d_mae = mae(loa_or_data$population,descaled_loa_transferred_predict)
  d_pmae = (mae(loa_or_data$population,descaled_loa_transferred_predict) * length(loa_or_data$population))/sum(loa_or_data$population)
  singletime = data.frame(s_rmse=s_rmse,s_prmse= s_prmse,s_mae=s_mae,s_pmae=s_pmae,ratio=ratio,d_rmse=d_rmse,d_prmse=d_prmse,d_mae=d_mae,d_pmae=d_pmae)
  save(singletime,file = paste(i,"_moa2loa_DNN.Rdata",sep = ""))
}