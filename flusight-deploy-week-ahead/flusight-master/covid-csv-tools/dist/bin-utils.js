"use strict";
// Module for working with Bins
Object.defineProperty(exports, "__esModule", { value: true });
const almostEqual = require("almost-equal");
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
    }
    else {
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
        }
        else {
            acc.push(bin);
        }
        return acc;
    }, []);
}
exports.sliceSumBins = sliceSumBins;
//# sourceMappingURL=bin-utils.js.map