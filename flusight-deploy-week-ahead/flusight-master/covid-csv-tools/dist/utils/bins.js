"use strict";
/**
 * Module for working with Bins
 */
Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * Doc guard
 */
const almostEqual = require("almost-equal");
const meta_1 = require("../meta");
/**
 * Tell whether the bins represent
 */
function isUniform(bins) {
  // Skip the last bin which is sometimes different since that bin contains, e.g.
  // all wili values from 13 to 100
  return bins.slice(0, bins.length - 1).every(bin => almostEqual(bin[2], bins[0][2], almostEqual.FLT_EPSILON));
}
exports.isUniform = isUniform;
/**
 * Infer point probability value for the bins
 */
function inferPoint(bins) {
  if (isUniform(bins)) {
    return bins[Math.floor(bins.length / 2)][0];
  } else {
    let pointBin = bins.reduce((acc, item) => {
      return (acc[2] < item[2]) ? item : acc;
    }, bins[0]);
  }
}
exports.inferPoint = inferPoint;
/**
 * Reduce the bins by summing probabilities for batches.
 */
function sliceSumBins(bins, batch) {
  return bins.reduce((acc, bin, idx) => {
    let sIdx = Math.floor(idx / batch);
    if (acc[sIdx]) {
      acc[sIdx][2] += bin[2];
      acc[sIdx][1] = bin[1];
    } else {
      acc.push(bin.slice());
    }
    return acc;
  }, []);
}
exports.sliceSumBins = sliceSumBins;
/**
 * Sort bins appropriately using the target information
 */
function sortBins(bins, target) {
  // Extract none value separately and push it in the end
  let noneVal = null;
  bins = bins.sort();
  if (noneVal !== null)
    bins.push([null, null, noneVal]);
  return bins;
}
exports.sortBins = sortBins;
/**
 * Return bin index in which the given value lies. Assume bins are properly sorted.
 * `value` can be null, in which case we look for the last bin (which is onset bin).
 */
function findBinIndex(bins, value, target) {
  let tolerance = 0.000000001;
  let binType = meta_1.targetType[target];
  let notFoundError = new Error('Bin value not found');
  if (binType === 'week') {
    // We are looking for none bin of onset
    if (value === null) {
      if (bins[bins.length - 1][0] === null) {
        return bins.length - 1;
      } else {
        throw notFoundError;
      }
    }
    // Truncating tail if it gets in somehow
    value = Math.floor(value);
    // For week case, we just need to search the bin starts
    let binIdx = bins.findIndex(b => almostEqual(b[0], value, tolerance));
    if (binIdx > -1) {
      return binIdx;
    } else {
      throw notFoundError;
    }
  } else if (binType === 'percent') {
    // Find bin range for rejecting values
    let binMin = bins[0][0];
    let binMax = (bins[bins.length - 1][0] === null) ? bins[bins.length - 2][1] : bins[bins.length - 1][1];
    if (((value - (binMin - tolerance)) < 0) ||
      ((value - (binMax + tolerance)) > 0)) {
      throw notFoundError;
    }
    for (let i = 0; i < bins.length; i++) {
      if (almostEqual(bins[i][1], value, tolerance)) {
        // Its the next bin
        continue;
      } else {
        if (((bins[i][1] - (value - tolerance)) > 0) ||
          (almostEqual(bins[i][1], (value - tolerance), tolerance))) {
          return i;
        }
      }
    }
  }
  // In unexpected situation
  throw notFoundError;
}
exports.findBinIndex = findBinIndex;
/**
 * Return bin in which the given value lies. Assume bins are properly sorted.
 * `value` can be null, in which case we look for the last bin (which is onset bin).
 */
function findBin(bins, value, target) {
  return bins[findBinIndex(bins, value, target)];
}
exports.findBin = findBin;
/**
 * Return bins to consider as neighbours for the bin at given index
 * This follows the CDC FluSight guideline for considering the neighbouring bins
 */
function expandBin(bins, index, target) {
  function getBinsInWindow(windowSize) {
    return bins.filter((_, idx) => (idx >= (index - windowSize)) && (idx <= (index + windowSize)));
  }
  let binType = meta_1.targetType[target];
  if (binType === 'week') {
    if (bins[index][0] === null) {
      // We don't return anyone else in case of onset
      return [bins[index]];
    } else {
      return getBinsInWindow(1);
    }
  } else if (binType === 'percent') {
    if (bins.length === 27) {
      // These are old style bins, only use a neighbour size of 1
      return getBinsInWindow(1);
    } else {
      return getBinsInWindow(5);
    }
  } else {
    throw new Error('Unknown bin type found while expanding');
  }
}
exports.expandBin = expandBin;
//# sourceMappingURL=bins.js.map