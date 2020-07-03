import getopt
import os

import pandas as pd
import sys
from pathlib import Path


def remove_cols_2(df):
    """
    Migration function to extract only the specified columns in teh DataFrame
    """
    cols_to_keep = [

        'location',
        'target',
        'type',
        'quantile',
        'value'
    ]
    return df.loc[:, cols_to_keep]


# dictionary containing a list of function for migration.
# Example: for migration to version "2": specify a list of functions that accept
# a pandas.DataFrame and return a modified pandas.DataFrame that will be used in the
# subsequent cal in the chain.
# Basically, the dict has key = version and value = list of function to be
# executed **sequentially**
migration_funcs = {
    2: [
        remove_cols_2
    ]
}


def migrate_to(data_dir, version):
    d_dir = Path(data_dir)
    try:
        csvs = d_dir.glob('**/*.csv')
        for csv in csvs:
            df = pd.read_csv(csv)
            for funcs in migration_funcs[version]:
                df = funcs(df)
            # write the modified forecast file back
            df.to_csv(csv)
    except Exception as e:
        return e
    return True


if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hv:d:", ["version=", "data-dir="])
    except getopt.GetoptError:
        print('forecast_migration.py -v <version>')
        sys.exit(2)
    version, data_dir = 2, './data-processed'
    for opt, arg in opts:
        if opt == '-h':
            print('forecast_migration.py -v <version>')
            sys.exit()
        elif opt in ("-v", "--version"):
            version = arg
        elif opt in ("-d", "--data-dir"):
            data_dir = arg
    res = migrate_to(data_dir, version)
    if isinstance(res, Exception):
        sys.stderr.write("Execption while migrating: " + str(res))
        sys.exit(3)
    else:
        print("Successful migration")
