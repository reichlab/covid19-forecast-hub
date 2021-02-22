import pymmwr as pm
import datetime
import pandas as pd
from zoltpy import util
import requests
import io


'''
    Get the epidemiological year, week and date of a given date.
'''
def get_epi_data(date):
    # The format
    format_str = '%m/%d/%y' 
    dt = datetime.datetime.strptime(date, format_str).date()
    epi = pm.date_to_epiweek(dt)
    return epi.year, epi.week, epi.day


'''
    Get the epidemiological year, week and date of a given timezero date.
'''
def get_epi_data_TZ(date):
    format_str = '%Y-%m-%d'  # The format
    dt = datetime.datetime.strptime(date, format_str).date()
    epi = pm.date_to_epiweek(dt)
    epi_week = epi.week
    epi_day = epi.day
    if epi_day >= 3:  # cut off is Tuesday
        epi_week = epi_week + 1
    return epi.year, epi_week, epi.day


'''
    Get a dataframe of locations with information including fips code, state/county name, population, etc.
'''
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


'''
    Get a list of availabel timezeros on a zoltar project given the project's name.
    Default project_name: COVID-19 Forecasts
'''
def get_available_timezeros(project_name="COVID-19 Forecasts"):
    conn = util.authenticate()
    project = [project for project in conn.projects if project.name == project_name][0]
    project_timezeros = project.timezeros
    timezero = []
    for timezero_array in project_timezeros:
        timezero += [timezero_array.timezero_date]
    return timezero


'''
    Unstack the original truth dataframe and 
    get epidemilogical data from dates
'''
def pre_process_truth(df):
    # convert matrix to repeating row format
    df_truth = df.unstack()
    df_truth = df_truth.reset_index()

    # get epi data from date
    df_truth['year'], df_truth['week'], df_truth['day'] = \
    zip(*df_truth['level_0'].map(get_epi_data))
    
    return df_truth


'''
    Process the truth dataframe into compatible format for whether the 
    Github visualization or uploading to Zoltar
'''
def pre_process_epiweek(df_truth, target, for_zoltar):
    # Observed data on the seventh day
    # or group by week for incident deaths
    if target in ('Incident Deaths','Incident Cases'):
        df_vis = df_truth.groupby(['week', 'location_long'], as_index=False).agg({'level_0': 'last',
                                                                                  'value': 'sum',
                                                                                  'year': 'last',
                                                                                  'day': 'last',
                                                                                  'location': 'last',
                                                                                  'abbreviation': 'last'})
                                                                                  
        if not for_zoltar:
            df_vis = df_vis[df_vis['day'] == 7]
    else:
        if not for_zoltar:
            df_vis = df_truth[df_truth['day'] == 7]
        else:
            df_vis = df_truth

    # shift epiweek on axis
    
    df_vis['week'] = df_vis['week'] + 1  
    df_invalid = df_vis[df_vis['week'] > 53]
    # print(f"Number of invalid rows: {len(df_invalid.index)}")
    if len(df_invalid.index) > 0:
        df_vis.loc[df_vis['week'] > 53, 'year'] =df_vis[df_vis['week'] > 53]['year'] + 1
        df_vis.loc[df_vis['week'] > 53, 'week'] = 1
    # print(f"Number of invalid rows after operation: {len(df_vis[df_vis['week'] > 53].index)}")

    # add leading zeros to epi week
    df_vis['week'] = df_vis['week'].apply(lambda x: '{0:0>2}'.format(x))

    # define epiweek
    df_vis['epiweek'] = df_vis['year'].astype(str) + df_vis['week']
    
    return df_vis


'''
    Download raw truth csv from a given url and convert into pandas dataframe
'''
def get_raw_truth_df(url):
    url_req = requests.get(url).content
    df = pd.read_csv(io.StringIO(url_req.decode('utf-8')))
    return df


'''
    Extract a new raw dataframe that contains cumulative and incident truths
    of US and the states from a given raw dataframe
'''
def extract_raw_us_and_state_truth(df, for_zoltar):
    # aggregate by state and nationally
    state_agg = df.groupby(['Province_State']).sum()
    us_nat = df.groupby(['Country_Region']).sum()
    df_state_nat = state_agg.append(us_nat)

    # drop unnecessary columns
    cols = list(range(0, 6))
    df_truth = df_state_nat.drop(df_state_nat.columns[cols], axis=1)

    # calculate incidents from cumulative
    df_truth_cumulative = df_truth
    df_truth_incident = df_truth - df_truth.shift(periods=1, axis='columns')

    if not for_zoltar:
        # lower bound truth values to 0.0
        df_truth_incident = df_truth_incident.clip(lower=0.0)
    return df_truth_cumulative, df_truth_incident


'''
    Extract a new raw dataframe that contains cumulative and incident truths
    of counties from a given raw dataframe
'''
def extract_raw_county_truth(df, for_zoltar):
    # aggregate by county based onf fips code
    county = df[pd.notnull(df.FIPS)]
    county = county[(county.FIPS >=100) & (county.FIPS <80001)]
    county.FIPS = (county.FIPS.astype(int)).map("{:05d}".format)
    county_agg = county.groupby(['FIPS']).sum()

    # drop unnecessary columns
    df_county_truth = county_agg.drop(county_agg.columns[list(range(0, 5))], axis=1)

    # calculate incidents from cumulative
    df_county_truth_cumulative = df_county_truth
    df_county_truth_incident = df_county_truth_cumulative-df_county_truth_cumulative.shift(periods=1, axis='columns')

    if not for_zoltar:
        # lower bound truth values to 0.0
        df_county_truth_incident = df_county_truth_incident.clip(lower=0.0)

    return df_county_truth_cumulative, df_county_truth_incident