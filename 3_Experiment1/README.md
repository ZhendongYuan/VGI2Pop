## Experiment 1 Scale effect in dasymetric mapping

In this experiment, we compared the performance of machine learning based dasymetric mapping with and without considering scale effect. 
The result shows that the scale effect affected prediction accuracy and our proposed adaptation can reduce it 
(17% performance boost in ratio for the deep neural network, 16% for Xgboost, and 5% for Random Forest compared to dasymetric mapping methods ignoring scale effect).


Folder ExtractPredictors:
This folder contains the R and sql files of extracting features space for multi-scales mainly from the morphological aspect of areal units, buildings and roads.

Folder Models:
This folder contains the code of designed experiments which downscaled the census population from msoa scale to lsoa.
