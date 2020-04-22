/**
 * Module for csv reading functionality
 */
/**
 * Doc guard
 */
import { Bin, RegionId, TargetId, Epiweek, SeasonId } from './interfaces';
/**
 * Class representing a CSV file
 */
export default class CSV {
    readonly epiweek: Epiweek;
    readonly season: SeasonId;
    readonly model: string;
    readonly filePath: string;
    headers: string[];
    private bins;
    private points;
    /**
     * Initialize the csv with filename and some metadata
     */
    constructor(filePath: string, epiweek: Epiweek, model: string);
    /**
     * Convert week to epiweek using this csv's season
     */
    private weekToEpiweek(week);
    /**
     * Parse and read the csv
     */
    private parseCsv();
    /**
     * Parse bin data for all the regions and targets
     */
    private parseBins(csvData);
    /**
     * Return an array of bin values for given target and region.
     */
    getBins(target: TargetId, region: RegionId): Bin[];
    /**
     * Parse point data for all the region and targets
     */
    private parsePoints(csvData);
    /**
     * Return a point value for given target and region
     */
    getPoint(target: TargetId, region: RegionId): number;
    /**
     * Return low and high bin values for the given confidence (in percent) and target, region pair.
     */
    getConfidenceRange(target: TargetId, region: RegionId, ciPercent?: number): [number, number];
}
