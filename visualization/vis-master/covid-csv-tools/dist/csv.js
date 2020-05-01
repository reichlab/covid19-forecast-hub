"use strict";
/**
 * Module for csv reading functionality
 */
Object.defineProperty(exports, "__esModule", {
  value: true
});
const meta_1 = require("./meta");
const u = require("./utils");
const Papa = require("papaparse");
const d3 = require("d3-collection");
const fs = require("fs-extra");
/**
 * Class representing a CSV file
 */
class CSV {
  /**
   * Initialize the csv with filename and some metadata
   */
  constructor(filePath, epiweek, model, target) {
    this.filePath = filePath;
    this.epiweek = epiweek;
    this.model = model;
    this.target = target;
    this.season = u.epiweek.seasonFromEpiweek(epiweek)
    this.parseCsv();
  }
  /**
   * Convert week to epiweek using this csv's season
   */
  weekToEpiweek(week) {
    return u.epiweek.weekToEpiweek(week, this.season);
  }
  /**
   * Parse and read the csv
   */
  parseCsv() {
    let csvRows = Papa.parse(fs.readFileSync(this.filePath, 'utf8'), {
      dynamicTyping: true
    }).data;
    this.headers = csvRows[0];
    let csvData = d3.nest()
      .key(d => d[0]) // state
      .key(d => d[1]) // target
      .object(csvRows.slice(1).filter(d => !(d.length === 1 && d[0] === '')));
    this.parseQuantiles(csvData);
    this.parsePoints(csvData);
  }
  /**
   * Parse bin data for all the states and targets
   */
  parseBins(csvData) {
    this.bins = {};
    for (let state of meta_1.stateIds) {
      this.bins[state] = {};
      for (let target of meta_1.targetIds) {
        try {
          let targetFullName = meta_1.targetFullNameInc[target]
          if (csvData[meta_1.stateFullName[state]][targetFullName] == undefined) {
            targetFullName = meta_1.targetFullNameCum[target]
          }
          let bins = csvData[meta_1.stateFullName[state]][targetFullName]
            .filter(row => row[2] == 'Bin')
            .map(row => [row[4], row[5], row[6]]); // bin start, bin end, value

          if (meta_1.targetType[target] === 'week') {
            // Convert the week values in bins to epiweek
            bins = bins.map(b => [this.weekToEpiweek(b[0]), this.weekToEpiweek(b[1]), b[2]]);
          }
          this.bins[state][target] = u.bins.sortBins(bins, target);
        } catch (err) {
          const errString = "Cannot find target "
          //console.log(errString.concat(target))
        }
      }
    }
  }
  /**
   * Parse bin data for all the states and targets
   */
  parseQuantiles(csvData) {
    this.bins = {};
    for (let state of meta_1.stateIds) {
      this.bins[state] = {};
      for (let target of meta_1.targetIds) {
        try {
          let targetFullName = meta_1.targetFullNameInc[target]
          if (csvData[meta_1.stateFullName[state]][targetFullName] == undefined) {
            targetFullName = meta_1.targetFullNameCum[target]
          }
          let bins = csvData[meta_1.stateFullName[state]][targetFullName]
            .filter(row => row[2] == 'quantile')
            .map(row => [row[4], row[5]]); // quantile, value
          this.bins[state][target] = u.bins.sortBins(bins, target);
        } catch (err) {
          const errString = "Cannot find target "
          //console.log(errString.concat(target))
        }
      }
    }
  }
  /**
   * Return an array of bin values for given target and state.
   */
  getBins(target, state) {
    return this.bins[state][target];
  }
  /**
   * Parse point data for all the state and targets
   */
  parsePoints(csvData) {
    this.points = {};
    for (let state of meta_1.stateIds) {
      this.points[state] = {};
      for (let target of meta_1.targetIds) {
        try {
          let targetFullName = meta_1.targetFullNameInc[target]
          if (csvData[meta_1.stateFullName[state]][targetFullName] == undefined) {
            targetFullName = meta_1.targetFullNameCum[target]
          }
          let point = csvData[meta_1.stateFullName[state]][targetFullName]
            .find(row => row[2] == 'point')[5];
          if (point === 'NA') {
            point = u.bins.inferPoint(this.getBins(target, state));
          }
          if (meta_1.targetType[target] === 'week') {
            // Transform the week target to epiweek
            point = this.weekToEpiweek(point);
          }
          this.points[state][target] = point;
        } catch (err) {
          const errString = "Cannot find target "
          //console.log(errString.concat(target))
        }
      }
    }
  }
  /**
   * Return a point value for given target and state
   */
  getPoint(target, state) {
    return this.points[state][target];
  }
  /**
   * Return low and high bin values for the given confidence (in percent) and target, state pair.
   */
  getConfidenceRange(target, state, ciPercent = 90) {
    //let ciTrim = 0.5 - (ciPercent / 200);
    let ciNum = (1 - (ciPercent / 100)) / 2;
    let roundedNum = Math.round(ciNum * 1000) / 1000;
    let ciLow = roundedNum;
    let ciHigh = 1 - roundedNum;
    let bins = this.getBins(target, state);
    let pAccum = {
      low: 0,
      high: 0
    };
    let low, high;
    try {
      for (let i = 0; i < bins.length; i++) {
        if (bins[i][0] == ciLow) {
          low = bins[i][1];
        }
        if (bins[i][0] == ciHigh) {
          high = bins[i][1];
        }
      }
      return [low, high];
    } catch (err) {
      //console.log("No bins for ".concat(target))
    }
  }
}
exports.default = CSV;
//# sourceMappingURL=csv.js.map