#mcandrew

from interface import interface
from model import VAR
import pandas as pd
import numpy as np

if __name__ == "__main__":
    
    io = interface(0)
    predictions = io.grab_recent_predictions()
    df1 = pd.read_csv('2022-02-21_LUcompUncertLab-VAR__predictions.csv')
    #working on location number 10
    df2 = df1[df1['location'] == 10]
    print(df2.info())
    df2['forecast_date'] = pd.to_datetime(df2['forecast_date'])
    df2['target_end_date'] = pd.to_datetime(df2['target_end_date'])
    print(df2.info())
    content_1 = ['1 day ahead inc covid case','2 day ahead inc covid case','3 day ahead inc covid case','4 day ahead inc covid case','5 day ahead inc covid case','6 day ahead inc covid case','7 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_1),'wn'] = 1
    content_2 = ['8 day ahead inc covid case','9 day ahead inc covid case','10 day ahead inc covid case','11 day ahead inc covid case','12 day ahead inc covid case','13 day ahead inc covid case','14 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_2),'wn'] = 2
    content_3 = ['15 day ahead inc covid case','16 day ahead inc covid case','17 day ahead inc covid case','18 day ahead inc covid case','19 day ahead inc covid case','20 day ahead inc covid case','21 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_3),'wn'] = 3
    content_4 = ['22 day ahead inc covid case','23 day ahead inc covid case','24 day ahead inc covid case','25 day ahead inc covid case','26 day ahead inc covid case','27 day ahead inc covid case','28 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_4),'wn'] = 4
    content_5 = ['1 day ahead inc covid death','2 day ahead inc covid death','3 day ahead inc covid death','4 day ahead inc covid death','5 day ahead inc covid death','6 day ahead inc covid death','7 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_5),'wn'] = 1
    content_6 = ['8 day ahead inc covid death','9 day ahead inc covid death','10 day ahead inc covid death','11 day ahead inc covid death','12 day ahead inc covid death','13 day ahead inc covid death','14 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_6),'wn'] = 2
    content_7 = ['15 day ahead inc covid death','16 day ahead inc covid death','17 day ahead inc covid death','18 day ahead inc covid death','19 day ahead inc covid death','20 day ahead inc covid death','21 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_7),'wn'] = 3
    content_8 = ['22 day ahead inc covid death','23 day ahead inc covid death','24 day ahead inc covid death','25 day ahead inc covid death','26 day ahead inc covid death','27 day ahead inc covid death','28 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_8),'wn'] = 4
    content_9 = ['1 day ahead inc covid hosp','2 day ahead inc covid hosp','3 day ahead inc covid hosp','4 day ahead inc covid hosp','5 day ahead inc covid hosp','6 day ahead inc covid hosp','7 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_9),'wn'] = 1
    content_10 = ['8 day ahead inc covid hosp','9 day ahead inc covid hosp','10 day ahead inc covid hosp','11 day ahead inc covid hosp','12 day ahead inc covid hosp','13 day ahead inc covid hosp','14 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_10),'wn'] = 2
    content_11 = ['15 day ahead inc covid hosp','16 day ahead inc covid hosp','17 day ahead inc covid hosp','18 day ahead inc covid hosp','19 day ahead inc covid hosp','20 day ahead inc covid hosp','21 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_11),'wn'] = 3
    content_12 = ['22 day ahead inc covid hosp','23 day ahead inc covid hosp','24 day ahead inc covid hosp','25 day ahead inc covid hosp','26 day ahead inc covid hosp','27 day ahead inc covid hosp','28 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_12),'wn'] = 4
    content_13 = ['1 day ahead inc covid case','2 day ahead inc covid case','3 day ahead inc covid case','4 day ahead inc covid case','5 day ahead inc covid case','6 day ahead inc covid case','7 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_1),'Measurable'] = 'case'
    content_14 = ['8 day ahead inc covid case','9 day ahead inc covid case','10 day ahead inc covid case','11 day ahead inc covid case','12 day ahead inc covid case','13 day ahead inc covid case','14 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_2),'Measurable'] = 'case'
    content_15 = ['15 day ahead inc covid case','16 day ahead inc covid case','17 day ahead inc covid case','18 day ahead inc covid case','19 day ahead inc covid case','20 day ahead inc covid case','21 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_3),'Measurable'] = 'case'
    content_16 = ['22 day ahead inc covid case','23 day ahead inc covid case','24 day ahead inc covid case','25 day ahead inc covid case','26 day ahead inc covid case','27 day ahead inc covid case','28 day ahead inc covid case']
    df2.loc[df2['target'].isin(content_4),'Measurable'] = 'case'
    content_17 = ['1 day ahead inc covid death','2 day ahead inc covid death','3 day ahead inc covid death','4 day ahead inc covid death','5 day ahead inc covid death','6 day ahead inc covid death','7 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_5),'Measurable'] = 'death'
    content_18 = ['8 day ahead inc covid death','9 day ahead inc covid death','10 day ahead inc covid death','11 day ahead inc covid death','12 day ahead inc covid death','13 day ahead inc covid death','14 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_6),'Measurable'] = 'death'
    content_19 = ['15 day ahead inc covid death','16 day ahead inc covid death','17 day ahead inc covid death','18 day ahead inc covid death','19 day ahead inc covid death','20 day ahead inc covid death','21 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_7),'Measurable'] = 'death'
    content_20 = ['22 day ahead inc covid death','23 day ahead inc covid death','24 day ahead inc covid death','25 day ahead inc covid death','26 day ahead inc covid death','27 day ahead inc covid death','28 day ahead inc covid death']
    df2.loc[df2['target'].isin(content_8),'Measurable'] = 'death'
    content_21 = ['1 day ahead inc covid hosp','2 day ahead inc covid hosp','3 day ahead inc covid hosp','4 day ahead inc covid hosp','5 day ahead inc covid hosp','6 day ahead inc covid hosp','7 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_9),'Measurable'] = 'hosp'
    content_22 = ['8 day ahead inc covid hosp','9 day ahead inc covid hosp','10 day ahead inc covid hosp','11 day ahead inc covid hosp','12 day ahead inc covid hosp','13 day ahead inc covid hosp','14 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_10),'Measurable'] = 'hosp'
    content_23 = ['15 day ahead inc covid hosp','16 day ahead inc covid hosp','17 day ahead inc covid hosp','18 day ahead inc covid hosp','19 day ahead inc covid hosp','20 day ahead inc covid hosp','21 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_11),'Measurable'] = 'hosp'
    content_24 = ['22 day ahead inc covid hosp','23 day ahead inc covid hosp','24 day ahead inc covid hosp','25 day ahead inc covid hosp','26 day ahead inc covid hosp','27 day ahead inc covid hosp','28 day ahead inc covid hosp']
    df2.loc[df2['target'].isin(content_12),'Measurable'] = 'hosp'
    df2.set_index('target_end_date', inplace = True)
    grouped = df2.groupby(df2.Measurable)
    df_hosp = grouped.get_group('hosp')
    df_case = grouped.get_group('case')
    df_death = grouped.get_group('death')
    df_hosp_groupby_saample = df_hosp.groupby('sample')
    df_hosp_groupby_sample_2_location_10 = df_hosp_groupby_saample.resample('w').sum()
    df_case_groupby_sample = df_case.groupby('sample')
    df_case_groupby_sample_2_location_10 = df_case_groupby_sample.resample('w').sum()
    df_death_groupby_sample = df_death.groupby('sample')
    df_death_groupby_sample_2_location_10 = df_death_groupby_sample.resample('w').sum()
    #working on location number 42
    df3 = df1[df1['location'] == 42]
    print(df3.info())
    df3['forecast_date'] = pd.to_datetime(df3['forecast_date'])
    df3['target_end_date'] = pd.to_datetime(df3['target_end_date'])
    print(df3.info())
    content_25 = ['1 day ahead inc covid case','2 day ahead inc covid case','3 day ahead inc covid case','4 day ahead inc covid case','5 day ahead inc covid case','6 day ahead inc covid case','7 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_25),'wn'] = 1
    content_26 = ['8 day ahead inc covid case','9 day ahead inc covid case','10 day ahead inc covid case','11 day ahead inc covid case','12 day ahead inc covid case','13 day ahead inc covid case','14 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_26),'wn'] = 2
    content_27 = ['15 day ahead inc covid case','16 day ahead inc covid case','17 day ahead inc covid case','18 day ahead inc covid case','19 day ahead inc covid case','20 day ahead inc covid case','21 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_27),'wn'] = 3
    content_28 = ['22 day ahead inc covid case','23 day ahead inc covid case','24 day ahead inc covid case','25 day ahead inc covid case','26 day ahead inc covid case','27 day ahead inc covid case','28 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_28),'wn'] = 4
    content_29 = ['1 day ahead inc covid death','2 day ahead inc covid death','3 day ahead inc covid death','4 day ahead inc covid death','5 day ahead inc covid death','6 day ahead inc covid death','7 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_29),'wn'] = 1
    content_30 = ['8 day ahead inc covid death','9 day ahead inc covid death','10 day ahead inc covid death','11 day ahead inc covid death','12 day ahead inc covid death','13 day ahead inc covid death','14 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_30),'wn'] = 2
    content_31 = ['15 day ahead inc covid death','16 day ahead inc covid death','17 day ahead inc covid death','18 day ahead inc covid death','19 day ahead inc covid death','20 day ahead inc covid death','21 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_31),'wn'] = 3
    content_32 = ['22 day ahead inc covid death','23 day ahead inc covid death','24 day ahead inc covid death','25 day ahead inc covid death','26 day ahead inc covid death','27 day ahead inc covid death','28 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_32),'wn'] = 4
    content_33 = ['1 day ahead inc covid hosp','2 day ahead inc covid hosp','3 day ahead inc covid hosp','4 day ahead inc covid hosp','5 day ahead inc covid hosp','6 day ahead inc covid hosp','7 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_33),'wn'] = 1
    content_34 = ['8 day ahead inc covid hosp','9 day ahead inc covid hosp','10 day ahead inc covid hosp','11 day ahead inc covid hosp','12 day ahead inc covid hosp','13 day ahead inc covid hosp','14 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_34),'wn'] = 2
    content_35 = ['15 day ahead inc covid hosp','16 day ahead inc covid hosp','17 day ahead inc covid hosp','18 day ahead inc covid hosp','19 day ahead inc covid hosp','20 day ahead inc covid hosp','21 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_35),'wn'] = 3
    content_36 = ['22 day ahead inc covid hosp','23 day ahead inc covid hosp','24 day ahead inc covid hosp','25 day ahead inc covid hosp','26 day ahead inc covid hosp','27 day ahead inc covid hosp','28 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_36),'wn'] = 4
    content_37 = ['1 day ahead inc covid case','2 day ahead inc covid case','3 day ahead inc covid case','4 day ahead inc covid case','5 day ahead inc covid case','6 day ahead inc covid case','7 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_37),'Measurable'] = 'case'
    content_38 = ['8 day ahead inc covid case','9 day ahead inc covid case','10 day ahead inc covid case','11 day ahead inc covid case','12 day ahead inc covid case','13 day ahead inc covid case','14 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_38),'Measurable'] = 'case'
    content_39 = ['15 day ahead inc covid case','16 day ahead inc covid case','17 day ahead inc covid case','18 day ahead inc covid case','19 day ahead inc covid case','20 day ahead inc covid case','21 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_39),'Measurable'] = 'case'
    content_40 = ['22 day ahead inc covid case','23 day ahead inc covid case','24 day ahead inc covid case','25 day ahead inc covid case','26 day ahead inc covid case','27 day ahead inc covid case','28 day ahead inc covid case']
    df3.loc[df3['target'].isin(content_40),'Measurable'] = 'case'
    content_41 = ['1 day ahead inc covid death','2 day ahead inc covid death','3 day ahead inc covid death','4 day ahead inc covid death','5 day ahead inc covid death','6 day ahead inc covid death','7 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_41),'Measurable'] = 'death'
    content_42 = ['8 day ahead inc covid death','9 day ahead inc covid death','10 day ahead inc covid death','11 day ahead inc covid death','12 day ahead inc covid death','13 day ahead inc covid death','14 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_42),'Measurable'] = 'death'
    content_43 = ['15 day ahead inc covid death','16 day ahead inc covid death','17 day ahead inc covid death','18 day ahead inc covid death','19 day ahead inc covid death','20 day ahead inc covid death','21 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_43),'Measurable'] = 'death'
    content_44 = ['22 day ahead inc covid death','23 day ahead inc covid death','24 day ahead inc covid death','25 day ahead inc covid death','26 day ahead inc covid death','27 day ahead inc covid death','28 day ahead inc covid death']
    df3.loc[df3['target'].isin(content_44),'Measurable'] = 'death'
    content_45 = ['1 day ahead inc covid hosp','2 day ahead inc covid hosp','3 day ahead inc covid hosp','4 day ahead inc covid hosp','5 day ahead inc covid hosp','6 day ahead inc covid hosp','7 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_45),'Measurable'] = 'hosp'
    content_46 = ['8 day ahead inc covid hosp','9 day ahead inc covid hosp','10 day ahead inc covid hosp','11 day ahead inc covid hosp','12 day ahead inc covid hosp','13 day ahead inc covid hosp','14 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_46),'Measurable'] = 'hosp'
    content_47 = ['15 day ahead inc covid hosp','16 day ahead inc covid hosp','17 day ahead inc covid hosp','18 day ahead inc covid hosp','19 day ahead inc covid hosp','20 day ahead inc covid hosp','21 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_47),'Measurable'] = 'hosp'
    content_48 = ['22 day ahead inc covid hosp','23 day ahead inc covid hosp','24 day ahead inc covid hosp','25 day ahead inc covid hosp','26 day ahead inc covid hosp','27 day ahead inc covid hosp','28 day ahead inc covid hosp']
    df3.loc[df3['target'].isin(content_48),'Measurable'] = 'hosp'
    df3.set_index('target_end_date', inplace = True)
    grouped_1 = df3.groupby(df3.Measurable)
    df_hosp_1 = grouped.get_group('hosp')
    df_case_1 = grouped.get_group('case')
    df_death_1 = grouped.get_group('death')
    df_hosp_groupby_saample_3 = df_hosp_1.groupby('sample')
    df_hosp_groupby_sample_4_location_42 = df_hosp_groupby_saample_3.resample('w').sum()
    df_case_groupby_sample_5 = df_case_1.groupby('sample')
    df_case_groupby_sample_6_location_42 = df_case_groupby_sample_5.resample('w').sum()
    df_death_groupby_sample_7 = df_death_1.groupby('sample')
    df_death_groupby_sample_8_location_42 = df_death_groupby_sample_7.resample('w').sum()
    print(df_death_groupby_sample_8_location_42.head(100))

