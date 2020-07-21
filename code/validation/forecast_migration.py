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
        'forecast_date',
        'target_end_date',
        'value'
    ]
    return df.loc[:, cols_to_keep], set(cols_to_keep) == set(df.columns)


def remove_rows_2(df):
    rows_to_retain = [f"{_} day ahead inc hosp" for _ in range(131)] + \
                     [f"{_} wk ahead inc death" for _ in range(1, 21)] + \
                     [f"{_} wk ahead cum death" for _ in range(1, 21)] + \
                     [f"{_} wk ahead inc case" for _ in range(1, 9)]
    df_rows = df['target'].isin(rows_to_retain)
    return df.loc[df_rows], df_rows.sum() == df.shape[0]


def fix_location(df):
    df_l = df['location'].astype(str).str.zfill(2)
    change_flag = df['location'] == df_l
    df['location'] = df_l
    return df, change_flag.all()


# dictionary containing a list of function for migration.
# Example: for migration to version "2": specify a list of functions that accept
# a pandas.DataFrame and return a modified pandas.DataFrame and a boolean flag indicating
# whether the data has been changed that will be used in the subsequent call in the chain.
# Basically, the dict has key = version and value = list of function to be
# executed **sequentially**
migration_funcs = {
    2: [
        remove_cols_2
    ],
    3: [
        remove_rows_2
    ],
    4: [
        fix_location
    ]
}


def migrate_to(data_dir, version):
    d_dir = Path(data_dir)
    try:
        csvs = d_dir.glob('**/*.csv')
        for csv in csvs:
            has_not_changed = True
            df = pd.read_csv(csv)
            for funcs in migration_funcs[version]:
                df, flag = funcs(df)
                has_not_changed = has_not_changed & flag
            # write the modified forecast file back
            if not has_not_changed:
                if df.shape[0] == 0:
                    print('Deleting file %s' % csv.name)
                    csv.unlink()
                else:
                    print('Writing file %s' % csv.name)
                    df.to_csv(csv, index=False)
            else:
                print('%s has not changed.' % csv.name)
    except Exception as e:
        return e
    return True


if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hv:d:", ["version=", "data-dir="])
    except getopt.GetoptError:
        print('forecast_migration.py -v <version>')
        sys.exit(2)
    version, data_dir = 3, './data-processed'
    for opt, arg in opts:
        if opt == '-h':
            print('forecast_migration.py -v <version>')
            sys.exit()
        elif opt in ("-v", "--version"):
            version = int(arg)
        elif opt in ("-d", "--data-dir"):
            data_dir = arg
    res = migrate_to(data_dir, version)
    if isinstance(res, Exception):
        sys.stderr.write("Exception while migrating: " + str(res))
        sys.exit(3)
    else:
        print("Successful migration")
