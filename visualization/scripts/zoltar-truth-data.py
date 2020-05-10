import json
from zoltpy import util
import pandas as pd
import pymmwr as pm
import datetime
import warnings
import requests
import io
warnings.simplefilter(action='ignore')


def get_epi_data(date):
    format_str = '%m/%d/%y'  # The format
    dt = datetime.datetime.strptime(date, format_str).date()
    epi = pm.date_to_epiweek(dt)
    return epi.year, epi.week, epi.day


def get_epi_data_TZ(date):
    format_str = '%Y-%m-%d'  # The format
    dt = datetime.datetime.strptime(date, format_str).date()
    epi = pm.date_to_epiweek(dt)
    epi_week = epi.week
    epi_day = epi.day
    if epi_day >= 3:  # cut off is Tuesday
        epi_week = epi_week + 1
    return epi.year, epi_week, epi.day


def get_available_timezeros(project_name):
    conn = util.authenticate()
    project = [project for project in conn.projects if project.name == project_name][0]
    project_timezeros = project.timezeros
    timezero = []
    for timezero_array in project_timezeros:
        timezero += [timezero_array.timezero_date]
    return timezero


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
    else:
        df_vis = df_truth
    df_vis['week'] = df_vis['week'] + 1  # shift epiweek on axis

    # add leading zeros to epi week
    df_vis['week'] = df_vis['week'].apply(lambda x: '{0:0>2}'.format(x))

    # define epiweek
    df_vis['epiweek'] = df_vis['year'].astype(str) + df_vis['week']

    # rename columns
    df_truth_long = df_vis.rename(columns={"state": "location",
                                           "week": "epiweek",
                                           "state_code": "unit",
                                           "level_0": "date"})
    # get timezero
    df_truth_long['date'] = pd.to_datetime(df_truth_long['date'])

    # initialize df_targets
    df_targets = pd.DataFrame(columns=list(df_truth_long.columns).append('target'))

    # use Saturday truth values
    df_truth_values = df_truth_long[df_truth_long['day'] == 7]

    # find week-ahead targets
    for i in range(4):
        weeks_ahead = i + 1  # add one to [0,3]
        days_back = 5 + ((weeks_ahead - 1) * 7)  # timezero is on Mondays

        df_calc = df_truth_values  # initialize df

        # find timezero and target
        df_calc['timezero'] = df_calc['date'] - datetime.timedelta(days=days_back)
        if target == "Cumulative Deaths":
            df_calc['target'] = "%i wk ahead cum death" % weeks_ahead
        else:
            df_calc['target'] = "%i wk ahead inc death" % weeks_ahead
        # concatenate truth
        df_targets = pd.concat([df_targets, df_calc])

    # get epi data from Timezero
    df_targets['timezero'] = df_targets['timezero'].astype(str)
    df_targets['tz_year'], df_targets['tz_week'], df_targets['tz_day'] = \
        zip(*df_targets['timezero'].map(get_epi_data_TZ))

    # truth targets by timezero week
    df_targets = df_targets[["tz_week", "unit", "target", "value"]]

    # Map all timezeros in Zoltar to Corresponding weeks
    df_map_wk_to_tz = pd.DataFrame(columns=['timezero'])
    df_map_wk_to_tz['timezero'] = get_available_timezeros("COVID-19 Forecasts")
    df_map_wk_to_tz['tz_year'], df_map_wk_to_tz['tz_week'], df_map_wk_to_tz['tz_day'] = \
        zip(*df_map_wk_to_tz['timezero'].map(get_epi_data_TZ))

    # Merge timezeros with truth values and targets
    df_final = pd.merge(df_targets, df_map_wk_to_tz, how='right', on=['tz_week'])

    # select columns
    df_final = df_final[["timezero", "unit", "target", "value"]]

    # drop empty rows
    nan_value = float("NaN")
    df_final.replace("", nan_value, inplace=True)
    df_final.dropna(inplace=True)
    return df_final


url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
url_req = requests.get(url).content
df = pd.read_csv(io.StringIO(url_req.decode('utf-8')))

fips_codes = pd.read_csv('../../template/state_fips_codes.csv')

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

# re-format files
df_cum_death = configure_JHU_data(df_truth_cumulative, "Cumulative Deaths")
df_inc_death = configure_JHU_data(df_truth_incident, "Incident Deaths")

# concatenate targers
zoltar_truth = pd.concat([df_cum_death, df_inc_death])

# write truth to csv
file_path = '../../data-truth/zoltar-truth.csv'
zoltar_truth.to_csv(file_path, index=False)
