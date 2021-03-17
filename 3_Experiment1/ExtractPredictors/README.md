## Extract predictors

This folder contains the code of extracting feature space.

folder extract_lsoa_features contains the code of extracting road and areal unit features at lsoa scale.
folder extract_msoa_features contains the code of extracting road and areal unit features at msoa scale.

building_orentation.sql records the sql comand for extract building orentation related featrues at multi-scales.
distinct_user.sql records how to extract features such as the number of distinct users and distinct tweets for each areal unit at multi-scales.
extract_roads_features extracted features realted to road at multi-scales.

File 1_enriched_scale_population_merge.Rmd merged all the features extracted from streets, buildings and areal units as well as response - population count. 

The finnal covariates are outputed in the output folder which will be input to involved machine learning models.
