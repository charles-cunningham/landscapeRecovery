# HEADER ---------------------------------------------------------------
#
# Author: Charles Cunningham
# Email: charles.cunningham@york.ac.uk
# 
# Script name: Read data from Biological Records Centre (BRC), Butterfly
# Conservation (BC), and BSBI. 
# Permission must be obtained before using these datasets.
#
# Script Description:

# INSTALL PACKAGES & LOAD LIBRARIES ------------------------------------

#devtools::install_github("colinharrower/BRCmap")

library(tidyverse)
library(BRCmap)

# SET DIRECTORIES ------------------------------------------------------

# Set data directory
dataDir <- "../Data/Species/Raw/"

# List the different recording schemes and their associated 
# distribution and species code datasets
# N.B. These must be requested from either BRC or BC as stated
schemes <- list(
  # Butterflies (BC data)
  butterflies = list(
    data = "Butterfly_Conservation/Butterflies/GB_BNM_Butterflies_10km_1950-2014.csv",
    codes = NA),
  # Moths (BC data)
  moths = list(
    data = "Butterfly_Conservation/Moths/GB_NMRS_Macro-moths_10km_1950-2014.csv",
    codes = NA),
  # Spiders (BRC data)
  arachnids = list(
    data = "BRC/Arachnids_2018_07_30/Arachnids_yearly_2018_07_30.csv",
    codes = "BRC/Arachnids_2018_07_30/Arachnids_Concepts_2018_07_30.csv"),
  # Bryophytes (BRC data)
  bryophytes = list(
    data = "BRC/Bryophytes_2018_05_21/Bryophytes_Yearly_2018_05_21.csv",
    codes = "BRC/Bryophytes_2018_05_21/Bryophytes_Concepts_2018_05_21.csv"),
  # Carabids (BRC data)
  carabids = list(
    data = "BRC/Carabidae_2018_05_19/Carabidae_Yearly_2018_05_19.csv",
    codes = "BRC/Carabidae_2018_05_19/Carabidae_Concepts_2018_05_19.csv"),
  # Ladybirds (BRC data)
  ladybirds = list(
    data = "BRC/Coccinellidae_2018_05_19/Coccinellidae_Yearly_2018_05_19.csv",
    codes = "BRC/Coccinellidae_2018_05_19/Coccinellidae_concepts_2018_05_19.csv"),
  # Mayflies (BRC data)
  mayflies = list(
    data = "BRC/Ephemeroptera_2018_05_19/Ephemeroptera_Yearly_2018_05_19.csv",
    codes = "BRC/Ephemeroptera_2018_05_19/Ephemeroptera_Concepts_2018_05_19.csv"),
  # Hoverflies (BRC data)
  hoverflies = list(
    data = "BRC/Hoverflies_2018_05_22_(HRS)/sp_hectad_year.csv",
    codes = NA),
  # Hymenoptera (BRC data)
  hymenoptera = list(
    data = "BRC/Hymenoptera_2018_05_24_(BWARS)/Bwars_exportable_post_1959.csv",
    codes = NA),
  # Odonata (BRC data)
  odonata = list(
    data = "BRC/Odonata_2018_05_15/Odonata_Yearly_2018_05_15.csv",
    codes = "BRC/Odonata_2018_05_15/Odonata_Concepts.csv"),
  # Soldierflies (BRC data)
  soldierflies = list(
    data = "BRC/Soldierflies_2018_07_30/Soliderflies_yearly_2018_07_30.csv",
    codes = "BRC/Soldierflies_2018_07_30/Soliderflies_concepts_2018_07_30.csv"),
  # Plants (BSBI data)
  plants = list(
    data = "BRC/Vascular_plants_(BSBI)/ccDat_v0.0.Rds",
    codes = NA))

# LOAD DATA ------------------------------------------------------------

# Load schedule 2 species
# N.B. this .csv is made from the names in
# "The Environmental Targets (Biodiversity) (England) Regulations 2023"
# available here: https://www.legislation.gov.uk/uksi/2023/91/schedule/2/made
s2 <-  paste0(dataDir, "Schedule2_species.csv") %>%
  read.csv()

# LOOP THROUGH SCHEMES -------------------------------------------------

for (scheme in names(schemes)) {
  scheme <- names(schemes)[12]

  # For  vascular plants...
  if (scheme == "plants") {
    
     # Load in the plants .Rds file and assign to taxaData
    paste0(dataDir, schemes[[scheme]]$data) %>%
      readRDS(.)
    taxaData <- dat
    rm(dat)
    
  # For hymenoptera... 
  } else if (scheme == "hymenoptera") {
  
    # Read in .csv file (no header)
    taxaData <- paste0(dataDir, schemes[[scheme]]$data) %>%
      read.csv(., header = FALSE)

    # For all schemes other than vascular plants and hymenoptera...
  } else {
    
    # Read in .csv file
    taxaData <- paste0(dataDir, schemes[[scheme]]$data) %>%
      read.csv()
  }

# JOIN SPECIES NAMES AND STANDARDISE -----------------------------------
  
  # For butterflies or moths (i.e. BC)...
  if (scheme %in% c("butterflies", "moths")) {
    
    # Rename columns accordingly to standardise
    taxaData <- rename(taxaData, 
                       TAXON = Taxon,
                       YEAR = Year,
                       GRID = Grid.Reference)

    # For hoverflies...
  } else if (scheme == "hoverflies") {
    
    # Rename columns accordingly to standardise
    taxaData <- rename(taxaData, 
                       TAXON = species,
                       YEAR = year,
                       GRID = hectad )
    
    # For hymenoptera
  } else if (scheme == "hymenoptera") {
    
    # Rename columns accordingly to standardise
    # (headers missing from dataset)
    names(taxaData) <- c("KEY", "NAME", "LOCATION",
                         "GRID", "YEAR_UPPER", "YEAR_LOWER")
    
    # Standardise years
    taxaData$YEAR <- substr(taxaData$YEAR_UPPER, 1,4) %>%
      as.numeric()
    
    # Standardise taxon
    taxaData$TAXON <- sub(":.*", "", taxaData$NAME)
    
    # For plants
  } else if (scheme == "plants") {
    
    # Rename columns accordingly to standardise
    taxaData <- rename(taxaData, 
                       TAXON = taxon,
                       GRID = hectad )
    
    # Convert to long format
    pivot_longer()
    
    
    
    # For all other schemes...
  } else {
    
    
    
  }
  

  
   
# FILTER DATA ----------------------------------------------------------
  
  
  
# ADD IN COORDINATES ---------------------------------------------------
  
  

# DATA FOR MODELLING ---------------------------------------------------
  
  
  
# SAVE -------------------------------------------------------------------
  
  
  
  
  
  
 
  
}





