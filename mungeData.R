library(checkpoint)
checkpoint("2020-07-01")


library(magrittr)
library(tidyverse)
library(scales)
library(censusapi)
library(dineq)


fixState <- function (x, isStartOfSentence = TRUE) {
  case_when(grepl("district.*columbia", x, ignore.case = TRUE) &  isStartOfSentence ~ sprintf("The %s", x),
            grepl("district.*columbia", x, ignore.case = TRUE) & !isStartOfSentence ~ sprintf("the %s", x),
            TRUE ~ x)
}


state <- read_csv(file.path("Data", "state_names.csv"))
reporting_characteristics <-
  read_csv(file.path("Data", "reporting_characteristics.csv")) %>%
  inner_join(state %>% select(State_Abbr, State_Name),
             by = c("State" = "State_Abbr")) %>%
  mutate(note_indicator = case_when(metric_nodata_flag & different_from_oregon_flag ~ "\u2020 \u2021",
                                    metric_nodata_flag ~ "\u2020",
                                    different_from_oregon_flag ~ "\u2021")) %>%
  mutate(reporting_note1 =
           case_when(metric_nodata_flag ~ sprintf("\u2020 %s does not report %s data for %s.",
                     fixState(State_Name), tolower(variable), tolower(metric))),
         reporting_note2 =
           case_when(different_from_oregon_flag ~
                       sprintf("\u2021 %s uses different categories for race and ethnicity than the US Census. Their data should not be compared to Oregon's.",
                               fixState(State_Name), tolower(variable), tolower(metric))))


# The COVID Tracking Projects's Racial Data Dashboard
# https://covidtracking.com/race/dashboard
readCRDT <- function () {
  url <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vS8SzaERcKJOD_EzrtCDK1dX1zkoMochlA9iHoHg_RSw3V8bkpfk1mpw4pfL5RdtSOyx_oScsUtyXyk/pub?gid=43720681&single=true&output=csv"
  require(magrittr)
  require(dplyr)
  require(readr)
  col_types <- c("n", "c", rep("n", 26)) %>% paste(collapse = "")
  data <- read_csv(url, col_types = col_types)
  message(sprintf("CRDT data updated: %s",
                  data %>% pull(Date) %>% unique() %>% max() %>% as.character() %>% as.Date(format = "%Y%m%d")))
  data %>%
    filter(Date == max(.$Date))
}

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


df <- readCRDT()


totals <-
  df %>%
  select(Date, State, Cases_Total, Deaths_Total) %>%
  mutate(cases_reported_flag = !is.na(Cases_Total),
         deaths_reported_flag = !is.na(Deaths_Total)) %>%
  mutate(timestamp = Sys.time()) %>%
  mutate(timestamp = Sys.time(),
         Date = Date %>% as.character() %>% as.Date(format = "%Y%m%d"))

pct_ex_Unknown <-
  df %>%
  mutate(Cases_Denom = Cases_Total - Cases_Unknown,
         Deaths_Denom = Deaths_Total - Deaths_Unknown) %>%
  calculatePercent() %>%
  transpose("_Pct") %>%
  rename(percent = value)

pct_incl_Unknown <-
  df %>%
  mutate(Cases_Denom = Cases_Total,
         Deaths_Denom = Deaths_Total) %>%
  calculatePercent() %>%
  transpose("_Pct") %>%
  rename(percent_incl_Unknown = value)

small_numer_flag <-
  df %>%
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
  
counts <-
  df %>%
  mutate(Cases_Black_count = Cases_Black,
         Cases_LatinX_count = Cases_LatinX,
         Cases_Asian_count = Cases_Asian,
         Cases_NHPI_count = Cases_NHPI,
         Cases_AIAN_count = Cases_AIAN,
         Cases_Multiracial_count = Cases_Multiracial,
         Cases_White_count = Cases_White,
         Cases_Other_count = Cases_Other,
         Cases_Ethnicity_Hispanic_count = Cases_Ethnicity_Hispanic,
         Cases_Ethnicity_NonHispanic_count = Cases_Ethnicity_NonHispanic,
         Deaths_Black_count = Deaths_Black,
         Deaths_LatinX_count = Deaths_LatinX,
         Deaths_Asian_count = Deaths_Asian,
         Deaths_NHPI_count = Deaths_NHPI,
         Deaths_AIAN_count = Deaths_AIAN,
         Deaths_Multiracial_count = Deaths_Multiracial,
         Deaths_White_count = Deaths_White,
         Deaths_Other_count = Deaths_Other,
         Deaths_Ethnicity_Hispanic_count = Deaths_Ethnicity_Hispanic,
         Deaths_Ethnicity_NonHispanic_count = Deaths_Ethnicity_NonHispanic) %>%
  transpose("_count") %>%
  rename(count = value)

