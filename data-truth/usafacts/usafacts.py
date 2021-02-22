import pandas as pd
import os

def reformat_county_data(df):
    df.drop(columns = ['StateFIPS', 'County Name', 'State'], inplace = True)
    df.rename(columns = {'countyFIPS': 'location'}, inplace = True)

    # Drop row that is not county data
    df = df[df['location']>1000]

    # Format county fips code
    df = df.astype({'location': str})
    df['location'] = df['location'].apply(lambda x: x.zfill(5))

    # Pivot the data to have each row holding the value (cases/death) per location - date pair
    df = df.melt(id_vars = ['location'], var_name = 'date', value_name = 'value')
    df = df[['date', 'location', 'value']]

    # Format the date
    df['date'] = pd.to_datetime(df['date'])
    return df


def reformat_state_data(df):
    df.drop(columns = ['countyFIPS', 'County Name', 'State'], inplace = True)
    df.rename(columns = {'StateFIPS': 'location'}, inplace = True)

    # Format state fips code
    df = df.astype({'location': str})
    df['location'] = df['location'].apply(lambda x: x.zfill(2))

    # Pivot the data to have each row holding the value (cases/death) per location - date pair
    df = df.melt(id_vars = ['location'], var_name = 'date', value_name = 'value')
    df = df[['date', 'location', 'value']]
    
    # Format the date
    df['date'] = pd.to_datetime(df['date'])

    # Sum up all county data within the state to get the aggregated state data
    df = df.groupby(['date', 'location']).sum().reset_index()
    return df

# Global Constants
CONFIRMED_URL = "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv"
DEATHS_URL = "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv"
RELATIVE_PATH = "data-truth/usafacts"

# Download raw data
cases = pd.read_csv(CONFIRMED_URL, dtype={'countyFIPS': int, 'County Name': str, 'State': str, 'StateFIPS': int}).fillna(value = 'NA')
cases.to_csv(os.path.join(RELATIVE_PATH,"raw/covid_confirmed_usafacts.csv"), index = False)

deaths = pd.read_csv(DEATHS_URL, dtype={'countyFIPS': int, 'County Name': str, 'State': str, 'StateFIPS': int}).fillna(value = 'NA')
deaths.to_csv(os.path.join(RELATIVE_PATH,"raw/covid_deaths_usafacts.csv"), index = False)

# Reformat county, state and us data into records of each location-date pair per row
county_cases = reformat_county_data(cases.copy(deep = True))
county_deaths = reformat_county_data(deaths.copy(deep = True))

state_cases = reformat_state_data(cases.copy(deep = True))
state_deaths = reformat_state_data(deaths.copy(deep = True))

us_cases = state_cases.groupby(['date']).sum().reset_index()
us_cases.insert(loc = 1, column = 'location', value = 'US')

us_deaths = state_deaths.groupby(['date']).sum().reset_index()
us_deaths.insert(loc = 1, column = 'location', value = 'US')

overall_cases = pd.concat([county_cases, state_cases, us_cases])

overall_deaths = pd.concat([county_deaths, state_deaths, us_deaths])

# Output truth cumulative
overall_cases.to_csv(os.path.join(RELATIVE_PATH,"truth_usafacts-Cumulative Cases.csv"), columns = ['date', 'location', 'value'], header = ['date', 'location', 'value'], index = False)
overall_deaths.to_csv(os.path.join(RELATIVE_PATH,"truth_usafacts-Cumulative Deaths.csv"), columns = ['date', 'location', 'value'], header = ['date', 'location', 'value'], index = False)

# Output truth incident
overall_cases = overall_cases.reset_index()
overall_cases['diff_cases'] = overall_cases.groupby(by = ['location'])['value'].diff().fillna(overall_cases['value'])
overall_cases = overall_cases.astype({'diff_cases': int})
overall_cases.to_csv(os.path.join(RELATIVE_PATH,"truth_usafacts-Incident Cases.csv"), columns = ['date', 'location', 'diff_cases'], header = ['date', 'location', 'value'], index = False)

overall_deaths = overall_deaths.reset_index()
overall_deaths['diff_cases'] = overall_deaths.groupby(by = ['location'])['value'].diff().fillna(overall_deaths['value'])
overall_deaths = overall_deaths.astype({'diff_cases': int})
overall_deaths.to_csv(os.path.join(RELATIVE_PATH,"truth_usafacts-Incident Deaths.csv"), columns = ['date', 'location', 'diff_cases'], header = ['date', 'location', 'value'], index = False)
