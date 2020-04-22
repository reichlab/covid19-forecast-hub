/**
 * Metadata and mappings from abbreviations to corresponding text in csv
 */
/**
 * Doc guard
 */
import { RegionId, TargetId } from './interfaces';
/**
 * The headers expected in the csv files
 */
export declare const headers: string[];
/**
 * Short ids representing a region in the code.
 */
export declare const regionIds: RegionId[];
/**
 * Short ids representing a target in the code.
 */
export declare const targetIds: TargetId[];
/**
 * Short ids representing a score in the code.
 */
export declare const scoreIds: string[];
/**
 * Mapping from target ids to full name as used in the csvs
 */
export declare const targetFullName: {
    '1-ahead': string;
    '2-ahead': string;
    '3-ahead': string;
    '4-ahead': string;
    'peak': string;
    'peak-wk': string;
    'onset-wk': string;
};
/**
 * Target type for each target. Note that there can be only two
 * target types, 'percent' and 'week'.
 */
export declare const targetType: {
    '1-ahead': string;
    '2-ahead': string;
    '3-ahead': string;
    '4-ahead': string;
    'peak': string;
    'peak-wk': string;
    'onset-wk': string;
};
/**
 * Mapping from region ids to full region name as used in
 * the csvs
 */
export declare const regionFullName: {
    'nat': string;
    'hhs1': string;
    'hhs2': string;
    'hhs3': string;
    'hhs4': string;
    'hhs5': string;
    'hhs6': string;
    'hhs7': string;
    'hhs8': string;
    'hhs9': string;
    'hhs10': string;
};
/**
 * List of US state abbreviations
 */
export declare const stateIds: string[];
/**
 * Mapping from region ids to the states in those regions
 */
export declare const regionStates: {
    'nat': string[];
    'hhs1': string[];
    'hhs2': string[];
    'hhs3': string[];
    'hhs4': string[];
    'hhs5': string[];
    'hhs6': string[];
    'hhs7': string[];
    'hhs8': string[];
    'hhs9': string[];
    'hhs10': string[];
};
