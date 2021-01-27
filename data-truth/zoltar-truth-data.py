import json
from truth_utils._utils import get_epi_data, get_epi_data_TZ, get_available_timezeros, pre_process_truth, pre_process_epiweek, get_raw_truth_df, extract_raw_us_and_state_truth
import pandas as pd
import datetime
import warnings
warnings.simplefilter(action='ignore')


def configure_JHU_data(df, target):
    df_truth = pre_process_truth(df)

    # rename columns
    df_truth = df_truth.rename(columns={0: "value",
                                        "level_1": "location_long"})

    # Get state IDs
    df_truth = df_truth.merge(fips_codes, left_on='location_long', right_on='location_name', how='left')

    # Drop duplicate column
    df_truth = df_truth.drop(['location_name'], axis=1)

    # Drop NAs
    df_truth = df_truth.dropna(subset=['location', 'value'])

    # add leading zeros to state code
    df_truth['location'] = df_truth['location'].apply(lambda x: '{0:0>2}'.format(x))

    # Pre-process epiweek
    df_vis = pre_process_epiweek(df_truth, target, for_zoltar = True)

    # rename columns
    df_truth_long = df_vis.rename(columns={"week": "epiweek",
                                           "location": "unit",
                                           "level_0": "date"})
    # get timezero
    df_truth_long['date'] = pd.to_datetime(df_truth_long['date'])

    # initialize df_targets
    df_targets = pd.DataFrame(columns=list(df_truth_long.columns).append('target'))

    # use Saturday truth values
    df_truth_values = df_truth_long[df_truth_long['day'] == 7]

    # find week-ahead targets
    for i in range(20):
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
    df_targets = df_targets[["tz_year","tz_week", "unit", "target", "value"]]

    # Map all timezeros in Zoltar to Corresponding weeks
    df_map_wk_to_tz = pd.DataFrame(columns=['timezero'])
    df_map_wk_to_tz['timezero'] = get_available_timezeros("COVID-19 Forecasts")
    df_map_wk_to_tz['timezero'] = df_map_wk_to_tz['timezero'].astype(str)
    df_map_wk_to_tz['tz_year'], df_map_wk_to_tz['tz_week'], df_map_wk_to_tz['tz_day'] = \
        zip(*df_map_wk_to_tz['timezero'].map(get_epi_data_TZ))

    # Merge timezeros with truth values and targets
    df_final = pd.merge(df_targets, df_map_wk_to_tz, how='right', on=['tz_week', 'tz_year'])

    # select columns
    df_final = df_final[["timezero", "unit", "target", "value"]]

    # drop empty rows
    nan_value = float("NaN")
    df_final.replace("", nan_value, inplace=True)
    df_final.dropna(inplace=True)
    return df_final


url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
df = get_raw_truth_df(url)

fips_codes = pd.read_csv('../data-locations/locations.csv')
fips_codes = fips_codes[fips_codes.location != '11001']

# Extraction of cumulative and incident truths for national and state level
df_truth_cumulative, df_truth_incident = extract_raw_us_and_state_truth(df, for_zoltar = True)

# re-format files
df_cum_death = configure_JHU_data(df_truth_cumulative, "Cumulative Deaths")
df_inc_death = configure_JHU_data(df_truth_incident, "Incident Deaths")

# concatenate targers
zoltar_truth = pd.concat([df_cum_death, df_inc_death])

# write truth to csv
file_path = './zoltar-truth.csv'
zoltar_truth.to_csv(file_path, index=False)
