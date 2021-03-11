# VGI2Pop
VGI2Pop is one open-sourced and adapted dasymteric mapping method which can downscale the urban population from coarse census tracks or administrative units into neighborhood (street block scale) considering the scale effect. Two popular voluntary geographic information (VGI) data sets are involved. They are open street map (OSM) and twitter data. 

The micro-urban structure features extracted from OSM and user's locations of twitter data can better represent the distribution of urban population. Moreover, we found that scale effect ignored by the conventional dasymetrci mapping methods limits the perdiction accuracy.
We proposed to apply the domain adaptation techniques to mitigate the scale effect and the result shows that our VGI2Pop can outperform than broadly used dasymetric mapping.

## Introduction 
This repository stored the code of VGI2Pop and data of the Greater London Area as example where the offical population data are avilable at two distinct scales namly LOA and MOA. 
Two experiments are recorded. 

### Experiment 1: Scale effect in dasymetric mapping
In this experiment, we compared the performance of machine learning based dasymetric mapping with and without considering scale effect. The result shows that the scale effect affected prediction accuracy and our proposed adaptation can reduce it (17% performance boost in ratio for the deep neural network, 16% for Xgboost, and 5% for Random Forest compared to dasymetric mapping methods ignoring scale effect).

### Experiment 2: Overall performance of VGI2Pop
The performance of two popular dasymetric mapping methods are compared to VGI2Pop. Our proposed VGI2Pop achieved 71.4% higher aggregated accuracy than the conventional multi-class dasymetric mapping method and 48.8% higher than the random forest method based on land use and land cover data.


## Code of VGI2Pop

Show the tree structure and explain which part is for what.

Preprocessing:

This folder contains the preprocessing for cleaning twitter, population data, extracting street blocks (thanks links for sharing this).

Experiment 1:

This folder records how the features extracted from osm and twitter data sets and trained the machine learning based dasymetric mapping models with and without considering scale effect.

Experiment 2: 

This folder contains the implementation of VGI2Pop and two traditional models as comparisons (multi-class dasymetric mapping method and the random forest method based on land use and land cover data). 

## Involved data in case study area (Greater London)
1. population excel download from national statistic office;
2. Shapefile for LSOA and MSOA;
3. OSM data download from OHSOME API;
4. Twitter data download from Twitter API;
5. Urban Atlas.



