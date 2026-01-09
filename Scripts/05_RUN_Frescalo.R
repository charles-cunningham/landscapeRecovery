# HEADER ---------------------------------------------------------------
#
# Author: Charles Cunningham
# Email: charles.cunningham@york.ac.uk
# 
# Script name: Run Frescalo
#
# Script Description:

# INSTALL PACKAGES & LOAD LIBRARIES ------------------------------------

#devtools::install_github('BiologicalRecordsCentre/sparta')

library(tidyverse)
library(sparta)
library(BRCmap)
library(terra)

# SET DIRECTORIES ------------------------------------------------------

# Set data directory
dataDir <- "../Data/"

# Create spatial directory
dir.create(paste0(dataDir, "Spatial/GB"))

### DOWNLOAD AND PROCESS GB BOUNDARY FOR ANALYSIS ----------------------

# Information on GB boundary data here:
# https://www.data.gov.uk/dataset/8580e329-83c9-4646-bf93-d0411f00c53a/countries-december-2024-boundaries-uk-buc

# Set download url
url <- "https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/06d13e0421784911aa669768f25dcb18/shapefile?layers=0"

# Download
download.file(url = url,
              destfile = paste0(dataDir,"Spatial/GB/UK.zip"),
              sep = "",
              mode = "wb")

# Unzip
unzip(paste0(dataDir,"Spatial/GB/UK.zip"),
      exdir = paste0(dataDir,"Spatial/GB/UK_Unzip"),
      overwrite = TRUE)

# Read in UK boundary
UK <- paste0(dataDir,"Spatial/GB/UK_Unzip/",
                     "CTRY_DEC_2024_UK_BUC.shp") %>%
  vect

# Filter to GB only
GB <- boundaryUK[boundaryUK$CTRY24NM != "Northern Ireland",]

# Disaggregate
GB <- disagg(GB)

# Calculate area
GB$area_sqkm <- expanse(GB, unit = "km")

# Remove polygons with < 50km ^2 area
GB <- GB[GB$area_sqkm > 50]

# Aggregate back
GB <- aggregate(GB)

# Project to British National Grid
GB <- project(GB, "EPSG:27700")

# Save to GB folder
writeVector(GB, filename = paste0(dataDir,"Spatial/GB/GB.gpkg"))

# Remove files and directories no longer needed
rm(UK)
unlink(paste0(dataDir,"Spatial/GB/UK.zip"), recursive = TRUE)
unlink(paste0(dataDir,"Spatial/GB/UK_Unzip"), recursive = TRUE)

# CREATE GB RASTER -------------------------------------------

 



# X ----------------------------------------------------------

# Add back in grid
GRID <- gr_num2let(easting = taxaModelData$EASTING, northing = taxaModelData$NORTHING, keep_precision = FALSE)

GRID <- paste0(substr(GRID, 1,3), substr(GRID, 5, 5))

taxaModelData <- bind_cols(taxaModelData, data.frame(GRID))

taxaModelData$TAXON_ABB <- paste("species", as.numeric(as.factor(taxaModelData$TAXON )))

taxaModelData$YEAR <- as.numeric(2000)


fres_out <- frescalo(Data = taxaModelData[grep("SK",taxaModelData$GRID ),],
         frespath = file.path(getwd(), "../Frescalo_3a_windows.exe"),
         sp_col = "TAXON_ABB",
         site_col = "GRID",
         year_col = "YEAR",
         Fres_weights = "LCGB",
         time_periods = data.frame(start=c(2000),end=c(2000)),
         sinkdir = file.path(getwd(),  "../Data/Species/Processed", scheme))


# post processing


#extract values from frescalo object
sites <- unique(fres_out$freq$Location)
freq <- fres_out$freq
stats <- fres_out$stat
results <- NULL

### not all of this is needed, but was used for previous analysis
for (i in sites){
  freq.site<-freq[freq$Location==i,]
  no.benchmarks.pres<-nrow(freq.site[freq.site$Pres==1&freq.site$Rank_1<0.27,])   # number of benchmarks present
  no.species.pres<-nrow(freq.site[freq.site$Pres==1,])                 # total number of species present
  est.sp.rich<-as.numeric(stats$Spnum_out[stats$Location==i])    # expected species richness of the neighbourhood
  prop.bench.pres<-no.benchmarks.pres/no.species.pres           # proportion of species present that are benchmarks
  if(is.na(prop.bench.pres)){prop.bench.pres<-0}
  rec.intensity.all.sp<-no.species.pres/est.sp.rich     # rec. intensity measure 1- proportion of expected species that are present in the sample
  exp.no.bench<-nrow(freq.site[freq.site$Rank_1<0.27,])   # the expected number of benchmarks in the neighbourhood
  rec.intensity.bench<-no.benchmarks.pres/exp.no.bench  # rec intensity measure 2-   proportion of benchmarks present in sample
  if(is.na(rec.intensity.bench)){rec.intensity.bench<-0}
  location<-i # this is the cell number from the pts object at beginning
  results.temp<-data.frame(location,no.benchmarks.pres,no.species.pres,prop.bench.pres,est.sp.rich,exp.no.bench,rec.intensity.all.sp,rec.intensity.bench)
  results<-rbind(results,results.temp)
}

### the effort column we will use is rec.intensity.all
results$rec.intensity.all.sp %>% unique(
)
#######################
### (5) CREATE AND SAVE WEIGHT TABLES
#######################

#Some cells cannot be calculated which means you now have to match the cells up

#GB coords as a dataframe, and add an ID column (identical to results)
GB.coord <- as.data.frame(GB.coord)
GB.coord$Loc <- row(GB.coord)[,1]

#merge results to coordinates, and convert to spdf
results <- merge(GB.coord, results, by.x = "Loc", by.y = "location")
coordinates(results) <- ~ x + y

#rasterise to obtain rec.intensity.all raster
output <- rasterize(results, base.grid, results$rec.intensity.all.sp)

#assign out of loop
assign(paste0("rec.eff.rast.", j), output)

#end loop
}

#Save to .Rdata file
save(list = c("rec.eff.rast.1", "rec.eff.rast.2", "rec.eff.rast.3"),
     file = paste0("Species_datasets/", taxa.group, "/Effort_weights.RData")) ### CHANGE HERE
}

#load("INLA/Frescalo/Effort_weights.RData")
