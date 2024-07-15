# sample-location-webmap Project
Create a leaflet based webmap showing stormwater sample locations for a given year

This project involves downloading stormwater data from the Intellus New Mexico publicly-accessible database of environmental monitoring data provided by the Los Alamos National Laboratory (LANL) and the New Mexico Environment Department DOE Oversight Bureau (NMED DOE OB). All data contained in this system are unclassified.

## Project Structure

- `code/`: Contains the R script to create the webmap.
- `data/`: Contains the raw data file downloaded from Intellus New Mexico.
- `ouput/`: Contains the html output file

## Requirements

- R
- R libraries: `tidyverse', 'lubridate', 'sf', 'crosstalk', 'leaflet', 'htmlwidgets', 'htmltools', 'jsonlite', 'httr'

## How to Run the Project

1. Clone the repository:
   ```sh
   git clone https://github.com/r-lyon/sample-location-webmap.git
   cd sample-location-webmap
2. Open the R script in RStudio or your preferred R environment.
3. Ensure the necessary libraries are installed.
4. Run the script to generate the results.
