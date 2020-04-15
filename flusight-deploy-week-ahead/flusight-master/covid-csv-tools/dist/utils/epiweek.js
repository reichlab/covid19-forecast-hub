"use strict";
/**
 * Epiweek and time related functions
 */
Object.defineProperty(exports, "__esModule", {
  value: true
});
const mmwr = require("mmwr-week");
const moment = require("moment");
/**
 * Convert given week and season to epiweek, handle non standard values too
 */
function weekToEpiweek(week, seasonId) {
  // If null, return it directly since that might refer to None onset week
  if (week === null ||
    week === undefined ||
    isNaN(week) ||
    week.toString() === 'none')
    return null;
  // Convert the point predictions to int first
  week = Math.floor(week);
  let nWeeks = (new mmwr.MMWRDate(seasonId)).nWeeks;
  // Wrap around values
  if (week > nWeeks) {
    week = week % nWeeks;
  }
  if (week === 0) {
    // We go back to the last value from past season
    return seasonId * 100 + nWeeks;
  } else if (week >= 52) {
    return seasonId * 100 + week;
  } else {
    return (seasonId + 1) * 100 + week;
  }
}
exports.weekToEpiweek = weekToEpiweek;
/**
 * Return current epiweek
 */
function currentEpiweek() {
  let mdate = new mmwr.MMWRDate(0);
  mdate.fromMomentDate(moment());
  return mdate.year * 100 + mdate.week;
}
exports.currentEpiweek = currentEpiweek;
/**
 * Return seasons for given epiweek. Assume seasons start from
 * mmwr-week 520 and end on next year's week 29
 */
function seasonFromEpiweek(epiweek) {
  let year = Math.trunc(epiweek / 100);
  return (epiweek % 100 >= 52) ? year : year - 1;
}
exports.seasonFromEpiweek = seasonFromEpiweek;
/**
 * Return epiweek with diff number of weeks added
 */
function epiweekWithDiff(epiweek, diff) {
  let mdate = new mmwr.MMWRDate(0);
  mdate.fromEpiweek(epiweek);
  mdate.applyWeekDiff(diff);
  return mdate.toEpiweek();
}
exports.epiweekWithDiff = epiweekWithDiff;
/**
 * Return equivalent of first - second in epiweek scale
 */
function getEpiweekDiff(first, second) {
  let firstDate = new mmwr.MMWRDate(0);
  let secondDate = new mmwr.MMWRDate(0);
  firstDate.fromEpiweek(first);
  secondDate.fromEpiweek(second);
  return firstDate.diffWeek(secondDate);
}
exports.getEpiweekDiff = getEpiweekDiff;
/**
 * Return id for current season
 */
function currentSeasonId() {
  return seasonFromEpiweek(currentEpiweek());
}
exports.currentSeasonId = currentSeasonId;
/**
 * Return a list of epiweeks in the season provided
 */
function seasonEpiweeks(season) {
  let arange = (a, b) => [...Array(b - a).keys()].map(i => i + a);
  let maxWeek = (new mmwr.MMWRDate(season, 52)).nWeeks;
  return [
    ...arange(100 * season + 52, 100 * season + maxWeek + 1),
    ...arange(100 * (season + 1) + 1, 100 * (season + 1) + 52)
  ];
}
exports.seasonEpiweeks = seasonEpiweeks;
//# sourceMappingURL=epiweek.js.map