# CD/CI workflows with GitHub actions

COVID-19 Forecast Hub uses GitHub actions as its primary CD/CI tool. This page documents the actions and scripts involved with our CD/CI process.

(Note: _As the repository is getting larger in size, the GitHub Actions runner is unable to provide enough disk space for our CD/CI scripts. We are in progress of moving some actions to a Githooks based triggering system on a cloud VM._)

Some actions may contain identical initial steps. This is because each time a GitHub action is run, it is run on a clean VM with no software/packages/libraries installed.

## 1. Deploy to GitHub Pages

### Summary

1. Check disk space and delete temporary files
2. Checkout latest commit on `master` (uses [this external action](https://github.com/actions/checkout))
3. Install Node.js (uses [this external action](https://github.com/actions/setup-node))
4. Install Python (uses [this external action](https://github.com/actions/setup-python))
5. Install [Node.js requirements](https://github.com/reichlab/covid19-forecast-hub/blob/master/package.json)
6. Install [Python requirements](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/requirements.txt)
7. Deploy the contents in [`visualization/vis-master/dist`](https://github.com/reichlab/covid19-forecast-hub/tree/master/visualization/vis-master/dist) onto the [`gh-pages` branch](https://github.com/reichlab/covid19-forecast-hub/tree/gh-pages)

### Details

This action is quite simple. The Hub uses GitHub Pages to host our external-facing website; GitHub Pages hosts files on the `gh-pages` branch. The file `visualization/vis-master/dist/CNAME` determines under which domain should the host be configured.

Please consult the [GitHub Pages documentation](https://docs.github.com/en/free-pro-team@latest/github/working-with-github-pages) for how to set up GitHub Pages.

## 2. Validate on push/PR

### Summary

1. Checkout latest commit on `master`
2. Install Python
3. Install Python requirements
4. Run [this validation script](https://github.com/reichlab/covid19-forecast-hub/blob/master/code/validation/test_formatting.py)
   * The script implements [these validation rules](https://github.com/reichlab/covid19-forecast-hub/wiki/Data-Validation)

### Details

On every push to `master` and every newly-created pull request, this action is run to make sure that all CSV data files meets Zoltar's formatting requirements for CSV files. Teams will resubmit updated versions of their data files if the validation did not pass.

For an overview of all validation rules we have, please see [this page on the repository's wiki](https://github.com/reichlab/covid19-forecast-hub/wiki/Data-Validation).

## 3. Update local visualization

### Summary

1. Check disk space and delete temporary files
2. Checkout latest commit on `master`
3. Install Node.js
4. Install Python
5. Install Node.js requirements
6. Install Python requirements
7. Run [this build script](https://github.com/reichlab/covid19-forecast-hub/blob/master/travis/vis-build.sh)
   1. Validate that all metadata files exist and are in the correct location
   2. Parse raw CSV data into visualization's CSV format
   3. Get the latest truth data from JHU
   4. Parse data from sub step 2 to visualization's JSON format
   5. Build the visualization

### Details

The most important steps are the substeps of step 7; that is where the bulk of the work is done. The build script runs three separate scripts: [`0-init-vis.sh`](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/0-init-vis.sh), [`1-patch-vis.sh`](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/1-patch-vis.sh), and [`2-build-vis.sh`](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/2-build-vis.sh); please see the source code for details.

## 4. Weekly truth data update

### Summary

1. Checkout latest commit on `master`
2. Install Node.js
3. Install Python
4. Install Node.js requirements
5. Install Python requirements
6. Update truth data from JHU, NYTimes, USAFacts
   1. JHU data is both updated in the hub repository and on Zoltar
   2. NYTimes and USAFacts truth data is only updated in the repository

### Details

Mostly, the details are in the code for parsing JHU, NYTimes, and USAFacts data by their respective formats. All the relevant source code is in the [`data-truth/` folder](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-truth).

## 5. Upload to Zoltar

### Summary

1. Checkout latest commit on `master`
2. Install Node.js
3. Install Python
4. Install Node.js requirements
5. Install Python requirements
6. Upload all CSVs to Zoltar, including both forecast and truth CSVs

### Details

By design, we require the teams submit their forecast CSVs in Zoltar format to facilitate this pipeline. This action is run every 6 hours to upload the latest forecast and truth CSVs to Zoltar. To reduce the amount of data to upload, we use a JSON file containing hashes of all validated and uploaded forecast CSVs so that they are not uploaded twice. During the validation and upload process, if we find new files that we don't have hashes for, or old files that have a different hash, we will upload the relevant files (again).
