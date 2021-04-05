#!/usr/bin/env python
# coding: utf-8

# This scripts updates the population for each state and county
# NOTE: does not add county if not already present!

# In[1]:
import pandas as pd
from pathlib import Path
import numpy as np

# get root of repository
root = (Path(__file__)/'..').resolve()

# read latest CSV file (incident deaths) from JHU
df = pd.read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")

# In[3]:
# load our locations CSV into a dataframe
locs = pd.read_csv(open(root/'locations.csv', 'r'))

# filter out national level
locs = locs[locs['location']!='US'].astype({'location':'int64'})

# In[4]:
# calculate state population:
#   1. group by state (JHU reports county-level)
#   2. sum within each group
#   3. reset the index
#   4. rename columns appropriately
#   5. merge with our locations dataframe on location
#   6. drop any NAs; currently drops
#       - any counties in territories
#       - FIPS code >= 80000 (unassigned/out of state)
st_pop = df[['Province_State', 'Population']] \
    .groupby('Province_State') \
    .sum() \
    .reset_index() \
    .rename(columns={
        'Province_State': 'location_name',
        'Population': 'population'
    }).merge(
        locs, how='left', on='location_name'
    ).dropna(subset=['abbreviation'])

# get county population dataframe
pop_df = df[df['FIPS'].notna()] \
    [['FIPS', 'Province_State', 'Admin2', 'Population']] \
        .astype({'FIPS': 'int64'}) \
        .rename(columns={
            'FIPS': 'location',
            'Population': 'population'
        })

# append state pop dataframe to county pop dataframe
pop_df = pd.concat([pop_df, st_pop]) \
    .astype({'location':'int64'}) \
        [['location', 'Province_State', 'Admin2', 'population']]

# In[5]:
# merge old dataframe with pop dataframe for an update
updated_locs = locs.merge(pop_df, how='left', on='location') \
    [['abbreviation', 'location', 'location_name', 'population_x']] \
        #.drop_duplicates()

# rename columns appropriately
updated_locs.rename(columns={'population_x': 'population'}, inplace=True)

# In[6]:
updated_locs['location'] = updated_locs['location'] \
    .astype(str) \
    .apply(lambda x: '{0:0>2}'.format(x)) \
    .apply(lambda x: '{0:0>2}'.format(x))

updated_locs.loc[updated_locs['abbreviation'].isna(), 'location'] = updated_locs \
    .loc[updated_locs['abbreviation'].isna(), 'location'] \
    .apply(lambda x: '{0:0>5}'.format(x))

# calculate national level population
top_row = pd.DataFrame({
    'abbreviation': ['US'],
    'location': ['US'],
    'location_name': ['US'],
    'population': [np.sum(st_pop[st_pop['location'] < 57]['population_x'])]
})
updated_locs = pd.concat([top_row, updated_locs]).reset_index(drop = True)

updated_locs.to_csv(open(root/'locations.csv','w'), index=False)
