"use strict";
/**
 * Module for working with truth related data
 */
Object.defineProperty(exports, "__esModule", {
  value: true
});
const fs = require("fs-extra");
const path = require("path");

function readJSON(filePath) {
  return __awaiter(this, void 0, void 0, function* () {
    return JSON.parse(yield fs.readFile(filePath, 'utf8'));
  });
}

var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
  return new(P || (P = Promise))(function (resolve, reject) {
    function fulfilled(value) {
      try {
        step(generator.next(value));
      } catch (e) {
        reject(e);
      }
    }

    function rejected(value) {
      try {
        step(generator["throw"](value));
      } catch (e) {
        reject(e);
      }
    }

    function step(result) {
      result.done ? resolve(result.value) : new P(function (resolve) {
        resolve(result.value);
      }).then(fulfilled, rejected);
    }
    step((generator = generator.apply(thisArg, _arguments || [])).next());
  });
};
Object.defineProperty(exports, "__esModule", {
  value: true
});
const meta_1 = require("./meta");
const delphi = require("./delphi");
const download = require("download");
const arrayEqual = require("array-equal");
const u = require("./utils");
var rename = require('deep-rename-keys');
/**
 * Url for fetching baseline data from
//  */
// const BASELINE_URL = 'https://raw.githubusercontent.com/cdcepi/FluSight-forecasts/master/wILI_Baseline.csv';
// /**
//  * Download baseline csv file to given path and return a promise for the path
//  */
// function downloadBaseline(cacheFile) {
//   return __awaiter(this, void 0, void 0, function* () {
//     let data = yield download(BASELINE_URL);
//     yield u.cache.writeInCache(cacheFile, data);
//     return cacheFile;
//   });
// }
// /**
//  * Ensure that an up to date baseline csv is available in cache and
//  * return the data
//  */
// function getBaselineData(cacheFile) {
//   return __awaiter(this, void 0, void 0, function* () {
//     if (yield u.cache.isInCache(cacheFile)) {
//       let seasons = (yield u.cache.readFromCache(cacheFile))[0].map(d => parseInt(d.split('/')[0]));
//       if (seasons.indexOf(u.epiweek.currentSeasonId()) === -1) {
//         console.log('Baseline file not valid, downloading...');
//         yield downloadBaseline(cacheFile);
//       }
//     } else {
//       console.log('Baseline file not found, downloading...');
//       yield downloadBaseline(cacheFile);
//     }
//     return yield u.cache.readFromCache(cacheFile);
//   });
// }
// /**
//  * Return baseline value
//  */
// function getBaseline(state, season) {
//   return __awaiter(this, void 0, void 0, function* () {
//     let data = yield getBaselineData('wILI_Baseline.csv');
//     let stateCsvName = meta_1.stateFullName[state].split(' ').slice(1).join('');
//     let seasonCsvName = `${season}/${season + 1}`;
//     let colIdx = data[0].indexOf(seasonCsvName);
//     return data.find(row => row[0] === stateCsvName)[colIdx];
//   });
// }
// exports.getBaseline = getBaseline;
/**
 * Return season data for the given lag value (or latest). Return value is an
 * object keyed by state ids having a list of { epiweek, wili } items as values
 */

function allKeysToUpperCase(obj) {
  var i;
  var output = {};
  for (i in obj) {
    output[i.toUpperCase()] = obj[i];
  }
  return output;
}

function getSeasonData(season, lag) {
  return __awaiter(this, void 0, void 0, function* () {
    let lagId = lag === undefined ? 'latest' : lag;
    let cacheFile = `seasondata-${season}-lag-${lagId}-${u.epiweek.currentEpiweek()}.json`;
    // if (yield u.cache.isInCache(cacheFile)) {
    //   return yield u.cache.readFromCache(cacheFile);
    // } else {
    //let data = yield delphi.requestSeasonData(season, lag);
    let data = yield readJSON(('covid-csv-tools/dist/truth/'.concat(season, '.json')).toString())

    // if (data.message === 'success') { 
    let formattedData = data
      .sort((a, b) => a.epiweek - b.epiweek)
      .reduce((acc, {
        epiweek,
        location,
        value
      }) => {
        acc[location] = acc[location] || [];
        acc[location].push({
          epiweek,
          value
        });
        return acc;
      }, {});

    formattedData = rename(formattedData, function (key) {
      if (key === 'value') return 'wili';
      return key;
    })
    yield u.cache.writeInCache(cacheFile, JSON.stringify(formattedData));
    return formattedData;
    // } else {
    //   console.log(`Warning: Delphi api says "${data.message}" for ${season}, lag ${lagId}.`);
    //   return null;
    // }
    // }
  });
}
exports.getSeasonData = getSeasonData;
/**
 * Same as getSeasonDataLatestLag but works on a list of seasons and return
 * Promise.all value
 */
