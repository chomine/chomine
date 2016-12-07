# Pipeline to install CHOmine 

This repository contains all scripts to build current CHOmine 
([https://chomine.boku.ac.at](https://chomine.boku.ac.at))

## Manual work before running the script

1. change values of config file
  * copy config.example to config
  * set correct paths for input and output files
  * set path to intermine or leave empty if it should be cloned from github
  * set git-tag that should be checked out for building the mine
  * set theme_hue between 10 and 200
3. adapt sources/chomine/webapp/resources/webapp/dataCategories.jsp
  * set correct release versions for data
2. create databases in postgresql for
  * chomine
  * items-chomine
  * userprofile-chomine
3. change *sources/chomine.properties* if necessary
  * database settings
  * webapp settings
  * email settings
4. run pipeline.sh to build ChoMine
5. copy result to productive server and follow intermine documentation to build
   webapp by
   * cd chomine/webapp
   * ant build-db-userprofile
   * ant default remove-webapp release-webapp

