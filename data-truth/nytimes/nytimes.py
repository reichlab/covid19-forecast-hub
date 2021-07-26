import pandas as pd
import os

# Global Constants
US_URL = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us.csv"
STATES_URL = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv"
COUNTIES_URL = "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"
RELATIVE_PATH = "data-truth/nytimes"

# Download raw data
us = pd.read_csv(US_URL, dtype={'cases': int, 'deaths': int}).fillna(value = 'NA')
us['date'] = pd.to_datetime(us['date'])
us.to_csv(os.path.join(RELATIVE_PATH,"raw/us.csv"), index = False)

states = pd.read_csv(STATES_URL, dtype={'fips': str, 'cases': int, 'deaths': int}).fillna(value = 'NA')
states['date'] = pd.to_datetime(states['date'])
states.to_csv(os.path.join(RELATIVE_PATH,"raw/us-states.csv"), index = False)

counties = pd.read_csv(COUNTIES_URL, dtype={'fips': str}).dropna().astype(dtype={'fips': str, 'cases': int, 'deaths': int})
counties['date'] = pd.to_datetime(counties['date'])
counties.to_csv(os.path.join(RELATIVE_PATH,"raw/us-counties.csv"), index = False)

# Generate truth data for: cumulative deaths, cumulative cases, incident deaths, incident cases
us.insert(loc = 1, column = 'location', value = 'US')

states.drop(columns = 'state', inplace = True)
states.rename(columns = {'fips': 'location'}, inplace = True)

counties.drop(columns = ['county', 'state'], inplace = True)
counties.rename(columns = {'fips': 'location'}, inplace = True)

main_df = pd.concat([us, states, counties])
main_df = main_df.sort_values(['location','date'])

# Output truth cumulative
main_df.to_csv(os.path.join(RELATIVE_PATH,"truth_nytimes-Cumulative Cases.csv"), columns = ['date', 'location', 'cases'], header = ['date', 'location', 'value'], index = False)
main_df.to_csv(os.path.join(RELATIVE_PATH,"truth_nytimes-Cumulative Deaths.csv"), columns = ['date', 'location', 'deaths'], header = ['date', 'location', 'value'], index = False)

# Output truth incident
main_df = main_df.reset_index()
main_df['diff_cases'] = main_df.groupby(by = ['location'])['cases'].diff().fillna(main_df['cases'])
main_df = main_df.astype({'diff_cases': int})
main_df.to_csv(os.path.join(RELATIVE_PATH,"truth_nytimes-Incident Cases.csv"), columns = ['date', 'location', 'diff_cases'], header = ['date', 'location', 'value'], index = False)

main_df['diff_deaths'] = main_df.groupby(by = ['location'])['deaths'].diff().fillna(main_df['deaths'])
main_df = main_df.astype({'diff_deaths': int})
main_df.to_csv(os.path.join(RELATIVE_PATH,"truth_nytimes-Incident Deaths.csv"), columns = ['date', 'location', 'diff_deaths'], header = ['date', 'location', 'value'], index = False)