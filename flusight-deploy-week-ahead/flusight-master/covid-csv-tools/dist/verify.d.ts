/**
 * Module for verifying csvs
 */
/**
 * Doc guard
 */
import Csv from './csv';
/**
 * Check whether the point predictions are alright
 */
export declare function verifyPoint(csv: Csv): void;
/**
 * Check where the headers match the default (in lower case)
 */
export declare function verifyHeaders(csv: Csv): void;
/**
 * Verify that the probabilities in csv sum to one
 */
export declare function verifyProbabilities(csv: Csv): void;
