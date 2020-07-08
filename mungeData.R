library(checkpoint)
checkpoint("2020-07-01")


library(magrittr)
library(tidyverse)


state <- read_csv(file.path("Data", "state_names.csv"))
reporting_characteristics <-
  read_csv(file.path("Data", "reporting_characteristics.csv")) %>%
  inner_join(state %>% select(State_Abbr, State_Name),
             by = c("State" = "State_Abbr")) %>%
  mutate(note_indicator = case_when(metric_nodata_flag & different_from_oregon_flag ~ "\u2020 \u2021",
                                    metric_nodata_flag ~ "\u2020",
                                    different_from_oregon_flag ~ "\u2021")) %>%
  mutate(reporting_note1 =
           case_when(metric_nodata_flag ~ sprintf("\u2020 %s does not report %s data for %s",
                     State_Name, tolower(variable), tolower(metric))),
         reporting_note2 =
           case_when(different_from_oregon_flag ~
                       sprintf("\u2021 %s uses different categories for race and ethnicity than the US Census. Their data should not be compared to Oregon's",
                               State_Name, tolower(variable), tolower(metric))))


# The COVID Tracking Projects's Racial Data Dashboard
# https://covidtracking.com/race/dashboard
url <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vR_xmYt4ACPDZCDJcY12kCiMiH0ODyx3E1ZvgOHB8ae1tRcjXbs_yWBOA4j4uoCEADVfC1PS2jYO68B/pub?gid=43720681&single=true&output=csv"


calculatePercent <- function(data) {
  require(magrittr)
  require(dplyr)
  data %>%
    mutate(Cases_Black_Pct = Cases_Black / Cases_Denom,
           Cases_LatinX_Pct = Cases_LatinX / Cases_Denom,
           Cases_Asian_Pct = Cases_Asian / Cases_Denom,
           Cases_NHPI_Pct = Cases_NHPI / Cases_Denom,
           Cases_AIAN_Pct = Cases_AIAN / Cases_Denom,
           Cases_Multiracial_Pct = Cases_Multiracial / Cases_Denom,
           Cases_White_Pct = Cases_White / Cases_Denom,
           Cases_Other_Pct = Cases_Other / Cases_Denom,
           Cases_Ethnicity_Hispanic_Pct = Cases_Ethnicity_Hispanic / (Cases_Ethnicity_Hispanic + Cases_Ethnicity_NonHispanic),
           Cases_Ethnicity_NonHispanic_Pct = Cases_Ethnicity_NonHispanic / (Cases_Ethnicity_Hispanic + Cases_Ethnicity_NonHispanic),
           Deaths_Black_Pct = Deaths_Black / Deaths_Denom,
           Deaths_LatinX_Pct = Deaths_LatinX / Deaths_Denom,
           Deaths_Asian_Pct = Deaths_Asian / Deaths_Denom,
           Deaths_NHPI_Pct = Deaths_NHPI / Deaths_Denom,
           Deaths_AIAN_Pct = Deaths_AIAN / Deaths_Denom,
           Deaths_Multiracial_Pct = Deaths_Multiracial / Deaths_Denom,
           Deaths_White_Pct = Deaths_White / Deaths_Denom,
           Deaths_Other_Pct = Deaths_Other / Deaths_Denom,
           Deaths_Ethnicity_Hispanic_Pct = Deaths_Ethnicity_Hispanic / (Deaths_Ethnicity_Hispanic + Deaths_Ethnicity_NonHispanic),
           Deaths_Ethnicity_NonHispanic_Pct = Deaths_Ethnicity_NonHispanic / (Deaths_Ethnicity_Hispanic + Deaths_Ethnicity_NonHispanic))
}
transpose <- function(data, suffix) {
  require(magrittr)
  require(dplyr)
  data %>%
    select(c(Date, State, ends_with(suffix))) %>%
    pivot_longer(-c(Date, State)) %>%
    mutate(name = gsub(suffix, "", name))
}


