#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import os
from pathlib import Path

# In[2]:

root =(Path(__file__)/'..').resolve()
df=pd.read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")


# In[3]:


locs = pd.read_csv(open(root/'locations.csv', 'r'))
locs = locs[locs['location']!='US'].astype({'location':'int64'})


# In[4]:


st_pop = df[[ 'Province_State', 'Population']].groupby(
    'Province_State').sum().reset_index().rename(
    columns={'Province_State':'location_name'}
).merge(
    locs, how='left',on='location_name'
).dropna(subset=['abbreviation'])
pop_df = df[df['FIPS'].notna()][['FIPS', 'Province_State', 'Admin2','Population']].astype({'FIPS':'int64'}).rename(columns={'FIPS':'location'})
pop_df = pd.concat([pop_df, st_pop]).astype({'location':'int64'})[['location', 'Province_State', 'Admin2','Population']]


# In[5]:


df_pop = locs.merge(
    pop_df, how='left', on='location'
)[['abbreviation', 'location', 'location_name', 'Population']].drop_duplicates()


# In[6]:


df_pop.to_csv(open(root/'populations.csv','w'), index=False)


# In[ ]:





# In[ ]:




