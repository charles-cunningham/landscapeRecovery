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
# (only schemes that have species in Schedule 2 list)
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
  # Mayflies (BRC data)
  mayflies = list(
    data = "BRC/Ephemeroptera_2018_05_19/Ephemeroptera_Yearly_2018_05_19.csv",
    codes = "BRC/Ephemeroptera_2018_05_19/Ephemeroptera_Concepts_2018_05_19.csv"),
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
    data = "BRC/Vascular_plants_(BSBI)/ccDat_v0.0.Rda",
    codes = NA))

# LOAD DATA ------------------------------------------------------------

# Load schedule 2 species
# N.B. this .csv is made from the names in
# "The Environmental Targets (Biodiversity) (England) Regulations 2023"
# available here: https://www.legislation.gov.uk/uksi/2023/91/schedule/2/made
s2 <-  paste0(dataDir, "Schedule2_species.csv") %>%
  read.csv()

# Find species aggregates
aggSpecies <- grep("spp.|/", s2$Scientific.name, value = TRUE)

### LOOP THROUGH SCHEMES 

for (scheme in names(schemes)) {
scheme = "soldierflies"
  # For  vascular plants...
  if (scheme == "plants") {
    
     # Load in the plants .Rds file and assign to taxaData
    load(paste0(dataDir, schemes[[scheme]]$data)) 
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
    # (remove everything after colon and any " agg")
    taxaData$TAXON <- sub(":.*", "", taxaData$NAME) %>%
      sub(" agg", "", .) 
    
    # For plants
  } else if (scheme == "plants") {
    
    # Rename columns accordingly to standardise
    taxaData <- rename(taxaData, 
                       TAXON = taxon,
                       GRID = hectad )
    
    # Convert to long format
    taxaData <- taxaData %>%
      # Pivot from 'wide' to 'long' format
      # with PERIOD from period columns and COUNT from rows
      pivot_longer(cols = !c(TAXON , qualifier, GRID, freq),
                   names_to = "PERIOD", 
                   values_to = "COUNT") %>%
      # Drop redundant 'freq' and 'qualifier' columns
      select(-c(freq, qualifier))
    
    # For all other schemes...
  } else {
    
    # Read in species names and concept codes 
    codeData <- paste0(dataDir, schemes[[scheme]]$codes) %>%
      read.csv(.)
    
    # Add in scientific name
    taxaData <- merge(codeData, 
                   taxaData, by = "CONCEPT")
    
    # Rename columns accordingly to standardise
    taxaData <- rename(taxaData, 
                       TAXON = NAME,
                       GRID = SQ_10 )
  }

# AGGREGATE SPECIES ----------------------------------------------------------
  # N.B. Species aggregates on the Schedule 2 list are either entire genus aggregates
  # (e.g. "Aeshna spp.") or specific species complexes (e.g. Bombus lucorum / terrestris)
  
  # For each unique taxon name
  for (i in unique(taxaData$TAXON)) {

    # Extract genus and species components, add new character to start and end to
    # ensure full name defined and stop partial matches
    iGeneric <- sub(" .*", "", i) %>% paste0(">", ., "<")
    iSpecific <- sub(".*? ", "", i) %>% paste0(">", ., "<")
    
    # Find which (if any) species aggregate genus names match iGeneric,
    # assign match to aggSpecies_i 
    aggSpecies_i <- grep(iGeneric, 
                         paste0(">", sub(" .*", "", aggSpecies), "<") , 
                         ignore.case = TRUE) %>%
      aggSpecies[.]
    
    # If one matches...
    if(length(aggSpecies_i) > 0) {

      # Find the specific names of aggSpecies_i
      aggSpeciesSpecific <- sub(".*? ", "", aggSpecies_i) %>%
        strsplit(., "/") %>%
        .[[1]] %>%
        sub(" ", "", .) %>%
        paste0(">", ., "<")

      # If aggSpeciesSpecific contains "spp." OR
      if(any(grepl(">spp.<", aggSpeciesSpecific) ) | 
         # if the specific name of i is one of the specific name of 
         # species aggregate, e.g. "Bombus lucorum / terrestris"
         any(grepl(iSpecific, aggSpeciesSpecific, ignore.case = TRUE) ) ) {   
           
           # Assign i TAXON to the aggregate name
           taxaData [which(taxaData$TAXON == i), 
                     "TAXON"] <- 
             aggSpecies_i   
         }
    # If more than one matches print an error
    } else if (length(aggSpecies_i) > 1) {
      
      print("ERROR: More than one species match in list of aggregated species")
    }
  }

  ### EXCEPTIONS

  # Moth genus with only two species. In S2 list as a species complex, and
  # sometime recorded in records only by genus name. There are only 2 species of
  # this genus in UK that can only be separated by genetalia.
  if (scheme == "moths") {
  taxaData [which(taxaData$TAXON == "Mesapamea"), "TAXON"] <-
    "Mesapamea secalis / didyma"
  }

# FILTER DATA ----------------------------------------------------------
  
  # FILTER TAXA
  
  # Filter to Schedule 2 species (and species aggregates)
  taxaData <- taxaData %>%
    filter(  tolower(taxaData$TAXON) %in% tolower(s2$Scientific.name))
  
  # FILTER LOCATION
  
  # Filter by location, resolution and record status
  taxaData <- taxaData %>%
    # Filter out channel island records
    filter(!grepl("WA|WV", GRID)) %>%
    # Filter out blanks
    filter(GRID != "")
  
  # FILTER TIME
  
  # Exclude plants...
  if (scheme != "plants") {
    
    # Filter to years after 1991 (soldierflies only go back to 1990)
    taxaData <- filter(taxaData, YEAR>1990)
    
    # Then for plants...
  } else {
    
    # Filter to years after 1990
    taxaData <- filter(taxaData, PERIOD %in% 
                         c("X1987.1999", "X2000.2009", "X2010.") )
  }
  
# ADD IN COORDINATES ---------------------------------------------------
  
  # Extract easting and northing from OS grid using BRCmap package
  XY <- OSgrid2GB_EN(taxaData$GRID,
                     centre = TRUE,
                     gr_prec = 10000)
  
  # Join easting/northing with scheme data
  taxaData <- bind_cols(taxaData, XY)
  
  # Drop all columns apart from TAXON, GRID, YEAR/PERIOD, EASTING, NORTHING
  taxaData <- taxaData %>%
    select(names(taxaData)[names(taxaData) %in% 
                              c("TAXON", "GRID", "YEAR", "PERIOD", "EASTING", "NORTHING")])
  
# DATA FOR MODELLING ---------------------------------------------------
  
  # Subset to after year 2000 for 'recent' records
  
  # Exclude plants...
  if (scheme != "plants") {
    
    # Filter to years after 2000
    taxaModelData <- filter(taxaData, YEAR > 2000)
    
    # Then for plants...
  } else {
    
    # Filter to years after 1990
    taxaModelData <- filter(taxaData, PERIOD %in% 
                         c("X2000.2009", "X2010.") )
  }
  
# SAVE -------------------------------------------------------------------
  
  # Create directory
  dir.create(paste0(dataDir, "../Processed/", scheme), 
             recursive = TRUE, showWarnings = FALSE)
  # Save
  save(taxaData,
       file = paste0(dataDir, "../Processed/", scheme, "/taxaData.RData"))
  save(taxaModelData,
       file = paste0(dataDir, "../Processed/", scheme, "/taxaModelData.RData"))

}
