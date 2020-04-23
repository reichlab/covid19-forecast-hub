"use strict";
/**
 * Module with functions related to flusight-csv-tools cache
 */
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
  return new(P || (P = Promise))(function (resolve, reject) {
    function fulfilled(value) {
      try {
        step(generator.next(value));
      } catch (e) {
        reject(e);
      }
    }

    function rejected(value) {
      try {
        step(generator["throw"](value));
      } catch (e) {
        reject(e);
      }
    }

    function step(result) {
      result.done ? resolve(result.value) : new P(function (resolve) {
        resolve(result.value);
      }).then(fulfilled, rejected);
    }
    step((generator = generator.apply(thisArg, _arguments || [])).next());
  });
};
Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * Doc guard
 */
const Papa = require("papaparse");
const fs = require("fs-extra");
const path = require("path");
const appdirs_1 = require("appdirs");
/**
 * Cache directory path
 */
const CACHE_DIR = path.join(appdirs_1.userCacheDir(), 'covid-csv-tools');
/**
 * Tell if the file is present in cache
 */
function isInCache(cacheFile) {
  return __awaiter(this, void 0, void 0, function* () {
    yield fs.ensureDir(CACHE_DIR);
    return yield fs.pathExists(path.join(CACHE_DIR, cacheFile));
  });
}
exports.isInCache = isInCache;
/**
 * Read csv using papaparse
 */
function readCsv(filePath) {
  return __awaiter(this, void 0, void 0, function* () {
    return Papa.parse((yield fs.readFile(filePath, 'utf8')).trim(), {
      dynamicTyping: true
    }).data;
  });
}
/**
 * Read json from file
 */
function readJSON(filePath) {
  return __awaiter(this, void 0, void 0, function* () {
    return JSON.parse(yield fs.readFile(filePath, 'utf8'));
  });
}
/**
 * Return data read from cache for the given filename
 */
function readFromCache(cacheFile) {
  return __awaiter(this, void 0, void 0, function* () {
    let filePath = path.join(CACHE_DIR, cacheFile);
    if (filePath.endsWith('.json')) {
      return yield readJSON(filePath);
    } else if (filePath.endsWith('.csv')) {
      return yield readCsv(filePath);
    } else {
      throw Error('File type not understood');
    }
  });
}
exports.readFromCache = readFromCache;
/**
 * Write the provided data in cacheFile
 */
function writeInCache(cacheFile, data) {
  return __awaiter(this, void 0, void 0, function* () {
    yield fs.ensureDir(CACHE_DIR);
    yield fs.writeFile(path.join(CACHE_DIR, cacheFile), data);
    return cacheFile;
  });
}
exports.writeInCache = writeInCache;
//# sourceMappingURL=cache.js.map