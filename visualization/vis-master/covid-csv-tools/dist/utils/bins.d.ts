import { Bin, TargetId } from '../interfaces';
/**
 * Tell whether the bins represent
 */
export declare function isUniform(bins: Bin[]): boolean;
/**
 * Infer point probability value for the bins
 */
export declare function inferPoint(bins: Bin[]): number;
/**
 * Reduce the bins by summing probabilities for batches.
 */
export declare function sliceSumBins(bins: Bin[], batch: number): Bin[];
/**
 * Sort bins appropriately using the target information
 */
export declare function sortBins(bins: Bin[], target: TargetId): Bin[];
/**
 * Return bin index in which the given value lies. Assume bins are properly sorted.
 * `value` can be null, in which case we look for the last bin (which is onset bin).
 */
export declare function findBinIndex(bins: Bin[], value: number, target: TargetId): number;
/**
 * Return bin in which the given value lies. Assume bins are properly sorted.
 * `value` can be null, in which case we look for the last bin (which is onset bin).
 */
export declare function findBin(bins: Bin[], value: number, target: TargetId): Bin;
/**
 * Return bins to consider as neighbours for the bin at given index
 * This follows the CDC FluSight guideline for considering the neighbouring bins
 */
export declare function expandBin(bins: Bin[], index: number, target: TargetId): Bin[];
