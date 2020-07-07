# COVID-19 Racial and Ethnicity Disparity Dashboard

DRTS #5404 `DRT_Covid_19_Race_and_Ethnicity_Dashboard`


## Background

Links to source data from The COVID Racial Data Tracker:

* [Main page](https://covidtracking.com/race)
* [Dashboard](https://covidtracking.com/race/dashboard/)
* [About](https://covidtracking.com/race/about)
* [CSV](https://docs.google.com/spreadsheets/d/e/2PACX-1vR_xmYt4ACPDZCDJcY12kCiMiH0ODyx3E1ZvgOHB8ae1tRcjXbs_yWBOA4j4uoCEADVfC1PS2jYO68B/pub?gid=43720681&single=true&output=csv)
  * Google Docs spreadsheet
  * The data is not currently packaged in The COVID Racial Data Tracker's data API
* [Github](https://github.com/COVID19Tracking)
  * This didn't prove to be too terribly useful; it houses the repos for their main data products

Links to OHA's data visualizations

* [Table form](https://public.tableau.com/profile/oregon.health.authority.covid.19#!/vizhome/OregonCOVID-19CaseDemographicsandDiseaseSeverityStatewide-SummaryTable/DemographicDataSummaryTable)
* [Data viz form](https://public.tableau.com/profile/oregon.health.authority.covid.19#!/vizhome/OregonCOVID-19CaseDemographicsandDiseaseSeverityStatewide/DemographicData)


## Build

1. Run the `make.bat` script from the Windows command line
   1. The script executes `mungeData.R`, which creates the source data file, `Data\disparity_data.csv`, for the Tableau workbook
   2. The data file is timestamped and version controlled
2. Publish `Covid19 Racial and Ethnic Disparity.twb` to the internal Tableau server

