import { SeasonId } from './interfaces';
/**
 * Return a promise with data from delphi epidata API
 * Note that the API only allows 3650 items for each request
 * (https://github.com/cmu-delphi/delphi-epidata/issues/1#issuecomment-308502781)
 * Collecting data for a season (with one lag value) with all regions amounts
 * to max of 520 results
 */
export declare function requestSeasonData(season: SeasonId, lag?: number): Promise<any>;
