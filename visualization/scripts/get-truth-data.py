import pandas as pd
import pymmwr as pm
import datetime
import warnings
import io
import requests
warnings.simplefilter(action='ignore')


def get_epi_data(date):
    format_str = '%m/%d/%y'  # The format
    dt = datetime.datetime.strptime(date, format_str).date()
    epi = pm.date_to_epiweek(dt)
    return epi.year, epi.week, epi.day


def configure_JHU_data(df, target):
    # convert matrix to repeating row format
    df_truth = df.unstack()
    df_truth = df_truth.reset_index()

    # get epi data from date
    df_truth['year'], df_truth['week'], df_truth['day'] = \
        zip(*df_truth['level_0'].map(get_epi_data))

    # rename columns
    df_truth = df_truth.rename(columns={0: "value",
                                        "level_1": "location_long"})
    # Get state IDs
    df_truth = df_truth.merge(fips_codes, left_on='location_long', right_on='state_name', how='left')

    df_truth.loc[df_truth["location_long"] == "US", "state_code"] = "US"
    df_truth["state_code"].replace({"US": 1000}, inplace=True)  # so that can be converted to int

    # convert FIPS code to int
    df_truth = df_truth.dropna(subset=['state_code'])
    df_truth["state_code"] = df_truth["state_code"].astype(int)

    # add leading zeros to state code
    df_truth['state_code'] = df_truth['state_code'].apply(lambda x: '{0:0>2}'.format(x))

    # convert 1000 back to US
    df_truth["state_code"].replace({"1000": "US"}, inplace=True)
    df_truth.loc[df_truth["location_long"] == "US", "state"] = "nat"
    '''
    ####################################
    # Daily truth data output for reference
    ####################################
    '''

    # only output "location", "epiweek", "value"
    df_byday = df_truth.rename(columns={"level_0": "date", "state_code": "location", "location_long": "location_name"})
    # select columns
    df_byday = df_byday[["date", "location", "location_name", "value"]]

    # change to yyyy/mm/dd format
    df_byday['date'] = pd.to_datetime(df_byday['date'])

    file_path = '../data-truth/truth-' + target + '.csv'
    df_byday.to_csv(file_path, index=False)

    '''
    ####################################
    # Truth data output for visualization
    ####################################
    '''
    # Only visualize certain states
    states = ['US', 'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
              'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
              'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
              'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
              'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
              'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
              'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia']
    df_truth = df_truth[df_truth["location_long"].isin(states)]

    # Observed data on the seventh day
    # or group by week for incident deaths
    if target == 'Incident Deaths':
        df_vis = df_truth.groupby(['week', 'location_long'], as_index=False).agg({'level_0': 'last',
                                                                                  'value': 'sum',
                                                                                  'year': 'last',
                                                                                  'day': 'last',
                                                                                  'state_code': 'last',
                                                                                  'state': 'last',
                                                                                  'state_name': 'last'})
        df_vis = df_vis[df_vis['day'] == 7]
    else:
        df_vis = df_truth[df_truth['day'] == 7]

    df_vis['week'] = df_vis['week'] + 1  # shift epiweek on axis

    # add leading zeros to epi week
    df_vis['week'] = df_vis['week'].apply(lambda x: '{0:0>2}'.format(x))

    # define epiweek
    df_vis['epiweek'] = df_vis['year'].astype(str) + df_vis['week']

    # only output "location", "epiweek", "value"
    df_vis = df_vis.rename(columns={"state": "location"})
    df_truth_short = df_vis[["location", "epiweek", "value"]]

    df_truth_short["value"].replace({0: 0.1}, inplace=True)

    file_path = './vis-master/covid-csv-tools/dist/truth/' + target + '.json'
    # write to json
    with open(file_path, 'w') as f:
        f.write(df_truth_short.to_json(orient='records'))


url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
url_req = requests.get(url).content
df = pd.read_csv(io.StringIO(url_req.decode('utf-8')))

fips_codes = pd.read_csv('../template/state_fips_codes.csv')

# aggregate by state and nationally
state_agg = df.groupby(['Province_State']).sum()
us_nat = df.groupby(['Country_Region']).sum()
df_state_nat = state_agg.append(us_nat)

# drop unnecessary columns
cols = list(range(0, 6))
df_truth = df_state_nat.drop(df_state_nat.columns[cols], axis=1)

df_truth_cumulative = df_truth
df_truth_incident = df_truth - df_truth.shift(periods=1, axis='columns')

configure_JHU_data(df_truth_cumulative, "Cumulative Deaths")
configure_JHU_data(df_truth_incident, "Incident Deaths")
