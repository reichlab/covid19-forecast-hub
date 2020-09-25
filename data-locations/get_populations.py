#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import os
from pathlib import Path
import numpy as np

root =(Path(__file__)/'..').resolve()
df=pd.read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")

# In[3]:
locs = pd.read_csv(open(root/'locations.csv', 'r'))
locs = locs[locs['location']!='US'].astype({'location':'int64'})

# In[4]:


st_pop = df[[ 'Province_State', 'Population']].groupby(
    'Province_State').sum().reset_index().rename(
    columns={'Province_State':'location_name', 'Population': 'population'}
).merge(
    locs, how='left',on='location_name'
).dropna(subset=['abbreviation'])
pop_df = df[df['FIPS'].notna()][['FIPS', 'Province_State', 'Admin2','Population']].astype({'FIPS':'int64'}).rename(columns={'FIPS':'location', 'Population':'population'})
pop_df = pd.concat([pop_df, st_pop]).astype({'location':'int64'})[['location', 'Province_State', 'Admin2','population']]

# In[5]:


df_pop = locs.merge(
    pop_df, how='left', on='location'
)[['abbreviation', 'location', 'location_name', 'population']].drop_duplicates()

# In[6]:

df_pop['location'] = df_pop['location'].astype(str).apply(lambda x: '{0:0>2}'.format(x)).apply(lambda x: '{0:0>2}'.format(x))

df_pop.loc[df_pop['abbreviation'].isna(), 'location'] = df_pop.loc[df_pop['abbreviation'].isna(), 'location'].apply(lambda x: '{0:0>5}'.format(x))


top_row = pd.DataFrame({'abbreviation':['US'],'location':['US'],'location_name':['US'], 'population': [np.sum(st_pop[st_pop['location'] < 57]['population'])]})
df_pop = pd.concat([top_row, df_pop]).reset_index(drop = True)

df_pop.to_csv(open(root/'locations.csv','w'), index=False)