pct_ex_Unknown <-
  read_csv(url) %>%
  mutate(Cases_Denom = Cases_Total - Cases_Unknown,
         Deaths_Denom = Deaths_Total - Deaths_Unknown) %>%
  calculatePercent() %>%
  transpose("_Pct") %>%
  rename(percent = value)

pct_incl_Unknown <-
  read_csv(url) %>%
  mutate(Cases_Denom = Cases_Total,
         Deaths_Denom = Deaths_Total) %>%
  calculatePercent() %>%
  transpose("_Pct") %>%
  rename(percent_incl_Unknown = value)

small_numer_flag <-
  read_csv(url) %>%
  mutate(Cases_Black_small_numer_flag = as.logical(Cases_Black < 30),
         Cases_LatinX_small_numer_flag = as.logical(Cases_LatinX < 30),
         Cases_Asian_small_numer_flag = as.logical(Cases_Asian < 30),
         Cases_NHPI_small_numer_flag = as.logical(Cases_NHPI < 30),
         Cases_AIAN_small_numer_flag = as.logical(Cases_AIAN < 30),
         Cases_Multiracial_small_numer_flag = as.logical(Cases_Multiracial < 30),
         Cases_White_small_numer_flag = as.logical(Cases_White < 30),
         Cases_Other_small_numer_flag = as.logical(Cases_Other < 30),
         Cases_Ethnicity_Hispanic_small_numer_flag = as.logical(Cases_Ethnicity_Hispanic < 30),
         Cases_Ethnicity_NonHispanic_small_numer_flag = as.logical(Cases_Ethnicity_NonHispanic < 30),
         Deaths_Black_small_numer_flag = as.logical(Deaths_Black < 30),
         Deaths_LatinX_small_numer_flag = as.logical(Deaths_LatinX < 30),
         Deaths_Asian_small_numer_flag = as.logical(Deaths_Asian < 30),
         Deaths_NHPI_small_numer_flag = as.logical(Deaths_NHPI < 30),
         Deaths_AIAN_small_numer_flag = as.logical(Deaths_AIAN < 30),
         Deaths_Multiracial_small_numer_flag = as.logical(Deaths_Multiracial < 30),
         Deaths_White_small_numer_flag = as.logical(Deaths_White < 30),
         Deaths_Other_small_numer_flag = as.logical(Deaths_Other < 30),
         Deaths_Ethnicity_Hispanic_small_numer_flag = as.logical(Deaths_Ethnicity_Hispanic < 30),
         Deaths_Ethnicity_NonHispanic_small_numer_flag = as.logical(Deaths_Ethnicity_NonHispanic < 30)) %>%
  transpose("_small_numer_flag") %>%
  rename(small_numer_flag = value)
  

crdt <-
  pct_ex_Unknown %>%
  inner_join(small_numer_flag) %>%
  inner_join(pct_incl_Unknown) %>%
  mutate(metric = case_when(grepl("Cases", name) ~ "Cases",
                            grepl("Deaths", name) ~ "Deaths")) %>%
  mutate(category = gsub("(Cases|Deaths)_", "", name)) %>%
  mutate(variable = case_when(grepl("Ethnicity", name) ~ "Ethnicity",
                              TRUE ~ "Race")) %>%
  mutate(category = case_when(category == "Black" ~ "Black or African American",
                              category == "LatinX" ~ "Hispanic or Latino",
                              category == "NHPI" ~ "Native Hawaiian and Other Pacific Islander",
                              category == "AIAN" ~ "American Indian and Alaska Native",
                              category == "Other" ~ "Some other race",
                              category == "Multiracial" ~ "Two or more races",
                              TRUE ~ category)) %>%
  mutate(category = gsub("Ethnicity_", "", category) %>% gsub("_Pct", "", .)) %>%
  mutate(category = case_when(category == "NonHispanic" ~ "Not Hispanic",
                              TRUE ~ category)) %>%
  mutate(category = case_when(variable == "Ethnicity" & category == "Hispanic" ~ "Hispanic or Latino (of any race)",
                              variable == "Ethnicity" & category == "Not Hispanic" ~ "Not Hispanic or Latino",
                              TRUE ~ category)) %>%
  select(Date, State, metric, variable, category, percent, percent_incl_Unknown, small_numer_flag) %>%
  inner_join(state, by = c("State" = "State_Abbr")) %>%
  mutate(oregon_flag = as.logical(State == "OR")) %>%
  select(Date, State, State_Name, everything())


