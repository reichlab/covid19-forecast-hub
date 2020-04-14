"use strict";
/**
 * Module to collect data from delphi epidata API (https://github.com/cmu-delphi/delphi-epidata)
 */
Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * Doc guard
 */
const rp = require("request-promise-native");
const buildUrl = require("build-url");
const meta_1 = require("./meta");
/**
 * Root url for the delphi API
 */
const API_ROOT = 'https://delphi.midas.cs.cmu.edu/epidata/api.php/';
/**
 * Build url for API request. The url represents a request for all weeks
 * in a single epidemic season, all states and single lag value.
 * Lag can be skipped if needing latest issue (with max lag value)
 */
function getSeasonRequestUrl(season, lag) {
  let url = buildUrl(API_ROOT, {
    queryParams: {
      epiweeks: `${season * 100 + 40}-${(season + 1) * 100 + 39}`,
      source: 'nowcast',
      locations: meta_1.stateIds
    }
  });
  return lag !== undefined ? `${url}&lag=${lag}` : url;
}
/**
 * Return a promise with data from delphi epidata API
 * Note that the API only allows 3650 items for each request
 * (https://github.com/cmu-delphi/delphi-epidata/issues/1#issuecomment-308502781)
 * Collecting data for a season (with one lag value) with all states amounts
 * to max of 520 results
 */
function requestSeasonData(season, lag) {
  return rp({
    uri: getSeasonRequestUrl(season, lag),
    json: true
  });
}
exports.requestSeasonData = requestSeasonData;
//# sourceMappingURL=delphi.js.map