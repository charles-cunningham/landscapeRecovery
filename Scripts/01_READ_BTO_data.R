# HEADER ---------------------------------------------------------------
#
# Author: Charles Cunningham
# Email: charles.cunningham@york.ac.uk
# 
# Script name: Read BTO data
#
# Script Description:

# LOAD LIBRARIES & INSTALL PACKAGES ------------------------------------



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

# PROCESS DATA -----------------------------------------------------------