crdt <-
  pct_ex_Unknown %>%
  inner_join(counts) %>%
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
  select(Date, State, metric, variable, category, percent, count, percent_incl_Unknown, small_numer_flag) %>%
  inner_join(state, by = c("State" = "State_Abbr")) %>%
  mutate(oregon_flag = as.logical(State == "OR")) %>%
  select(Date, State, State_Name, everything())


# Process ACS data in chunks
# Some states report Hispanic and Latinos as a race category in addition to an ethnic category
# This screws up a simple comparison to ACS
# So need to build some logic to handle these cases
lookup <-
  reporting_characteristics %>%
  filter(category == "Hispanic or Latino" & category_reporting_flag) %>%
  pull(State_Name) %>%
  unique()
mungeACS <- function (col, variable) {
  require(magrittr)
  require(dplyr)
  require(censusapi)
  metadata <-
    listCensusMetadata(name = "acs/acs5/profile", vintage = 2018) %>%
    select(name, label) %>%
    filter(name %in% col)
  key <- read_csv("C:/Users/or0250652/OneDrive - Oregon DHSOHA/API keys/censusAPIKey.txt", col_names = FALSE) %>% pull(X1)
  getCensus("acs/acs5/profile", 2018, var = col, region = "state", key = key) %>%
    select(-state) %>%
    # rename_all(list(~ names$value)) %>%
    pivot_longer(starts_with("DP05"), values_to = variable) %>%
    rename(State_Name = NAME) %>%
    inner_join(metadata) %>%
    select(-name) %>%
    mutate(label = gsub("Percent Estimate!!", "", label) %>%
                   gsub("Estimate!!", "", .) %>%
                   gsub("Total population!!", "", .) %>%
                   gsub("One race!!", "", .) %>%
                   gsub("HISPANIC OR LATINO AND RACE!!", "", .) %>%
                   gsub("RACE!!", "", .))
}
acs1 <-
  c("NAME",
    "DP05_0037PE",      # RACE!!Total population!!One race!!White,
    "DP05_0038PE",      # RACE!!Total population!!One race!!Black or African American,
    "DP05_0039PE",      # RACE!!Total population!!One race!!American Indian and Alaska Native,
    "DP05_0044PE",      # RACE!!Total population!!One race!!Asian,
    "DP05_0052PE",      # RACE!!Total population!!One race!!Native Hawaiian and Other Pacific Islander,
    "DP05_0057PE",      # RACE!!Total population!!One race!!Some other race,
    "DP05_0058PE") %>%  # RACE!!Total population!!Two or more races,
  mungeACS("percent")
acs2 <-
  c("NAME",
    "DP05_0071PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Hispanic or Latino (of any race),
    "DP05_0077PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!White alone,
    "DP05_0078PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Black or African American alone,
    "DP05_0079PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!American Indian and Alaska Native alone,
    "DP05_0080PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Asian alone,
    "DP05_0081PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Native Hawaiian and Other Pacific Islander alone,
    "DP05_0082PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Some other race alone,
    "DP05_0083PE") %>%  # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Two or more races,  
  mungeACS("percent")
acs3 <-
  c("NAME",
    "DP05_0071PE",      # HISPANIC OR LATINO AND RACE!!Total population!!Hispanic or Latino (of any race),
    "DP05_0076PE") %>%  # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino,
  mungeACS("percent")
acs4 <-
  c("NAME",
    "DP05_0037E",      # RACE!!Total population!!One race!!White,
    "DP05_0038E",      # RACE!!Total population!!One race!!Black or African American,
    "DP05_0039E",      # RACE!!Total population!!One race!!American Indian and Alaska Native,
    "DP05_0044E",      # RACE!!Total population!!One race!!Asian,
    "DP05_0052E",      # RACE!!Total population!!One race!!Native Hawaiian and Other Pacific Islander,
    "DP05_0057E",      # RACE!!Total population!!One race!!Some other race,
    "DP05_0058E") %>%  # RACE!!Total population!!Two or more races,
  mungeACS("count")
