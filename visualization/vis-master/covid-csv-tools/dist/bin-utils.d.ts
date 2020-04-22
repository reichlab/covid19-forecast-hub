import { Bin } from './interfaces';
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
