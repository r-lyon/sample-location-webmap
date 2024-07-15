# Plot locations of gage, IP, and MSGP sites that have sampled in current monitoring season
# RAL June 2024: updated to use sf package for loading spatial coordinates to leaflet, sp package no longer supported, also only showing stormwater samples, no baseflow samples
# July 2024 modified to run using Intellus downloaded data for current year

# R v. 4.4.0

# Load libraries
library(lubridate)
library(sf)
library(crosstalk)
library(leaflet)
library(htmlwidgets)
library(htmltools)
library(jsonlite)
library(httr)
library(tidyverse)
library(janitor)
library(lubridate)

# Input data downloaded from Intellus New Mexico (https://www.intellusnm.com/index.cfm)
gagedat <- 'Data/Intellus_2023_WT_All.csv'


# Read the csv data and clean the column header names
current_locs <- read_csv(gagedat) %>%
  clean_names() %>%
  select(location_id, northing, easting, sample_date, sample_type, sampling_plan_id) %>%
  mutate(sample_date = as.Date(sample_date, format="%m-%d-%Y")) %>%
  distinct()

# Get the year the data was collected, limit to one year when you run the query in Intellus
dat_year <- current_locs %>%
  mutate(year = year(sample_date)) %>%
  select(year) %>%
  distinct()

# Add program name based on location_id or sampling_plan_id (the id will change depending on the year)
current_locs <- current_locs %>%
  mutate(program = case_when(
    str_detect(location_id, "MSGP") ~ 'MSGP',
    str_detect(sampling_plan_id, "15155") ~ 'Gage',
    str_detect(location_id, 'LA-2') ~ 'Gage',
    str_detect(location_id, '-SMA-') ~ 'IP'
  ))

# Summarize all dates with samples into a single sample_date field
current_dates <- current_locs %>%
  group_by(location_id, program) %>%
  summarise(sample_date = toString(sample_date)) %>%
  ungroup()

# Select the coordinates for each sample location
spat_locs <- current_locs %>% select(location_id, northing, easting) %>%
  distinct()

df_locs <- data.frame(spat_locs)

# Join the current_dates
locs_sf <- current_dates %>%
  distinct() %>%
  left_join(df_locs, by='location_id') %>%
  filter(!is.na(program))

# Turn data frame of points into an sf and define coordinate reference system
locs_sf <- st_as_sf(locs_sf, coords = c("easting", "northing"))
st_crs(locs_sf) <- st_crs("+proj=tmerc +lat_0=31 +lon_0=-106.25 +k=0.9999 +x_0=500000.0001016001 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs")
head(locs_sf[,1:4])

# Convert coordinates to lat/long needed by leaflet
locs_sf <- st_transform(locs_sf, "+proj=longlat +datum=WGS84")
head(locs_sf[,1:4])

class(locs_sf)
st_geometry_type(locs_sf)

# Define the colors for each program
col_pal <- colorFactor(
  palette = c("darkturquoise", "darkblue", "darkorange"), domain = c('MSGP', 'IP','Gage')
)

# Create a shared data object
locs_sf_shared <- SharedData$new(locs_sf)

#Creat program checkboxes
prog_check <- filter_checkbox("prog", "Program", locs_sf_shared, ~program)

numcolor = unique(locs_sf$program)
print(numcolor)


# Creat the leaflet map
map_circles <- leaflet(locs_sf_shared, height = "100vh") %>%
  setView(lng =-106.285, lat=35.82, zoom = 12) %>%
  addProviderTiles("Esri.WorldTopoMap", group = 'Terrain') %>%
  addProviderTiles("OpenStreetMap.Mapnik", group = 'Street') %>%
  addProviderTiles("Esri.WorldImagery", group = 'Satellite') %>%
  addScaleBar("bottomright") %>%
  addLegend('bottomright', pal = col_pal, values = ~program, labels = c('MSGP', 'IP','Gage'), title = 'Program') %>%
  addCircleMarkers(group = 'Locations', color = ~col_pal(program),
                   stroke = FALSE, fillOpacity = 1, radius = 5, 
                   popup = ~paste0(location_id, '<br/>', " Date(s): ", '<strong>', sample_date, '</strong>' ),
                   #label = ~paste0(location_id_alias, "</br> Sample Type: ", sample_type, "</br>", sample_date),
                   labelOptions = labelOptions(textOnly = FALSE, textsize = 15)) %>%
  addLayersControl(
    baseGroups = c("Terrain", "Street", "Satellite"),
    overlayGroups = 'Locations',
    
    options = layersControlOptions(collapsed = FALSE)
    
  )

# Set program checkbox formatting
circle_map <- bscols(widths = c(2,10),
                     list(prog_check),
                     map_circles
)

circle_map

# Save the map as an html with the sampling year in the title
save_html(circle_map, paste0("Output/map/current_samples_collected_", dat_year,".html"))
