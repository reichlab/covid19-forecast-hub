"use strict";
/**
 * Module for verifying csvs
 */
Object.defineProperty(exports, "__esModule", {
  value: true
});
const meta_1 = require("./meta");
const assert = require("assert");
const almostEqual = require("almost-equal");
const arrayEqual = require("array-equal");
const u = require("./utils");
/**
 * Check whether the point predictions are alright
 */
function verifyPoint(csv) {
  meta_1.targetIds.forEach(target => {
    meta_1.stateIds.forEach(state => {
      let bins = csv.getBins(target, state);
      let point = csv.getPoint(target, state);
      assert(almostEqual(point, u.bins.inferPoint(bins), almostEqual.FLT_EPSILON), `Point for target ${target}, state ${state} should be equal to inferred.`);
    });
  });
}
exports.verifyPoint = verifyPoint;
/**
 * Check where the headers match the default (in lower case)
 */
function verifyHeaders(csv) {
  assert(arrayEqual(csv.headers.map(h => h.toLowerCase()), meta_1.headers));
}
exports.verifyHeaders = verifyHeaders;
/**
 * Verify that the probabilities in csv sum to one
 */
function verifyProbabilities(csv) {
  meta_1.targetIds.forEach(target => {
    meta_1.stateIds.forEach(state => {
      let probabilities = csv.getBins(target, state).map(b => b[2]);
      assert(almostEqual(probabilities.reduce((x, y) => x + y), 1.0, almostEqual.FLT_EPSILON), `Probabilities for target ${target}, state ${state} should sum to 1.0`);
    });
  });
}
exports.verifyProbabilities = verifyProbabilities;
//# sourceMappingURL=verify.js.map