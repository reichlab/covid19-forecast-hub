import pandas as pd
import glob
import os


def reformat_forecasts(file_path, target):
    # read forecast
    fips_codes = pd.read_csv('../template/state_fips_codes.csv')
    df = pd.read_csv(file_path)

    # lowercase all column headers
    df.columns = map(str.lower, df.columns)

    # Include US and state data
    locations_in_file = df["location"].unique()
    if "US" in locations_in_file:
        df["location"].replace({"US": 1000}, inplace=True)
        df["location"] = df["location"].apply(pd.to_numeric)
        df = df.merge(fips_codes, left_on='location', right_on='state_code', how='left')
        df.loc[df["location"] == 1000, "state_name"] = "US National"
    else:
        df["location"] = df["location"].apply(pd.to_numeric)
        df = df.merge(fips_codes, left_on='location', right_on='state_code', how='left')

    # Only visualize wk ahead forecasts
    if target == 'Cumulative Deaths':
        targets = ['1 wk ahead cum death',
                   '2 wk ahead cum death',
                   '3 wk ahead cum death',
                   '4 wk ahead cum death']
    elif target == 'Incident Deaths':
        targets = ['1 wk ahead inc death',
                   '2 wk ahead inc death',
                   '3 wk ahead inc death',
                   '4 wk ahead inc death']
    df = df[df["target"].isin(targets)]

    # Only visualize certain states
    states = ['US National', 'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
              'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
              'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
              'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
              'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
              'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
              'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia']
    df = df[df["state_name"].isin(states)]

    # Only visualize certain quantiles
    quantiles = [0.025, 0.25, 0.75, 0.975, None]  # 95 and 50 % CI
    # quantiles = [0.05, 0.25, 0.75, 0.95, None] # 90 and 50 % CI
    df["quantile"] = df["quantile"].round(3)
    df = df[df["quantile"].isin(quantiles)]

    df["Unit"] = "integer"

    # Rename bin column
    df = df.rename(columns={"target": "Target",
                            "state_name": "Location",
                            "type": "Type",
                            "quantile": "Quantile",
                            "value": "Value"})

    # use "NA" instead of null value
    df = df.fillna("NA")

    # Reorder Columns
    df = df[["Location", "Target", "Type", "Unit", "Quantile", "Value"]]

    return df


# loop through model directories
my_path = "./data/"
for file_path in glob.iglob(my_path + "**/**/*.csv", recursive=False):
    target = os.path.basename(os.path.dirname(os.path.dirname(file_path)))
    print(file_path)
    df2 = reformat_forecasts(file_path, target)
    df2.to_csv(file_path, index=False, float_format='%.14f')
