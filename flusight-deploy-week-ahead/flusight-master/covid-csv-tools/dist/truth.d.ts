/**
 * Module for working with truth related data
 */
/**
 * Doc guard
 */
import { SeasonId, RegionId, EpiweekWili, EpiweekWiliLag } from './interfaces';
/**
 * Return baseline value
 */
export declare function getBaseline(region: RegionId, season: SeasonId): Promise<number>;
/**
 * Return season data for the given lag value (or latest). Return value is an
 * object keyed by region ids having a list of { epiweek, wili } items as values
 */
export declare function getSeasonData(season: SeasonId, lag?: number): Promise<{
    [R in RegionId]: EpiweekWili[];
}>;
/**
 * Same as getSeasonDataLatestLag but works on a list of seasons and return
 * Promise.all value
 */
export declare function getSeasonsData(seasons: SeasonId[], lag?: number): Promise<{
    [R in RegionId]: EpiweekWili[];
}[]>;
/**
 * Return season data for all the lag values from 0 to 52. Return value is an object keyed
 * by region ids having a list of { epiweek, wili, { lagData: [{ lag, wili } ...] }} items
 * as values
 */
export declare function getSeasonDataAllLags(season: SeasonId): Promise<{
    [R in RegionId]: EpiweekWiliLag[];
}>;
/**
 * Find true target values for given season. Return a promise of an object keyed by region
 * id having a list of { target: truth } items
 */
export declare function getSeasonTruth(season: SeasonId, lag?: number): Promise<{
    [index: string]: {
        [index: string]: number;
    }[];
}>;
