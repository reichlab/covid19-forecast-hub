# flusight-csv-tools

[![Build Status](https://img.shields.io/travis/reichlab/flusight-csv-tools/master.svg?style=flat-square)](https://travis-ci.org/reichlab/flusight-csv-tools)
[![npm](https://img.shields.io/npm/v/flusight-csv-tools.svg?style=flat-square)](https://www.npmjs.com/package/flusight-csv-tools)
[![npm](https://img.shields.io/npm/l/flusight-csv-tools.svg?style=flat-square)](https://www.npmjs.com/package/flusight-csv-tools)

Node toolkit for CDC FluSight format CSVs. Full documentation
[here](http://reichlab.io/flusight-csv-tools). Provides features for:

1. Parsing CSVs (`fct.Csv` class)
2. Verifying CSVs (`fct.verify` module)
3. Scoring targets (`fct.score` module)
4. Fetching true values (`fct.truth` module)
5. Metadata related to CDC FluSight (`fct.meta` module)
6. Utilities for working with
   - Bin distributions (`fct.utils.bins` module)
   - Time and epiweeks (`fct.utils.epiweek` module)
   
## Quickstart

```bash
# Install from npm
npm i flusight-csv-tools
```

```js
// Read a csv
const fct = require('flusight-csv-tools')
let csv = new fct.Csv('./test/data/sample.csv', 201720, 'model-name')

// Verify
fct.verify.verifyHeaders(csv)
fct.verify.verifyPoint(csv)
fct.verify.verifyProbabilities(csv)

// Score
fct.score.score(csv).then(d => ...)
```

## Data representation

A CSV ingested by flusight-csv-tools uses the following standards for
representing information:

1. HHS Regions are referred to as `nat` (for 'US National') or `hhs1`, `hhs2`...
   for 'HHS Region 1', 'HHS Region 2' and so on.
2. Week ahead targets are referred using `1-ahead`, `2-ahead`, `3-ahead` and
   `4-ahead` while seasonal targets are `peak` (peak wili value), `peak-wk` and
   `onset-wk`.
3. A season 20xx-20yy is represented using a single number 20xx (the first year
   of a season).
4. Weeks values are not represented by themselves but are always passed around
   as epiweeks like YYYYWW where YYYY is the year and WW is the week (MMWR
   week).
5. An epidemic season 20xx contains all weeks in the set [20xx30, 20yy29], where
   20yy = 20xx + 1.
6. CSVs are scored using the latest available data and do not, as of yet, use
   the data available at the time the predictions were made.
