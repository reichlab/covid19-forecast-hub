/**
 * Module for scoring related functions
 */
/**
 * Doc guard
 */
import Csv from './csv';
import { Score, RegionTargetIndex } from './interfaces';
/**
 * Aggregate the scores by taking mean
 */
export declare function meanScores(scores: RegionTargetIndex<Score>[]): RegionTargetIndex<Score>;
/**
 * Return scores for all the regions and targets in the csv
 */
export declare function score(csv: Csv, lag?: number): Promise<RegionTargetIndex<Score>>;
