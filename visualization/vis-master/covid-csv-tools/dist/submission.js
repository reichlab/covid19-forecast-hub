"use strict";
Object.defineProperty(exports, "__esModule", {
  value: true
});
const meta_1 = require("./meta");
const Papa = require("papaparse");
const d3 = require("d3-collection");
const fs = require("fs-extra");
class Submission {
  /**
   * Initialize a submission object
   */
  constructor(filePath, epiweek, model) {
    this.filePath = filePath;
    this.epiweek = epiweek;
    this.model = model;
    this.readCsv();
  }
  /**
   * Parse and read the csv
   */
  readCsv() {
    let csvData = Papa.parse(fs.readFileSync(this.filePath, 'utf8'), {
      dynamicTyping: true
    }).data;
    this.headers = csvData[0];
    this.data = d3.nest()
      .key(d => d[0]) // state
      .key(d => d[1]) // target
      .object(csvData.slice(1).filter(d => !(d.length === 1 && d[0] === '')));
  }
  /**
   * Return a point value for given target and state. The value is taken
   * directly from the csv without trying to infer it from bins. The verification
   * module takes care of checking where the provided point value matches with the
   * inferred value.
   */
  getPoint(target, state) {
    return this.data[meta_1.stateFullName[state]][meta_1.targetFullName[target]]
      .find(row => row[2] == 'Point')[6];
  }
  /**
   * Return an array of bin values for given target and state.
   */
  getBins(target, state) {
    let bins = this.data[meta_1.stateFullName[state]][meta_1.targetFullName[target]]
      .filter(row => row[2] == 'Bin')
      .map(row => [row[4], row[5], row[6]]); // bin start, bin end, value
    let comparePercentage = (a, b) => a - b;
    let compareWeeks = (a, b) => {
      if ((a >= 40) && (b < 40)) {
        return -1;
      } else if ((a < 40) && (b >= 40)) {
        return 1;
      } else {
        return a - b;
      }
    };
    // TODO Handle none bin of onset properly
    if (target === 'onset-wk') {
      process.emitWarning('Removing none bin from onset');
      bins = bins.filter(row => row[0] !== 'none');
    }
    return bins.sort(meta_1.targetType[target] === 'percent' ? comparePercentage : compareWeeks);
  }
  /**
   * Return low and high bin values for the given confidence (in percent) and target, state pair.
   */
  getConfidenceRange(target, state, ciPercent = 90) {
    let ciTrim = 0.5 - (ciPercent / 200);
    let bins = this.getBins(target, state);
    let pAccum = {
      low: 0,
      high: 0
    };
    let low, high;
    for (let i = 0; i < bins.length; i++) {
      pAccum.low += bins[i][2];
      pAccum.high += bins[bins.length - i - 1][2];
      if ((pAccum.low > ciTrim) && (!low)) {
        low = bins[i][0];
      }
      if ((pAccum.high > ciTrim) && (!high)) {
        high = bins[bins.length - i - 1][1];
      }
    }
    return [low, high];
  }
}
exports.default = Submission;
//# sourceMappingURL=submission.js.map