function getSeasonsData(seasons, lag) {
  return Promise.all(seasons.map(s => getSeasonData(s, lag)));
}
exports.getSeasonsData = getSeasonsData;
/**
 * Return season data for all the lag values from 0 to 52. Return value is an object keyed
 * by state ids having a list of { epiweek, wili, { lagData: [{ lag, wili } ...] }} items
 * as values
 */
function getSeasonDataAllLags(season) {
  return __awaiter(this, void 0, void 0, function* () {
    let lags = [...Array(52).keys()];
    let latestData = (yield getSeasonData(season));
    let lagData = yield Promise.all(lags.map(l => getSeasonData(season, l)));

    meta_1.stateIds.forEach(rid => {
      latestData[rid].forEach(({
        epiweek,
        wili
      }, idx) => {
        let lagValues = lagData
          .filter(d => d)
          .map((ld, idx) => {
            let lagItem;
            if (ld[rid])
              lagItem = ld[rid].find(d => d.epiweek === epiweek);
            return lagItem ? {
              epiweek: lagItem.epiweek,
              wili: lagItem.wili,
              lag: lags[idx]
            } : null;
          })
          .filter(d => d)
          .sort((a, b) => b.lag - a.lag)
          .map(({
            lag,
            wili
          }) => {
            return {
              lag,
              wili
            };
          });
        latestData[rid][idx] = {
          epiweek,
          wili,
          lagData: lagValues
        };
      });
    });
    return latestData;
  });
}
exports.getSeasonDataAllLags = getSeasonDataAllLags;
/**
 * Return peak and peak-wk after checking if we have all available data for the season
 */
function parsePeak(ewPairs, allEpiweeks) {
  // Check if we have all the weeks available
  if (arrayEqual(ewPairs.map(ew => ew.epiweek).sort((a, b) => a - b), allEpiweeks)) {
    let peak = Math.max(...ewPairs.map(ew => ew.wili));
    return {
      peak,
      'peak-wk': ewPairs.find(ew => ew.wili === peak).epiweek
    };
  } else {
    return {
      peak: null,
      'peak-wk': null
    };
  }
}
/**
 * Return onset week
 * TODO: Verify that this is correct
 */
function parseOnset(ewPairs, baseline) {
  let onset = null;
  let carry = 0;
  for (let ew of ewPairs) {
    if (ew.wili >= baseline) {
      if (carry === 0) {
        onset = ew.epiweek;
      }
      carry += 1;
    } else {
      carry = 0;
    }
    if (carry >= 3) {
      return onset;
    }
  }
  return onset;
}
/**
 * Return nAhead week ahead truth value starting at startAt
 */
function parseWeekAhead(ewPairs, startAt, nAhead) {
  let futureEpiweek = u.epiweek.epiweekWithDiff(startAt, nAhead);
  let futureEw = ewPairs.find(({
    epiweek
  }) => epiweek === futureEpiweek);
  return futureEw ? futureEw.wili : null;
}
/**
 * Find true target values for given season. Return a promise of an object keyed by state
 * id having a list of { target: truth } items
 */
function getSeasonTruth(season, lag) {
  return __awaiter(this, void 0, void 0, function* () {
    let seasonData = yield getSeasonData(season, lag);
    // If we need truth for a past season, we also need to collect data for the
    // one season ahead to account for the week head values for the last few weeks
    // This is mosty probably not going to be costly, so we collect the whole next
    // season data and jam it to the current season
    let nextSeasonData;
    let seasonCSV = 2019;
    if (seasonData && (seasonCSV < u.epiweek.currentSeasonId())) {
      nextSeasonData = yield getSeasonData(seasonCSV + 1, lag);
    }
    let allEpiweeks = u.epiweek.seasonEpiweeks(seasonCSV);
    let truth = {};
    for (let state of meta_1.stateIds) {
      let stateSub = seasonData ? seasonData[state] : [];
      let stateSubExtension = nextSeasonData ? nextSeasonData[state] : [];
      truth[state] = [];
      // Find truth for seasonal targets
      let statePeak = parsePeak(stateSub, allEpiweeks);
      //let baseline = yield getBaseline(state, season);
      //let stateOnset = parseOnset(stateSub, baseline);
      for (let epiweek of allEpiweeks) {
        truth[state].push(Object.assign({
          epiweek,
          '1-ahead': parseWeekAhead(stateSub.concat(stateSubExtension), epiweek, 1),
          '2-ahead': parseWeekAhead(stateSub.concat(stateSubExtension), epiweek, 2),
          '3-ahead': parseWeekAhead(stateSub.concat(stateSubExtension), epiweek, 3),
          '4-ahead': parseWeekAhead(stateSub.concat(stateSubExtension), epiweek, 4)
          // 'onset-wk': stateOnset
        }, statePeak));
      }
    }
    return truth;
  });
}
exports.getSeasonTruth = getSeasonTruth;
//# sourceMappingURL=truth.js.map