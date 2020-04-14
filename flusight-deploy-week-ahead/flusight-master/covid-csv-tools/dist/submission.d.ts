import { Bin, RegionId, TargetId, Epiweek } from './interfaces';
export default class Submission {
    readonly epiweek: Epiweek;
    readonly model: string;
    readonly filePath: string;
    headers: string[];
    data: any;
    /**
     * Initialize a submission object
     */
    constructor(filePath: string, epiweek: Epiweek, model: string);
    /**
     * Parse and read the csv
     */
    private readCsv();
    /**
     * Return a point value for given target and region. The value is taken
     * directly from the csv without trying to infer it from bins. The verification
     * module takes care of checking where the provided point value matches with the
     * inferred value.
     */
    getPoint(target: TargetId, region: RegionId): number;
    /**
     * Return an array of bin values for given target and region.
     */
    getBins(target: TargetId, region: RegionId): Bin[];
    /**
     * Return low and high bin values for the given confidence (in percent) and target, region pair.
     */
    getConfidenceRange(target: TargetId, region: RegionId, ciPercent?: number): [number, number];
}