acs5 <-
  c("NAME",
    "DP05_0071E",      # HISPANIC OR LATINO AND RACE!!Total population!!Hispanic or Latino (of any race),
    "DP05_0077E",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!White alone,
    "DP05_0078E",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Black or African American alone,
    "DP05_0079E",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!American Indian and Alaska Native alone,
    "DP05_0080E",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Asian alone,
    "DP05_0081E",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Native Hawaiian and Other Pacific Islander alone,
    "DP05_0082E",      # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Some other race alone,
    "DP05_0083E") %>%  # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino!!Two or more races,  
  mungeACS("count")
acs6 <-
  c("NAME",
    "DP05_0071E",      # HISPANIC OR LATINO AND RACE!!Total population!!Hispanic or Latino (of any race),
    "DP05_0076E") %>%  # HISPANIC OR LATINO AND RACE!!Total population!!Not Hispanic or Latino,
  mungeACS("count")
checkACS <- function (data, tol = 1/4) {
  require(magrittr)
  require(dplyr)
  data %>%
    group_by(State_Name) %>%
    summarize(total = sum(percent)) %>%
    mutate(error = abs(total - 100) > tol) %>%
    pull(error)
}
if (any(c(acs1 %>% checkACS(), acs2 %>% checkACS(), acs3 %>% checkACS()))) {
  warning("Something went screwy with the ACS munging!")
  stop()
}
bindACS <- function(data1, data2, data3) {
  require(magrittr)
  require(dplyr)
  bind_rows(data1 %>%
              filter(!(State_Name %in% lookup)),
            data2 %>%
              filter(State_Name %in% lookup) %>%
              mutate(label = gsub("Not Hispanic or Latino!!", "", label) %>%
                             gsub("\\salone", "", .)),
            data3) %>%
    unique()
}
acs <-
  inner_join(bindACS(acs1, acs2, acs3),
             bindACS(acs4, acs5, acs6)) %>%
  arrange(State_Name)
  

# For states that report Hispanic or Latino as a race category, add the
# ACS Hispanic or Latino ethnicity data with the "Hispanic or Latino"
# label, so the left_join() can join it
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


recodeToNA <- function (var, check) {
  case_when(is.na(check) ~ NA_character_,
            TRUE ~ var)
}