# ACS data seems a little off compared to https://covidtracking.com/race/dashboard
# The "Two or more races" category is slightly off
f <-
  list.files("Data") %>%
  grep("ACSDP5Y2018", ., value = TRUE) %>%
  file.path("Data", .) %>%
  list.files(full.names = TRUE) %>%
  grep("data_with_overlays", ., value = TRUE)
col <- c("NAME",
         "DP05_0037PE",
         "DP05_0038PE",
         "DP05_0039PE",
         "DP05_0044PE",
         "DP05_0052PE",
         "DP05_0057PE",
         "DP05_0058PE",
         "DP05_0071PE",
         "DP05_0076PE")
labels <- read_csv(f, n_max = 1) %>% select(col) %>% pivot_longer(everything(), values_to = "label")
names <- read_csv(f, col_names = FALSE, n_max = 1) %>% pivot_longer(everything()) %>% filter(value %in% labels$name)
acs <-
  read_csv(f, col_names = FALSE, skip = 2) %>%
  select(names$name) %>%
  rename_all(list(~ names$value)) %>%
  pivot_longer(starts_with("DP05")) %>%
  rename(State_Name = NAME,
         percent = value) %>%
  inner_join(labels) %>%
  rename(col_name = name) %>%
  mutate(label = gsub("Percent Estimate!!", "", label) %>%
                 gsub("Total population!!", "", .) %>%
                 gsub("One race!!", "", .) %>%
                 gsub("HISPANIC OR LATINO AND RACE!!", "", .) %>%
                 gsub("RACE!!", "", .))


# For states that report Hispanic or Latino as a race category, add the
# ACS Hispanic or Latino ethnicity data with the "Hispanic or Latino"
# label, so the left_join() can join it
lookup <-
  reporting_characteristics %>%
  filter(category == "Hispanic or Latino" & category_reporting_flag) %>%
  pull(State_Name) %>%
  unique()
temp <-
  acs %>%
  filter(State_Name %in% lookup & label == "Hispanic or Latino (of any race)") %>%
  mutate(label = gsub(" \\(of any race\\)", "", label))
acs <- bind_rows(acs, temp)


# Identify race and ethnicity categories reported in Oregon
oregon_categories <-
  crdt %>%
  filter(State == "OR" & !is.na(percent)) %>%
  select(variable, category) %>%
  unique() %>%
  mutate(oregon_category_flag = TRUE)


nth <- function (x) {
  str <- case_when(x == 1 ~ "st",
                   x == 2 ~ "nd",
                   x == 3 ~ "rd",
                   TRUE ~ "th")
  sprintf("%.0f%s", x)
}


