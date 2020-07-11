# COVID-19 Racial and Ethnicity Disparity Dashboard

DRTS #5404 `Covid_19_Race_and_Ethnicity_Dashboard`


## Purpose

This project takes existing data from The COVID Racial Data Tracker and reforms
it to display a comparison between Oregon and other states and territories.

The genesis of this project was this email message:

> On Jul 1, 2020, at 9:50 AM, Allen Patrick <Patrick.Allen@dhsoha.state.or.us> wrote:
> 
> Jeremy,
> 
> Do you have anyone who could spend a little time on a data analysis project for
> me? The link below is to racial disparity data from covid. I need someone to a)
> validate that we agree with the reported data (some of the data looks a little
> off to me), and then b) figure out a way to display or describe the data in a
> way that benchmarks our disparities against other states.
> 
> Here's the link:
> 
> https://covidtracking.com/race/dashboard
> 
> Let me know if you’ve got someone to hand this off to. Thanks!
> 
> Pat.


## Source information

Links to source data from The COVID Racial Data Tracker:

* [Main page](https://covidtracking.com/race)
* [Dashboard](https://covidtracking.com/race/dashboard/)
* [About](https://covidtracking.com/race/about)
* [CSV](https://docs.google.com/spreadsheets/d/e/2PACX-1vR_xmYt4ACPDZCDJcY12kCiMiH0ODyx3E1ZvgOHB8ae1tRcjXbs_yWBOA4j4uoCEADVfC1PS2jYO68B/pub?gid=43720681&single=true&output=csv)
  * Google Docs spreadsheet
  * The data is not currently packaged in The COVID Racial Data Tracker's data API
  * Data is "updated twice per week"; from what I can tell it's updated on Sunday and Wednesday
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


## To do:

* Investigate why AI/AN for Washington does not get flagged as disparate (where it does in the CRDT dashboard)
  * I suspect CRDT's flag is a result of rounding/precision error
  * Could also be that the ACS data I'm pulling is not the same as the ACS data CRDT uses
  * Email query sent to racial.data@covidtracking.com on 2020-07-07
* **[Won't fix]** Fix the doughnut hole selection issue
  * Does not seem possible without sacrificing other functionality
  * https://community.tableau.com/s/question/0D54T00000C6ZzESAV/doughnut-selectionhover-issue
* Automate or semi-automate the build workflow
  * Would like to combine steps 1 and 2
* Add "the" before "District of Columbia"
* Duplicate ranking dashboard for `disparity_excess_pct`


## Press

* The NY Times has some disparity data I would like to get my hands on
  * https://www.nytimes.com/interactive/2020/07/05/us/coronavirus-latinos-african-americans-cdc-data.html
  * Their data is from the CDC and was obtained by a FOIA request
* Northwestern also has some disparity data
  * https://www.ipr.northwestern.edu/news/2020/covid-magnifies-racial-disparities.html
  * Survey data and not broken out by state
