library(checkpoint)
checkpoint("2020-07-01")


library(magrittr)
library(tidyverse)


state <- read_csv(file.path("Data", "state_names.csv"))


# The COVID Tracking Projects's Racial Data Dashboard
# https://covidtracking.com/race/dashboard
url <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vR_xmYt4ACPDZCDJcY12kCiMiH0ODyx3E1ZvgOHB8ae1tRcjXbs_yWBOA4j4uoCEADVfC1PS2jYO68B/pub?gid=43720681&single=true&output=csv"


temp <-
  read_csv(url) %>%
  mutate(Cases_Total_ex_Unknown = Cases_Total - Cases_Unknown,
         Deaths_Total_ex_Unknown = Deaths_Total - Deaths_Unknown) %>%
  mutate(Cases_Black_Pct = Cases_Black / Cases_Total_ex_Unknown,
         Cases_Asian_Pct = Cases_Asian / Cases_Total_ex_Unknown,
         Cases_NHPI_Pct = Cases_NHPI / Cases_Total_ex_Unknown,
         Cases_AIAN_Pct = Cases_AIAN / Cases_Total_ex_Unknown,
         Cases_Multiracial_Pct = Cases_Multiracial / Cases_Total_ex_Unknown,
         Cases_White_Pct = Cases_White / Cases_Total_ex_Unknown,
         Cases_Other_Pct = Cases_Other / Cases_Total_ex_Unknown,
         Cases_Ethnicity_Hispanic_Pct = Cases_Ethnicity_Hispanic / Cases_Total_ex_Unknown,
         Cases_Ethnicity_NonHispanic_Pct = Cases_Ethnicity_NonHispanic / Cases_Total_ex_Unknown,
         Cases_Ethnicity_Unknown_Pct = Cases_Ethnicity_Unknown / Cases_Total_ex_Unknown,
         Deaths_Black_Pct = Deaths_Black / Deaths_Total_ex_Unknown,
         Deaths_Asian_Pct = Deaths_Asian / Deaths_Total_ex_Unknown,
         Deaths_NHPI_Pct = Deaths_NHPI / Deaths_Total_ex_Unknown,
         Deaths_AIAN_Pct = Deaths_AIAN / Deaths_Total_ex_Unknown,
         Deaths_Multiracial_Pct = Deaths_Multiracial / Deaths_Total_ex_Unknown,
         Deaths_White_Pct = Deaths_White / Deaths_Total_ex_Unknown,
         Deaths_Other_Pct = Deaths_Other / Deaths_Total_ex_Unknown,
         Deaths_Ethnicity_Hispanic_Pct = Deaths_Ethnicity_Hispanic / Deaths_Total_ex_Unknown,
         Deaths_Ethnicity_NonHispanic_Pct = Deaths_Ethnicity_NonHispanic / Deaths_Total_ex_Unknown,
         Deaths_Ethnicity_Unknown_Pct = Deaths_Ethnicity_Unknown / Deaths_Total_ex_Unknown) %>%
  mutate(Cases_Black_small_denom_flag = as.logical(Cases_Black < 30),
         Cases_Asian_small_denom_flag = as.logical(Cases_Asian < 30),
         Cases_NHPI_small_denom_flag = as.logical(Cases_NHPI < 30),
         Cases_AIAN_small_denom_flag = as.logical(Cases_AIAN < 30),
         Cases_Multiracial_small_denom_flag = as.logical(Cases_Multiracial < 30),
         Cases_White_small_denom_flag = as.logical(Cases_White < 30),
         Cases_Other_small_denom_flag = as.logical(Cases_Other < 30),
         Cases_Ethnicity_Hispanic_small_denom_flag = as.logical(Cases_Ethnicity_Hispanic < 30),
         Cases_Ethnicity_NonHispanic_small_denom_flag = as.logical(Cases_Ethnicity_NonHispanic < 30),
         Cases_Ethnicity_Unknown_small_denom_flag = as.logical(Cases_Ethnicity_Unknown < 30),
         Deaths_Black_small_denom_flag = as.logical(Deaths_Black < 30),
         Deaths_Asian_small_denom_flag = as.logical(Deaths_Asian < 30),
         Deaths_NHPI_small_denom_flag = as.logical(Deaths_NHPI < 30),
         Deaths_AIAN_small_denom_flag = as.logical(Deaths_AIAN < 30),
         Deaths_Multiracial_small_denom_flag = as.logical(Deaths_Multiracial < 30),
         Deaths_White_small_denom_flag = as.logical(Deaths_White < 30),
         Deaths_Other_small_denom_flag = as.logical(Deaths_Other < 30),
         Deaths_Ethnicity_Hispanic_small_denom_flag = as.logical(Deaths_Ethnicity_Hispanic < 30),
         Deaths_Ethnicity_NonHispanic_small_denom_flag = as.logical(Deaths_Ethnicity_NonHispanic < 30),
         Deaths_Ethnicity_Unknown_small_denom_flag = as.logical(Deaths_Ethnicity_Unknown < 30)) %>%
  select(c(Date, State, ends_with("Pct"), ends_with("flag")))
  
crdt <-
  inner_join(temp %>%
               select(c(Date, State, ends_with("Pct"))) %>%
               pivot_longer(-c(Date, State), values_to = "percent") %>%
               mutate(name = gsub("_Pct", "", name)),
             temp %>%
               select(c(Date, State, ends_with("small_denom_flag"))) %>%
               pivot_longer(-c(Date, State), values_to = "small_denom_flag") %>%
               mutate(name = gsub("_small_denom_flag", "", name))) %>%
  mutate(metric = case_when(grepl("Cases", name) ~ "Cases",
                            grepl("Deaths", name) ~ "Deaths")) %>%
  mutate(category = gsub("(Cases|Deaths)_", "", name)) %>%
  mutate(variable = case_when(grepl("Ethnicity", name) ~ "Ethnicity",
                              TRUE ~ "Race")) %>%
  mutate(category = case_when(category == "NHPI" ~ "Pacific Is.",
                              category == "AIAN" ~ "AI/AN",
                              TRUE ~ category)) %>%
  mutate(category = gsub("Ethnicity_", "", category) %>% gsub("_Pct", "", .)) %>%
  mutate(category = case_when(category == "NonHispanic" ~ "Not Hispanic",
                              category == "Unknown" ~ "Refused/Unknown",
                              TRUE ~ category)) %>%
  select(Date, State, metric, variable, category, percent, small_denom_flag) %>%
  inner_join(state, by = c("State" = "State_Abbr") ) %>%
  mutate(oregon_flag = as.logical(State == "OR")) %>%

crdt %>%
  filter(State == "OR") %>%
  write_csv(file.path("Data", "CRDT_Oregon.csv"), na = "")
crdt %>%
  filter(State != "OR") %>%
  write_csv(file.path("Data", "CRDT_NotOregon.csv"), na = "")