df <-
  acs %>%
  select(State_Name, percent, label) %>%
  rename(percent_ACS = percent,
         category = label) %>%
  mutate(percent_ACS = percent_ACS / 100) %>%
  left_join(crdt, .) %>%
  left_join(reporting_characteristics) %>%
  left_join(oregon_categories) %>%
  mutate(disparity_factor = percent / percent_ACS,
         disparity_excess_pct = (percent - percent_ACS) / percent_ACS) %>%
  group_by(metric, category) %>%
  mutate(disparity_rank = rank(-disparity_factor),
         denom_ranked = sum(!is.na(percent))) %>%
  ungroup() %>%
  mutate(greater_than_ACS_flag = as.logical(disparity_excess_pct > 1/3)) %>%
  mutate(remains_elevated_incl_Unknown_flag = as.logical(percent_incl_Unknown > percent_ACS)) %>%
  mutate(disparity_flag = greater_than_ACS_flag &
                          remains_elevated_incl_Unknown_flag & 
                          !small_numer_flag) %>%
  mutate(disparity_indicator = case_when(disparity_flag ~ "*")) %>%
  mutate(category_text1 = case_when(category == "Native Hawaiian and Other Pacific Islander" ~ "Native Hawaiian and other Pacific Islander",
                                    category == "Not Hispanic or Latino" ~ "not Hispanic or Latino",
                                    category == "Some other race" ~ tolower(category),
                                    category == "Two or more races" ~ "multiracial",
                                    TRUE ~ category)) %>%
  mutate(category_text2 = case_when(category == "Hispanic or Latino (of any race)" ~ "Hispanic or Latinos (of any race)",
                                    category == "Some other race" ~ "Individuals of some other race",
                                    category == "Two or more races" ~ "Multiracial individuals",
                                    TRUE ~ sprintf("%ss", category))) %>%
  mutate(tooltip_text1 = sprintf("%s disparity criteria.",
                                 case_when( disparity_flag ~ "* Meets",
                                           !disparity_flag ~ "Does not meet",
                                           is.na(disparity_flag) ~ "No comparable census data to evaulate")),
         tooltip_text2 = sprintf("of COVID-19 %s in %s are %s.",
                                 tolower(metric),
                                 State_Name,
                                 category_text1),
         tooltip_text3 = sprintf("%s of the population are %s.",
                                 case_when(round(percent_ACS * 100) < 1 ~ "Less than half of 1%",
                                           TRUE ~ sprintf("%.0f%%", percent_ACS * 100)),
                                 category_text1),
         tooltip_text4 = sprintf("%s comprise %.1f times the number of %s than expected.",
                                 category_text2,
                                 disparity_factor,
                                 tolower(metric)),
         tooltip_text5 = sprintf("%s is ranked %.0f%s out of %.0f states and territories.",
                                 State_Name,
                                 disparity_rank,
                                 case_when(grepl("(^|[2-9])1$", sprintf("%.0f", disparity_rank)) ~ "st",
                                           grepl("(^|[2-9])2$", sprintf("%.0f", disparity_rank)) ~ "nd",
                                           grepl("(^|[2-9])3$", sprintf("%.0f", disparity_rank)) ~ "rd",
                                           TRUE ~ "th"),
                                 denom_ranked)) %>%
  mutate(tooltip_text1 = case_when(is.na(percent) ~ NA_character_,
                                   TRUE ~ tooltip_text1),
         tooltip_text2 = case_when(is.na(percent) ~ NA_character_,
                                   TRUE ~ tooltip_text2),
         tooltip_text3 = case_when(is.na(percent_ACS) ~ NA_character_,
                                   TRUE ~ tooltip_text3),
         tooltip_text4 = case_when(is.na(percent) ~ NA_character_,
                                   TRUE ~ tooltip_text4),
         tooltip_text5 = case_when(is.na(percent) ~ NA_character_,
                                   TRUE ~ tooltip_text5)) %>%
  mutate(tooltip_text9 = case_when(category == "Hispanic or Latino" & category_reporting_flag ~ "Oregon reports Hispanic or Latino data as ethnicity, not race. Switch to \"ethnicity\" view for direct comparison.")) %>%
  mutate(timestamp = Sys.time()) %>%
  select(-starts_with("category_rep"), -category_text1) %>%
  filter(!(State_Name %in% c("American Samoa",
                             "Northern Mariana Islands")))

f <- file.path("Data", "disparity_data.csv")
df %>% write_csv(f, na = "")
file.info(f)