df <-
  acs %>%
  select(State_Name, percent, count, label) %>%
  rename(percent_ACS = percent,
         count_ACS = count,
         category = label) %>%
  mutate(percent_ACS = pmax(percent_ACS, 0.05)) %>%
  mutate(percent_ACS = percent_ACS / 100) %>%
  left_join(crdt, .) %>%
  left_join(reporting_characteristics) %>%
  left_join(oregon_categories) %>%
  mutate(per_capita_denom = 1e5) %>%
  mutate(per_capita_rate = (count / count_ACS) * per_capita_denom) %>%
  mutate(disparity_factor = percent / percent_ACS,
         disparity_excess_pct = (percent - percent_ACS) / percent_ACS) %>%
  group_by(metric, category) %>%
  mutate(disparity_rank = rank(-disparity_factor),
         denom_ranked = sum(is.finite(disparity_factor))) %>%
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
                                    category == "Not Hispanic or Latino" ~ "Non-Hispanic or Latinos",
                                    category == "Some other race" ~ "Individuals of some other race",
                                    category == "Two or more races" ~ "Multiracial individuals",
                                    TRUE ~ sprintf("%ss", category))) %>%
  mutate(category_text3 = case_when(category == "Hispanic or Latino (of any race)" ~ "Hispanic or Latinos (of any race)",
                                    category == "Not Hispanic or Latino" ~ "non-Hispanic or Latinos",
                                    category == "Some other race" ~ "individuals of some other race",
                                    category == "Two or more races" ~ "multiracial individuals",
                                    TRUE ~ sprintf("%ss", category))) %>%
  mutate(tooltip_text1 = sprintf("%s disparity criteria.",
                                 case_when( disparity_flag ~ "* Meets",
                                           !disparity_flag ~ "Does not meet",
                                           is.na(disparity_flag) ~ "No comparable census data to evaulate")),
         tooltip_text2 = sprintf("of COVID-19 %s in %s are %s.",
                                 tolower(metric),
                                 fixState(State_Name, isStartOfSentence = FALSE),
                                 category_text1),
         tooltip_text3a = sprintf("%s",
                                  case_when(percent_ACS * 100 < 0.5 ~ "Less than half of 1%",
                                            TRUE ~ sprintf("%.1f%%", percent_ACS * 100))),
         tooltip_text3b = sprintf("of the population in %s are %s.", fixState(State_Name, isStartOfSentence = FALSE), category_text1),
         tooltip_text4a = sprintf("%s comprise", category_text2),
         tooltip_text4b = sprintf("%.1f times", disparity_factor),
         tooltip_text4c = sprintf("the number of %s than expected with a rate of", tolower(metric)),
         tooltip_text4d = sprintf("%s per %s", comma(per_capita_rate, accuracy = 1), comma(per_capita_denom, accuracy = 1)),
         tooltip_text4e = sprintf("in %s.", fixState(State_Name, isStartOfSentence = FALSE)),
         tooltip_text5a = sprintf("%s is ranked", fixState(State_Name)),
         tooltip_text5b = sprintf("%.0f%s",
                                  disparity_rank,
                                  case_when(grepl("(^|[2-9])1$", sprintf("%.0f", disparity_rank)) ~ "st",
                                            grepl("(^|[2-9])2$", sprintf("%.0f", disparity_rank)) ~ "nd",
                                            grepl("(^|[2-9])3$", sprintf("%.0f", disparity_rank)) ~ "rd",
                                            TRUE ~ "th")),
         tooltip_text5c = sprintf("for disparity among %s out of %.0f states and territories reporting %s for this category and with a non-zero percentage in their population.",
                                  category_text3,
                                  denom_ranked,
                                  tolower(metric))) %>%
  mutate(tooltip_text1 = recodeToNA(tooltip_text1, percent),
         tooltip_text2 = recodeToNA(tooltip_text2, percent),
         tooltip_text3a = recodeToNA(tooltip_text3a, percent),
         tooltip_text3b = recodeToNA(tooltip_text3b, percent),
         tooltip_text4a = recodeToNA(tooltip_text4a, percent),
         tooltip_text4b = recodeToNA(tooltip_text4b, percent),
         tooltip_text4c = recodeToNA(tooltip_text4c, percent),
         tooltip_text4d = recodeToNA(tooltip_text4d, percent),
         tooltip_text4e = recodeToNA(tooltip_text4e, percent),
         tooltip_text5a = recodeToNA(tooltip_text5a, percent),
         tooltip_text5b = recodeToNA(tooltip_text5b, percent),
         tooltip_text5c = recodeToNA(tooltip_text5c, percent)) %>%
  mutate(tooltip_text9 = case_when(category == "Hispanic or Latino" & category_reporting_flag ~ "Oregon reports Hispanic or Latino data as ethnicity, not race. Switch to \"ethnicity\" view for direct comparison.")) %>%
  mutate(tooltip_text4a = case_when(is.na(percent) ~ sprintf("%s does not have data on COVID-19 %s for %s.",
                                                             fixState(State_Name),
                                                             tolower(metric),
                                                             category_text3),
                                    is.na(percent_ACS) ~ sprintf("%s does not have Census data for %s.",
                                                                 fixState(State_Name),
                                                                 category_text3),
                                    TRUE ~ tooltip_text4a)) %>%
  rename(category_title_text = category_text2,
         category_insentence_text = category_text3) %>%
  select(-starts_with("category_text")) %>%
  mutate(timestamp = Sys.time()) %>%
  filter(!(State_Name %in% c("American Samoa",
                             "Northern Mariana Islands")))


# Calculate rate differences and rate ratios
# Use White as reference category for race
# Use as reference category for ethnicity
temp <- df %>% select(State, metric, variable, category, per_capita_rate)
rate_diff_rate_ratio <-
  inner_join(temp,
             temp %>% filter(category %in% c("White", "Not Hispanic or Latino")),
             by = c("State", "metric", "variable"),
             suffix = c("", "_ref")) %>%
  mutate(rate_diff = per_capita_rate - per_capita_rate_ref,
         rate_ratio = per_capita_rate / per_capita_rate_ref) %>%
  select(State, metric, variable, category, per_capita_rate, per_capita_rate_ref, rate_diff, rate_ratio, category_ref)
