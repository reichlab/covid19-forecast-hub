from truth_utils._utils import get_epi_data, read_fips_codes, pre_process_truth, pre_process_epiweek, get_raw_truth_df, extract_raw_us_and_state_truth, extract_raw_county_truth
import pandas as pd
import datetime
import warnings
warnings.simplefilter(action='ignore')


def get_byday (df_truth):
  # only output "location", "epiweek", "value"
  df_truth = df_truth.drop(['location_long'], axis=1)
  df_byday = df_truth.rename(columns={"level_0": "date"})
  
  # select columns
  df_byday = df_byday[["date", "location", "location_name", "value"]]
  
  # ensure value column is integer
  df_byday['value'] = df_byday['value'].astype(int)
  
  # change to yyyy/mm/dd format
  df_byday['date'] = pd.to_datetime(df_byday['date'])
  return df_byday

def configure_JHU_data(county_truth, state_nat_truth, target):
    # pre process both county truth and state_nat_truth
    county_truth = pre_process_truth(county_truth)
    state_nat_truth = pre_process_truth(state_nat_truth)

    # rename columns
    county_truth = county_truth.rename(columns={0: "value","FIPS": "location_long"})
    state_nat_truth = state_nat_truth.rename(columns={0: "value","level_1": "location_long"})

    # Get state IDs
    county_truth = county_truth.merge(fips_codes, left_on='location_long', right_on='location', how='left')
    state_nat_truth = state_nat_truth.merge(fips_codes, left_on='location_long', right_on='location_name', how='left')

    # Only keeps counties in the US 
    county_truth = county_truth[county_truth.location.notnull()]

    # Drop NAs
    county_truth = county_truth.dropna(subset=['location', 'value'])
    state_nat_truth = state_nat_truth.dropna(subset=['location', 'value'])

    # add leading zeros to state code
    state_nat_truth['location'] = state_nat_truth['location'].apply(lambda x: '{0:0>2}'.format(x))
    county_truth['location'] = county_truth['location'].apply(lambda x: '{0:0>2}'.format(x)) 
    '''
    ####################################
    # Daily truth data output for reference
    ####################################
    '''
    county_truth_byday = get_byday(county_truth)
    state_nat_truth_byday = get_byday(state_nat_truth)
    df_byday = state_nat_truth_byday.append(county_truth_byday)

    file_path = '../data-truth/truth-' + target + '.csv'
    df_byday.to_csv(file_path, index=False)

    '''
    ####################################
    # Truth data output for visualization
    ####################################
    '''
    # Only visualize certain states, not county truths
    states = ['US', 'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
              'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
              'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
              'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
              'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
              'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
              'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia', 'Puerto Rico', 'Guam', 'Virgin Islands',
              'Northern Mariana Islands', 'American Samoa']

    state_nat_truth = state_nat_truth.drop(['location_name'], axis=1)
    state_nat_truth = state_nat_truth[state_nat_truth["location_long"].isin(states)]
    df_truth = state_nat_truth

    
    # Pre-process epiweek
    df_vis = pre_process_epiweek(df_truth, target, for_zoltar = False)

    # Replace US with "nat" this is NECESSARY for visualization code!
    df_vis.loc[df_vis["location_long"] == "US", "abbreviation"] = "nat"

    # only output "location", "epiweek", "value"
    df_truth_short = df_vis[["abbreviation", "epiweek", "value"]]
    df_truth_short = df_truth_short.rename(columns={"abbreviation": "location"})

    df_truth_short["value"].replace({0: 0.1}, inplace=True)

    file_path = '../visualization/vis-master/covid-csv-tools/dist/truth/' + target + '.json'
    # write to json
    with open(file_path, 'w') as f:
        f.write(df_truth_short.to_json(orient='records'))


def get_truth(url):
  df = get_raw_truth_df(url)

  # Extraction of cumulative and incident truths for national and state level
  df_state_nat_truth_cumulative, df_state_nat_truth_incident = extract_raw_us_and_state_truth(df, for_zoltar = False)

  # Extraction of cumulative and incident truths for counties level
  df_county_truth_cumulative, df_county_truth_incident = extract_raw_county_truth(df, for_zoltar = False)

  return df_state_nat_truth_cumulative,df_state_nat_truth_incident,df_county_truth_cumulative,df_county_truth_incident

fips_codes = read_fips_codes('../data-locations/locations.csv')

state_nat_cum_death, state_nat_inc_death,county_cum_death,county_inc_death = get_truth(url="https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")

state_nat_cum_case, state_nat_inc_case,county_cum_case,county_inc_case = get_truth(url="https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv")

configure_JHU_data(county_truth = county_cum_death, state_nat_truth = state_nat_cum_death, target = "Cumulative Deaths")
configure_JHU_data(county_truth= county_inc_death, state_nat_truth = state_nat_inc_death, target = "Incident Deaths")

configure_JHU_data(county_truth = county_cum_case, state_nat_truth = state_nat_cum_case, target = "Cumulative Cases")
configure_JHU_data(county_truth= county_inc_case, state_nat_truth = state_nat_inc_case, target = "Incident Cases")