from utils import *
import pandas as pd
import os

def get_model_info(search_item):
    data = get_data()
    results = {}
    forecasts = data.glob('**/*.csv')
    for forecast in forecasts:
        if forecast.match('*'+ search_item + '*'):
            # print(forecast)
            model_abbr = forecast.parts[-2].strip()
            if model_abbr not in results:
                print(model_abbr)
                results[model_abbr] = {
                    'targets': set(),
                    'state_nat_vals': 0,
                    'county_vals':0,
                    'state_locations' : set()
                }
            res = results[model_abbr]
            df = pd.read_csv(open(forecast, 'r'))
            res['targets'] =  res['targets'].union(set(df['target'].unique()))
            df.loc[df['location'] == 'US'] = '-1'
            df['location'] = df['location'].astype(int)
            res['state_nat_vals'] += df[df['location'] < 60].shape[0]
            res['county_vals'] += df[df['location'] > 999].shape[0]
            res['state_locations'] = res['state_locations'].union(df[df['location'] < 60]['location'].unique())
            
    return results

if __name__ == "__main__":
    import pprint
    pprint.pprint(get_model_info('YYG'))
    pass