df <-
  df %>%
  inner_join(rate_diff_rate_ratio) %>%
  mutate(category_ref_text = case_when(category_ref == "Not Hispanic or Latino" ~ "Non-Hispanic or Latinos",
                                       TRUE ~ sprintf("%ss", category_ref))) %>%
  mutate(category_text3 = case_when(category == "Hispanic or Latino (of any race)" ~ "Hispanic or Latinos (of any race)",
                                    category == "Not Hispanic or Latino" ~ "non-Hispanic or Latinos",
                                    category == "Some other race" ~ "individuals of some other race",
                                    category == "Two or more races" ~ "multiracial individuals",
                                    TRUE ~ sprintf("%ss", category))) %>%
  mutate(tooltip_text6a = sprintf("%s have", category_title_text),
         tooltip_text6b = sprintf("%.1f times", rate_ratio),
         tooltip_text6c = sprintf("the %s compared to %s in %s.", tolower(metric), category_ref_text, fixState(State_Name, isStartOfSentence = FALSE)),
         tooltip_text7a = sprintf("%s %s", comma(per_capita_rate, accuracy = 1), tolower(metric)),
         tooltip_text7b = sprintf("per %s %s versus", comma(per_capita_denom, accuracy = 1), category_insentence_text),
         tooltip_text7c = sprintf("%s %s", comma(per_capita_rate_ref, accuracy = 1), tolower(metric)),
         tooltip_text7d = sprintf("per %s %s.", comma(per_capita_denom, accuracy = 1), category_ref_text)) %>%
  mutate(tooltip_text6a = recodeToNA(tooltip_text6a, rate_ratio),
         tooltip_text6b = recodeToNA(tooltip_text6b, rate_ratio),
         tooltip_text6c = recodeToNA(tooltip_text6c, rate_ratio),
         tooltip_text7a = recodeToNA(tooltip_text7a, rate_ratio),
         tooltip_text7b = recodeToNA(tooltip_text7b, rate_ratio),
         tooltip_text7c = recodeToNA(tooltip_text7c, rate_ratio),
         tooltip_text7d = recodeToNA(tooltip_text7d, rate_ratio)) %>%
  mutate(tooltip_text6a = case_when(is.na(rate_ratio) ~ sprintf("%s does not have data on COVID-19 %s for %s.",
                                                                fixState(State_Name),
                                                                tolower(metric),
                                                                category_text3),
                                    TRUE ~ tooltip_text6a)) %>%
  select(-c(category_ref_text, category_insentence_text, category_text3))


#  Calculate disparity indices
disparity_indices <-
  df %>%
  filter(!is.na(percent) & !is.na(percent_ACS)) %>%
  filter(percent > 0 & percent_ACS > 0) %>%
  group_by(Date, State, State_Name, metric, variable) %>%
  summarize(between_group_variance = sum(percent_ACS * (percent - percent_ACS) ^ 2),
            theil_index = theil.wtd(percent, weights = NULL),
            mean_log_deviation = mld.wtd(percent, weights = NULL),
            chisq = sum(((count - sum(count) * percent_ACS) ^ 2) / (sum(count) * percent_ACS)),
            df = n() - 1) %>%
  ungroup() %>%
  mutate(chisq_pvalue = pchisq(chisq, df, lower.tail = FALSE)) %>%
  pivot_longer(-c(Date, State, State_Name, metric, variable)) %>%
  mutate(index_type = case_when(name == "between_group_variance" ~ "Absolute",
                                name == "theil_index" ~ "Relative",
                                name == "mean_log_deviation" ~ "Relative",
                                name == "chisq" ~ "Absolute",
                                name == "chisq_pvalue" ~ "Absolute"),
         index = case_when(name == "between_group_variance" ~ "Between Group Variance",
                           name == "theil_index" ~ "Theil Index",
                           name == "mean_log_deviation" ~ "Mean Log Deviation",
                           name == "chisq" ~ "Chi-square statistic",
                           name == "chisq_pvalue" ~ "Chi-square p-value"),
         value = case_when(name == "between_group_variance" ~ value,
                           name == "theil_index" ~ value * 1000,
                           name == "mean_log_deviation" ~ value * 1000,
                           name == "chisq" ~ value,
                           name == "chisq_pvalue" ~ value)) %>%
  select(-name) %>%
  group_by(Date, metric, variable, index_type, index) %>%
  mutate(value_scaled = case_when(index == "Chi-square statistic" ~ value,
                                  index == "Chi-square p-value" ~ value,
                                  TRUE ~ value / sd(value))) %>%
  ungroup() %>%
  mutate(tooltip = sprintf("%s's %s for %s disparity in %s rates is %.1f",
                           fixState(State_Name),
                           case_when(index == "Between Group Variance" ~ "between group variance (BGV)",
                                     index == "Theil Index" ~ "Theil Index (TI)",
                                     index == "Mean Log Deviation" ~ "mean log deviation (MLD)",
                                     index == "Chi-square statistic" ~ "chi-square statistic",
                                     index == "Chi-square p-value" ~ "chi-square p-value"),
                           case_when(variable == "Race" ~ "racial",
                                     variable == "Ethnicity" ~ "ethnic"),
                           case_when(metric == "Cases" ~ "case",
                                     metric == "Deaths" ~ "death"),
                           value_scaled)) %>%
  mutate(timestamp = Sys.time())


