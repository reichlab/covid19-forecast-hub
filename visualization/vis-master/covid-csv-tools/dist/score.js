"use strict";
/**
 * Module for scoring related functions
 */
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
const moize_1 = require("moize");
const truth = require("./truth");
const u = require("./utils");
const meta_1 = require("./meta");
/**
 * Memoized version of getSeasonTruth since there will be a lot of
 * csvs with the same season
 */
const getSeasonTruthMem = moize_1.default(truth.getSeasonTruth, {
  isPromise: true
});
/**
 * Aggregate the scores by taking mean
 */
function meanScores(scores) {
  let meanScores = {};
  for (let state of meta_1.stateIds) {
    meanScores[state] = {};
    for (let target of meta_1.targetIds) {
      meanScores[state][target] = {};
      for (let scoreId of meta_1.scoreIds) {
        if (scoreId === 'error') {
          // Return null since mean of error is useless
          meanScores[state][target][scoreId] = null;
        } else {
          let scoreValues = scores.map(s => s[state][target][scoreId]).filter(s => s !== null);
          meanScores[state][target][scoreId] = scoreValues.reduce((a, b) => a + b, 0);
          meanScores[state][target][scoreId] /= scoreValues.length;
        }
      }
    }
  }
  return meanScores;
}
exports.meanScores = meanScores;
/**
 * Return scores for all the states and targets in the csv
 */
function score(csv, lag) {
  return __awaiter(this, void 0, void 0, function* () {
    let seasonTruth = yield getSeasonTruthMem(csv.target, lag);
    let scores = {};
    for (let state of meta_1.stateIds) {
      scores[state] = {};
      let trueValues = seasonTruth[state].find(({
        epiweek
      }) => csv.epiweek === epiweek);
      for (let target of meta_1.targetIds) {
        let trueValue = trueValues[target];
        if ((target !== 'onset-wk') && (trueValue === null)) {
          // Only onset-wk can have null true value
          scores[state][target] = {
            logScore: null,
            logScoreMultiBin: null,
            error: null,
            absError: null
          };
        } else {
          let pointEstimate = csv.getPoint(target, state);
          let bins = csv.getBins(target, state);
          let error;
          let trueProbability;
          let expandedTrueProbability;
          try {
            let trueBinIndex = u.bins.findBinIndex(bins, trueValue, target);
            trueProbability = bins[trueBinIndex][2];
            expandedTrueProbability = u.bins.expandBin(bins, trueBinIndex, target)
              .reduce((acc, b) => acc + b[2], 0);
          } catch (e) {
            // Error in finding true bin, leaving probability as null
            trueProbability = null;
            expandedTrueProbability = null;
          }
          let logScore = trueProbability !== null ? Math.log(trueProbability) : null;
          let logScoreMultiBin = expandedTrueProbability !== null ? Math.log(expandedTrueProbability) : null;
          if (meta_1.targetType[target] === 'percent') {
            error = pointEstimate !== null ? trueValue - pointEstimate : null;
          } else if (meta_1.targetType[target] === 'week') {
            if (trueValue === null) {
              // This is onset target with none bin as the truth
              if (pointEstimate === null) {
                error = 0;
              } else {
                error = -Infinity;
              }
            } else {
              if (pointEstimate === null) {
                error = -Infinity;
              } else {
                error = u.epiweek.getEpiweekDiff(trueValue, pointEstimate);
              }
            }
          }
          scores[state][target] = {
            logScore,
            logScoreMultiBin,
            error,
            absError: Math.abs(error)
          };
        }
      }
    }
    return scores;
  });
}
exports.score = score;
//# sourceMappingURL=score.js.map