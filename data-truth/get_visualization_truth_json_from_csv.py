import pandas as pd
import datetime
import pymmwr as pm


'''
    Get the epidemiological year, week and date of a given date.
'''
def get_epi_data(date):
    # The format
    format_str = '%Y-%m-%d' 
    dt = datetime.datetime.strptime(date, format_str).date()
    epi = pm.date_to_epiweek(dt)
    return epi.year, epi.week, epi.day

'''
    Get a dataframe of locations with information including fips code, state/county name, population, etc.
'''
def read_fips_codes(filepath):
    # read file
    fips_codes = pd.read_csv(filepath)
    # take state code from all fips codes
    fips_codes['state_abbr'] = fips_codes['location'].str[:2]

    # match state abbrevaition with state fips code
    fips_codes['state_abbr'] = fips_codes['state_abbr'].apply(lambda x: fips_codes[fips_codes.location ==x].abbreviation.tolist()[0] if str(x) in fips_codes['location'].tolist() else 'NA')

    # only output "location (fips code)","location_name","(state) abbreviation"
    fips_codes = fips_codes.drop('abbreviation',axis=1)
    fips_codes.rename({'state_abbr': 'abbreviation'}, axis=1, inplace=True)
    # took out DC county
    fips_codes = fips_codes[fips_codes.location != '11001']
    return fips_codes

def configure_visualization_truth(state_nat_truth, target):
    # Only visualize certain states, not county truths
    states = ['US', 'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
                'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
                'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
                'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
                'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
                'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
                'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia', 'Puerto Rico', 'Guam', 'Virgin Islands',
                'Northern Mariana Islands', 'American Samoa']

    state_nat_truth = state_nat_truth.merge(fips_codes, left_on='location_name', right_on='location_name', how='left')
    state_nat_truth = state_nat_truth.drop(['location_y'], axis=1)
    state_nat_truth = state_nat_truth.rename(columns={"location_x": "location"})
    state_nat_truth = state_nat_truth[state_nat_truth["location_name"].isin(states)]
    df_truth = state_nat_truth

    # get epi data from date
    df_truth['year'], df_truth['week'], df_truth['day'] = \
    zip(*df_truth['date'].map(get_epi_data))

    # Observed data on the seventh day
    # or group by week for incident deaths
    if target in ('Incident Deaths','Incident Cases'):
        df_truth['value'] = df_truth['value'].clip(lower=0.0)
        df_vis = df_truth.groupby(['week', 'location_name'], as_index=False).agg({'date': 'last',
                                                                                    'value': 'sum',
                                                                                    'year': 'last',
                                                                                    'day': 'last',
                                                                                    'location': 'last',
                                                                                    'abbreviation': 'last'})
                                                                                    
        df_vis = df_vis[df_vis['day'] == 7]
    else:
        df_vis = df_truth[df_truth['day'] == 7]


    # shift epiweek on axis

    df_vis['week'] = df_vis['week'] + 1  
    df_invalid = df_vis[df_vis['week'] > 53]
    # print(f"Number of invalid rows: {len(df_invalid.index)}")
    if len(df_invalid.index) > 0:
        df_vis.loc[df_vis['week'] > 53, 'year'] =df_vis[df_vis['week'] > 53]['year'] + 1
        df_vis.loc[df_vis['week'] > 53, 'week'] = 1
    # print(f"Number of invalid rows after operation: {len(df_vis[df_vis['week'] > 53].index)}")

    # add leading zeros to epi week
    df_vis['week'] = df_vis['week'].apply(lambda x: '{0:0>2}'.format(x))

    # define epiweek
    df_vis['epiweek'] = df_vis['year'].astype(str) + df_vis['week']

    # Replace US with "nat" this is NECESSARY for visualization code!
    df_vis.loc[df_vis["location_name"] == "US", "abbreviation"] = "nat"

    # only output "location", "epiweek", "value"
    df_truth_short = df_vis[["abbreviation", "epiweek", "value"]]
    df_truth_short = df_truth_short.rename(columns={"abbreviation": "location"})

    df_truth_short["value"].replace({0: 0.1}, inplace=True)

    file_path = 'visualization/vis-master/covid-csv-tools/dist/truth/' + target + '.json'

    # write to json
    with open(file_path, 'w') as f:
        f.write(df_truth_short.to_json(orient='records'))

fips_codes = read_fips_codes('data-locations/locations.csv')

configure_visualization_truth(state_nat_truth = pd.read_csv("data-truth/truth-Cumulative Deaths.csv"), target = "Cumulative Deaths")
configure_visualization_truth(state_nat_truth =  pd.read_csv("data-truth/truth-Incident Deaths.csv"), target = "Incident Deaths")

configure_visualization_truth(state_nat_truth =  pd.read_csv("data-truth/truth-Cumulative Cases.csv"), target = "Cumulative Cases")
configure_visualization_truth(state_nat_truth =  pd.read_csv("data-truth/truth-Incident Cases.csv"), target = "Incident Cases")