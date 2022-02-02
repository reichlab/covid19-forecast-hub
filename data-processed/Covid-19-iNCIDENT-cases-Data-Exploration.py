#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd


# In[2]:


df = pd.read_csv('~/Documents/Python/truth-Incident-Cases.csv')


# In[ ]:


print(df)


# In[ ]:


df


# In[3]:


df.info()


# In[4]:


df['date'] = pd.to_datetime(df['date'])


# In[5]:


df.info()


# In[6]:


print(df['date'][0].day)


# In[7]:


df['location_name'].nunique()


# In[8]:


df.isnull().any()


# In[9]:


df['location_name'].unique().tolist()


# In[10]:


df['location_name'].unique()


# In[11]:


df_US = df[df['location_name']=='US']


# In[12]:


df_US


# In[13]:


pd.options.display.max_rows


# In[14]:


pd.set_option('display.max_rows',None)


# In[15]:


df_US


# In[16]:


import matplotlib.pyplot as plt


# In[17]:


plt.style.use('seaborn-whitegrid')


# In[18]:


import os
import numpy as np
import time


# In[19]:


df1 = df_US.drop(columns = ['location_name'])


# In[20]:


df1


# In[21]:


df1.drop(df1.index[df1['date'] == '2020-01-22'],inplace = True)


# In[22]:


df1.drop(df1.index[df1['date'] == '2020-01-23'],inplace = True)


# In[23]:


df1.drop(df1.index[df1['date'] == '2020-01-24'],inplace = True)


# In[24]:


df1.drop(df1.index[df1['date'] == '2020-01-25'],inplace = True)


# In[25]:


df1.drop(df1.index[df1['date'] == '2020-01-26'],inplace = True)


# In[26]:


df1


# In[27]:


x = df1[['date']]
x['date'].dt.day_name()


# In[28]:


df1['day_name'] = df1['date'].dt.day_name()
df1


# In[29]:


def new_case_count(state_new_cases):
    first_monday_found = False;
    week_case_count = 0;
    week_case_counts = [];
    for date in state_new_cases['date']:
        day_of_the_week_name = 


# In[30]:


df1


# In[31]:


df1 = df1.reset_index()


# In[32]:


df1


# In[33]:


df1.info()
df1 = df1.drop(columns = ['index'])
df1


# In[35]:


df1.set_index('date',inplace = True)


# In[36]:


df1


# In[37]:


x = df1.resample('w').sum()


# In[38]:


x


# In[39]:


x.reset_index()


# In[40]:


x = x.rename(columns = {'value':'cases'})


# In[41]:


x


# In[42]:


x = x.reset_index()


# In[43]:


x


# In[44]:


import seaborn as sns


# In[45]:


import matplotlib.pyplot as plt


# In[82]:


plt.plot(x['date'],x['cases'])
plt.xlabel('Time: 2020 - Present')
plt.ylabel('Cases in millions')
ax = plt.gca()
ax.axes.xaxis.set_ticklabels([])
ax.axes.yaxis.set_ticklabels([])


# In[47]:


y = x['cases'].max()


# In[48]:


y


# In[49]:


import numpy as np


# In[51]:


pd.set_option('display.max_rows',60)


# In[52]:


df


# In[53]:


df['location_name']


# In[57]:


df_w = df[df['location_name'] == 'Wisconsin']


# In[58]:


df_w


# In[60]:


df_w = df_w.drop(columns = ['location_name'])


# In[61]:


df_w


# In[62]:


df_w.drop(df_w.index[df_w['date'] == '2020-01-22'],inplace = True)


# In[63]:


df_w.drop(df_w.index[df_w['date'] == '2020-01-23'],inplace = True)


# In[64]:


df_w.drop(df_w.index[df_w['date'] == '2020-01-24'],inplace = True)


# In[65]:


df_w.drop(df_w.index[df_w['date'] == '2020-01-25'],inplace = True)


# In[66]:


df_w.drop(df_w.index[df_w['date'] == '2020-01-26'],inplace = True)


# In[67]:


df_w


# In[68]:


df_w = df_w.drop(columns = ['location'])


# In[70]:


df_w


# In[72]:


df_w.info()


# In[73]:


df_w = df_w.set_index('date')


# In[75]:


df_w


# In[76]:


df_w = df_w.resample('w').sum()


# In[77]:


df_w


# In[78]:


df_w = df_w.reset_index()


# In[79]:


df_w


# In[80]:


df_w = df_w.rename(columns = {'value':'cases'})


# In[81]:


df_w


# In[83]:


plt.plot(df_w['date'],df_w['cases'])
plt.xlabel('Time: 2020 - Present')
plt.ylabel('Cases in millions')
ax = plt.gca()
ax.axes.xaxis.set_ticklabels([])
ax.axes.yaxis.set_ticklabels([])


# In[84]:


plt.plot(x['date'],x['cases'])
plt.xlabel('Time: 2020 - Present')
plt.ylabel('Cases in millions')
ax = plt.gca()
ax.axes.xaxis.set_ticklabels([])
ax.axes.yaxis.set_ticklabels([])


# In[ ]:




