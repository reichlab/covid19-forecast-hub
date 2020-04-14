/**
 * Epiweek and time related functions
 */
/**
 * Doc guard
 */
import { SeasonId, Epiweek } from '../interfaces';
/**
 * Convert given week and season to epiweek, handle non standard values too
 */
export declare function weekToEpiweek(week: number, seasonId: SeasonId): Epiweek;
/**
 * Return current epiweek
 */
export declare function currentEpiweek(): Epiweek;
/**
 * Return seasons for given epiweek. Assume seasons start from
 * mmwr-week 30 and end on next year's week 29
 */
export declare function seasonFromEpiweek(epiweek: Epiweek): SeasonId;
/**
 * Return epiweek with diff number of weeks added
 */
export declare function epiweekWithDiff(epiweek: Epiweek, diff: number): Epiweek;
/**
 * Return equivalent of first - second in epiweek scale
 */
export declare function getEpiweekDiff(first: Epiweek, second: Epiweek): number;
/**
 * Return id for current season
 */
export declare function currentSeasonId(): SeasonId;
/**
 * Return a list of epiweeks in the season provided
 */
export declare function seasonEpiweeks(season: SeasonId): Epiweek[];
