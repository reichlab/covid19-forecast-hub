import hashlib
import json
from pathlib import Path

import click
import zoltpy

from code.zoltar_scripts.upload_covid19_forecasts_to_zoltar import VALIDATED_FILE_DB, \
    DATA_PROCESSED_DIR


# run in the covid19-forecast-hub repo root
def main():
    """
    Utility that repairs validated_file_db.json by checking every forecast file in the local repo against it and then
    adding to it those that are missing. Only adds missing files that have been uploaded to Zoltar. NB: Does NOT check
    checksums. Requires Z_USERNAME and Z_PASSWORD env vars to be set for zoltar API access.
    """
    # try connecting to zoltar
    click.echo(f"connecting to zoltar")
    conn = zoltpy.util.authenticate()
    project_name = 'COVID-19 Forecasts'
    project = [project for project in conn.projects if project.name == project_name][0]

    with open(VALIDATED_FILE_DB, 'r') as fp:
        db = json.load(fp)

    # process files in two passes, which allows us to see the files being checked before hitting the Zoltar API (in case
    # that server is down):
    # 1) find local forecast files that are missing from the .json file
    # 2) check each one against zoltar to see if it was uploaded. if so then add it to db

    # step 1/2: compute missing_entries
    click.echo(f"processing: {DATA_PROCESSED_DIR}")
    missing_entries = []  # 2-tuples: (file_path, checksum)
    for model_dir in Path(DATA_PROCESSED_DIR).iterdir():
        if not model_dir.is_dir():
            continue

        for forecast_file in model_dir.iterdir():
            if forecast_file.suffix != '.csv':
                continue

            with open(forecast_file, "rb") as fp:
                checksum = hashlib.md5(fp.read()).hexdigest()
                if db.get(forecast_file.name, None) == checksum:
                    continue

                # we have a file not present in the json file, so add its path and checksum
                click.echo(f"! {forecast_file}\t{checksum}")
                missing_entries.append((forecast_file, checksum))

    click.echo(f"done processing. #missing_entries={len(missing_entries)}")
    if not missing_entries:
        click.echo('done')
        return

    for file_path, checksum in missing_entries:
        click.echo(f"- {file_path.name}\t{checksum}")

    # step 2/2: check missing_entries against zoltar uploads, saving only uploaded ones to db. NB: we do not check the
    # uploaded file's checksum against the local one
    click.echo("checking missing_entries against zoltar")
    latest_forecasts_source = [source for forecast_id, source in project.latest_forecasts]
    for file_path, checksum in missing_entries:
        if file_path.name in latest_forecasts_source:  # is in zoltar. NB: we do not check checksum
            click.echo(f"- adding to db: missing file IS in zoltar: {file_path.name}")
            db[file_path.name] = checksum
        else:
            click.echo(f"- not adding to db: missing file NOT in zoltar: {file_path.name}")

    # done. save db. NB: it's possible that there were no db additions if no missing_entries were uploaded, but the
    # saved .json file will be the same and git will know it.
    click.echo(f"saving: {VALIDATED_FILE_DB}")
    with open(VALIDATED_FILE_DB, 'w') as fp:
        json.dump(db, fp, indent=4)

    click.echo('done')


if __name__ == '__main__':
    main()
