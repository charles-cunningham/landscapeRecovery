# HEADER ---------------------------------------------------------------
#
# Author: Charles Cunningham
# Email: charles.cunningham@york.ac.uk
# 
# Script name: Read BTO data
#
# Script Description:

# INSTALL PACKAGES & LOAD LIBRARIES ------------------------------------

#devtools::install_github("colinharrower/BRCmap")

library(tidyverse)
library(BRCmap)

# SET DIRECTORIES ------------------------------------------------------

# Set data directory
dataDir <- "../Data/Species/Raw/BTO/"

# Create data directory
dir.create(dataDir, recursive = TRUE, showWarnings = FALSE)

# DOWNLOAD DATA --------------------------------------------------------

# Download publicly available and accessible data from this paper:

# Licence: Creative Commons, with Attribution, Non-commercial v4.0 (CC-BY-NC). 
# See here for full details of what is permitted: https://creativecommons.org/licenses/by-nc/4.0/

# Citation: Gillings, S., Balmer, D.E., Caffrey, B.J., Downie, I.S., Gibbons, D.W., Lack, P.C., 
# Reid, J.B., Sharrock, J.T.R., Swann, R.L. & Fuller, R.J. (in press) Breeding and wintering bird 
# distributions in Britain and Ireland from citizen science bird atlases. Global Ecology and Biogeography.
# https://doi.org/10.1111/geb.12906

# BTO 
# 02 February 2019

# Information on linked dataset here
# https://zenodo.org/records/10599935

# Specify download url
url <- "https://zenodo.org/api/records/10599935/files-archive"
 
# Download
download.file(url = url,
              destfile = paste0(dataDir, "Bird_data.zip"),
              mode = "wb")

# Unzip downloaded folder
unzip(paste0(dataDir, "Bird_data.zip"),
      exdir = dataDir,
      overwrite = TRUE)

# Unzip specific data folder
unzip(paste0(dataDir, "atlas_open_data_files.zip"),
      exdir = dataDir,
      overwrite = TRUE)

# Delete .zip fils as no longer needed
unlink(paste0(dataDir, "Bird_data.zip"), recursive = TRUE)
unlink(paste0(dataDir, "atlas_open_data_files.zip"), recursive = TRUE)

# LOAD DATA -------------------------------------------------------------

# Load distribution data
taxaData <- paste0(dataDir, "distributions.csv") %>%
  read.csv()

# Load species lookup
species <- paste0(dataDir, "species_lookup.csv") %>%
  read.csv()

# Load schedule 2 species
# N.B. this .csv is made from the names in
# "The Environmental Targets (Biodiversity) (England) Regulations 2023"
# available here: https://www.legislation.gov.uk/uksi/2023/91/schedule/2/made
s2 <-  paste0(dataDir, "../Schedule2_species.csv") %>%
  read.csv()

# FILTER DATA -----------------------------------------------------------

# Add in scientific name
taxaData <- merge(species[, c("speccode", "scientific_name")], 
               taxaData, by = "speccode")

# Filter by location, resolution and record status
taxaData <- taxaData %>%
  # Filter to only last two Breeding Atlases to align with other records
  filter(period %in% c("1988-91", "2008-11")) %>% 
  # Filter out Irish records
  filter(island == "B") %>%
  # Filter to only 10km resolution records
  filter(resolution == 10) %>%
  # Filter out channel island records
  filter(!grepl("WA|WV", grid)) %>%
  # Filter out Isle of Man Records
  filter(!grepl("SC|NX30|NX40", grid)) %>%
  # Filter out non-certain records
  filter(!(status %in% c("Probable", "Possible")))

# Filter to schedule 2 species only
taxaData <- taxaData %>%
  filter(scientific_name %in% s2$Scientific.name)

# ADD IN COORDINATES ----------------------------------------------------

# Extract easting and northing from OS grid using BRCmap package
XY <- OSgrid2GB_EN(taxaData$grid,
                   centre = TRUE,
                   gr_prec = 10000)

# Join easting/northing with bird data
taxaData <- bind_cols(taxaData, XY)

# Remove redundant columns to save memory
taxaData <- taxaData %>%
  select(!c("speccode", "grid", "island", "resolution", "n_tenkms", "status"))

# Standardise column names
taxaData <- rename(taxaData, TAXON = scientific_name, PERIOD = period)

# DATA FOR MODELLING ----------------------------------------------------

# Filter to only the latest periods (>2000) to model
taxaModelData <- taxaData %>%
  filter(PERIOD == "2008-11" )

# SAVE -------------------------------------------------------------------

# Create directory
dir.create(paste0(dataDir, "../../Processed/birds"), 
           recursive = TRUE, showWarnings = FALSE)
# Save
save(taxaData,
     file = paste0(dataDir, "../../Processed/Birds/taxaData.RData"))
save(taxaModelData,
     file = paste0(dataDir, "../../Processed/Birds/taxaModelData.RData"))
