import pandas as pd
import pymmwr as pm
import datetime
import warnings
import io
import requests
warnings.simplefilter(action='ignore')

def read_fips_codes(filepath):
  # read file
  fips_codes = pd.read_csv(filepath)
  # take state code from all fips codes
  fips_codes['state_abbr'] = fips_codes['location'].str[:2]

  # match state abbrevaition with state fips code
  fips_codes['state_abbr'] = fips_codes['state_abbr'].apply(lambda x: fips_codes[fips_codes.location ==x].abbreviation.tolist()[0] if str(x) in fips_codes['location'].tolist() else 'NA')
  
  # only output "location (fips code)","location_name","(state) abbreviation"
  fips_codes = fips_codes.drop('abbreviation',axis=1)
  fips_codes.rename({'state_abbr': 'abbreviation'}, axis=1, inplace=True)
  # took out DC county
  fips_codes = fips_codes[fips_codes.location != '11001']
  return fips_codes

def get_epi_data(date):
    # The format
    format_str = '%m/%d/%y' 
    dt = datetime.datetime.strptime(date, format_str).date()
    epi = pm.date_to_epiweek(dt)
    return epi.year, epi.week, epi.day

def pre_process (df):
  # convert matrix to repeating row format
  df_truth = df.unstack()
  df_truth = df_truth.reset_index()
  
  # get epi data from date
  df_truth['year'], df_truth['week'], df_truth['day'] = \
  zip(*df_truth['level_0'].map(get_epi_data))
  return df_truth

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
    county_truth = pre_process(county_truth)
    state_nat_truth = pre_process(state_nat_truth)

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
              'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia']

    state_nat_truth = state_nat_truth.drop(['location_name'], axis=1)
    state_nat_truth = state_nat_truth[state_nat_truth["location_long"].isin(states)]
    df_truth = state_nat_truth

    
    # Observed data on the seventh day
    # or group by week for incident deaths
    if target in ('Incident Deaths','Incident Cases'):
        df_vis = df_truth.groupby(['week', 'location_long'], as_index=False).agg({'level_0': 'last',
                                                                                  'value': 'sum',
                                                                                  'year': 'last',
                                                                                  'day': 'last',
                                                                                  'location': 'last',
                                                                                  'abbreviation': 'last'})
                                                                                  
        df_vis = df_vis[df_vis['day'] == 7]
    else:
        df_vis = df_truth[df_truth['day'] == 7]


    # shift epiweek on axis
    df_vis['week'] = df_vis['week'] + 1  

    # add leading zeros to epi week
    df_vis['week'] = df_vis['week'].apply(lambda x: '{0:0>2}'.format(x))

    # define epiweek
    df_vis['epiweek'] = df_vis['year'].astype(str) + df_vis['week']

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

def get_county_truth(df):
  county = df[pd.notnull(df.FIPS)]
  county = county[(county.FIPS >=100) & (county.FIPS <80001)]
  county.FIPS = (county.FIPS.astype(int)).map("{:05d}".format)
  county_agg = county.groupby(['FIPS']).sum()
  return county_agg


def get_truth(url):
  url_req = requests.get(url).content
  df = pd.read_csv(io.StringIO(url_req.decode('utf-8')))

  # aggregate by state and nationally
  state_agg = df.groupby(['Province_State']).sum()
  us_nat = df.groupby(['Country_Region']).sum()
  county_agg = get_county_truth(df)
  df_state_nat = state_agg.append(us_nat)

  # drop unnecessary columns
  df_state_nat_truth = df_state_nat.drop(df_state_nat.columns[list(range(0, 6))], axis=1)
  df_county_truth = county_agg.drop(county_agg.columns[list(range(0, 5))], axis=1)

  df_state_nat_truth_cumulative = df_state_nat_truth
  df_county_truth_cumulative = df_county_truth

  df_state_nat_truth_incident = df_state_nat_truth_cumulative - df_state_nat_truth_cumulative.shift(periods=1, axis='columns')
  df_county_truth_incident = df_county_truth_cumulative-df_county_truth_cumulative.shift(periods=1, axis='columns')


  return df_state_nat_truth_cumulative,df_state_nat_truth_incident,df_county_truth_cumulative,df_county_truth_incident

fips_codes = read_fips_codes('../data-locations/locations.csv')

state_nat_cum_death, state_nat_inc_death,county_cum_death,county_inc_death = get_truth(url="https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")

state_nat_cum_case, state_nat_inc_case,county_cum_case,county_inc_case = get_truth(url="https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv")

configure_JHU_data(county_truth = county_cum_death, state_nat_truth = state_nat_cum_death, target = "Cumulative Deaths")
configure_JHU_data(county_truth= county_inc_death, state_nat_truth = state_nat_inc_death, target = "Incident Deaths")

configure_JHU_data(county_truth = county_cum_case, state_nat_truth = state_nat_cum_case, target = "Cumulative Cases")
configure_JHU_data(county_truth= county_inc_case, state_nat_truth = state_nat_inc_case, target = "Incident Cases")