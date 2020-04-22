/**
 * Tell if the file is present in cache
 */
export declare function isInCache(cacheFile: string): Promise<boolean>;
/**
 * Return data read from cache for the given filename
 */
export declare function readFromCache(cacheFile: string): Promise<any>;
/**
 * Write the provided data in cacheFile
 */
export declare function writeInCache(cacheFile: string, data: string): Promise<string>;