# Export for Tableau
df <- df %>% select(-c(Date, timestamp))

f <- file.path("Data", "disparity_data.csv")
df %>% write_csv(f, na = "")

f <- file.path("Data", "disparity_factor_range.csv")
df %>%
  summarize(min = min(disparity_factor, na.rm = TRUE),
            median = median(disparity_factor, na.rm = TRUE),
            p90 = quantile(disparity_factor, probs = 0.90, na.rm = TRUE),
            p95 = quantile(disparity_factor, probs = 0.95, na.rm = TRUE),
            p99 = quantile(disparity_factor, probs = 0.99, na.rm = TRUE),
            p995 = quantile(disparity_factor, probs = 0.995, na.rm = TRUE),
            max = max(disparity_factor, na.rm = TRUE)) %>%
  pivot_longer(everything()) %>%
  write_csv(f, na = "")

f <- file.path("Data", "rate_ratio_range.csv")
df %>%
  summarize(min = min(rate_ratio, na.rm = TRUE),
            median = median(rate_ratio, na.rm = TRUE),
            p90 = quantile(rate_ratio, probs = 0.90, na.rm = TRUE),
            p95 = quantile(rate_ratio, probs = 0.95, na.rm = TRUE),
            p99 = quantile(rate_ratio, probs = 0.99, na.rm = TRUE),
            p995 = quantile(rate_ratio, probs = 0.995, na.rm = TRUE),
            max = max(rate_ratio, na.rm = TRUE)) %>%
  pivot_longer(everything()) %>%
  write_csv(f, na = "")

f <- file.path("Data", "per_capita_rate_range.csv")
df %>%
  summarize(min = min(per_capita_rate, na.rm = TRUE),
            median = median(per_capita_rate, na.rm = TRUE),
            p90 = quantile(per_capita_rate, probs = 0.90, na.rm = TRUE),
            p95 = quantile(per_capita_rate, probs = 0.95, na.rm = TRUE),
            p99 = quantile(per_capita_rate, probs = 0.99, na.rm = TRUE),
            p995 = quantile(per_capita_rate, probs = 0.995, na.rm = TRUE),
            max = max(per_capita_rate, na.rm = TRUE)) %>%
  pivot_longer(everything()) %>%
  write_csv(f, na = "")

f <- file.path("Data", "disparity_indices.csv")
disparity_indices %>% write_csv(f, na = "")

f <- file.path("Data", "disparity_indices_summaries.csv")
disparity_indices %>%
  group_by(metric, variable, index) %>%
  summarize(mean = mean(value_scaled),
            sd = sd(value_scaled),
            min = min(value_scaled),
            max = max(value_scaled)) %>%
  write_csv(f, na = "")

f <- file.path("Data", "control_totals.csv")
totals %>%
  group_by(Date, timestamp) %>%
  summarize(Cases_Total = sum(Cases_Total, na.rm = TRUE),
            Deaths_Total = sum(Deaths_Total, na.rm = TRUE)) %>%
  write_csv(f, na = "")

f <- file.path("Data", "chiSquareExample.csv")
df %>%
  filter(!is.na(percent) & !is.na(percent_ACS)) %>%
  filter(percent > 0 & percent_ACS > 0) %>%
  filter(State == "OR") %>%
  filter(metric == "Cases") %>%
  filter(variable == "Race") %>%
  select(Date, State, State_Name, metric, variable, category, percent, percent_ACS, count) %>%
  mutate(category = case_when(category == "White" ~ "White or some other race",
                              category == "Some other race" ~ "White or some other race",
                              TRUE ~ category)) %>%
  group_by(Date, State, State_Name, metric, variable, category) %>%
  summarize(percent = sum(percent),
            percent_ACS = sum(percent_ACS),
            count = sum(count)) %>%
  ungroup() %>%
  mutate(count_ACS = sum(count) * percent_ACS) %>%
  mutate(sqDevPct = (percent - percent_ACS) ^ 2) %>%
  mutate(SSPctProp = sqDevPct / sum(sqDevPct)) %>%
  mutate(sqDevCount = (count - count_ACS) ^ 2 / count_ACS) %>%
  mutate(SSCountProp = sqDevCount / sum(sqDevCount)) %>%
  write_csv(f, na = "")
