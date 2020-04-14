import pandas as pd
import glob


def reformat_forecasts(file_path):
    # read forecast
    fips_codes = pd.read_csv('../template/state_fips_codes.csv')
    df = pd.read_csv(file_path)

    # Include US and state data
    df["location_id"].replace({"US": 1000}, inplace=True)
    df["location_id"] = df["location_id"].apply(pd.to_numeric)
    df = df.merge(fips_codes, left_on='location_id', right_on='state_code', how='left')
    df.loc[df["location_id"] == 1000, "state_name"] = "US National"

    # Only visualize wk ahead forecasts
    targets = ['1 wk ahead cum', '2 wk ahead cum', '3 wk ahead cum', '4 wk ahead cum']
    df = df[df["target_id"].isin(targets)]

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
    quantiles = [0.05, 0.25, 0.75, 0.95, None]
    df = df[df["quantile"].isin(quantiles)]

    df["Unit"] = "integer"

    # Rename bin column
    df = df.rename(columns={"target_id": "Target",
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
    print(file_path)
    df2 = reformat_forecasts(file_path)
    df2.to_csv(file_path, index=False, float_format='%.14f')
