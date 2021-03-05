/**
 * Script to parse and write data for a single season
 * This is supposed to be called in child processes via the main parse script
 */

const fs = require('fs-extra')
const path = require('path')
const utils = require('./utils')
const fct = require('../covid-csv-tools')
const moize = require('moize')

// Directory with CSVs
const DATA_DIR = './data'

// Directory for output JSONs
const OUT_DIR = './src/assets/data'

// Look for seasons in the data directory
const TARGETS = utils.getSubDirectories(DATA_DIR)

// Take input season from command line argument
const TARGET = process.argv[2].concat(" ".concat(process.argv[3]))
const SEASON_ID = parseInt(2019)
const SEASON = `${SEASON_ID}-${SEASON_ID + 1}`
const MODELS_DIR = utils.getSubDirectories(path.join(DATA_DIR, TARGET))

/**
 * Return season name for writing files
 */
function getSeasonName() {
  // if (TARGETS.indexOf(TARGET) === TARGETS.length - 1) {
  //   return 'latest'
  // } else {
  //   return TARGET
  // }
  if (TARGET === "Cumulative Deaths") {
    return 'latest'
  } else {
    return TARGET
  }

}

async function writeSeasonFile(data) {
  await utils.writeJSON(path.join(OUT_DIR, `season-${getSeasonName()}.json`), data)
}

async function writeScoresFile(data) {
  await utils.writeJSON(path.join(OUT_DIR, `scores-${getSeasonName()}.json`), data)
}

async function writeDistsFile(data, stateId) {
  let distsDir = path.join(OUT_DIR, 'distributions')
  await fs.ensureDir(distsDir)

  let outputFile
  if (stateId === 'nat') {
    // We only use latest identifier in the latest AND nat data
    outputFile = path.join(distsDir, `season-${getSeasonName()}-nat.json`)
  } else {
    outputFile = path.join(distsDir, `season-${TARGET}-${stateId}.json`)
  }

  await utils.writeJSON(outputFile, data)
}

/**
 * Return state data with nulls filled in for missing epiweeks
 */
function parseStateActual(seasonData, stateId) {
  let stateSubset = seasonData[stateId]
  let epiweeks = fct.utils.epiweek.seasonEpiweeks(SEASON_ID)
  // Remove the first 5 ew of 2019-2020 season because there is no data
  epiweeks = epiweeks.slice(5)
  // Temporary: expand to next 4 weeks while working on the main fix
  let epiweeks_next_year = fct.utils.epiweek.seasonEpiweeks(SEASON_ID+1)
  epiweeks_next_year_first_24_ew = epiweeks_next_year.slice(0, 24)
  epiweeks = epiweeks.concat(epiweeks_next_year_first_24_ew)
  return epiweeks.map(ew => {
    let ewData = stateSubset.find(({
      epiweek
    }) => epiweek === ew.toString())
    // Rename keys to match the expectations of flusight
    // and extend by filling in missing epiweeks
    if (ewData) {
      return {
        week: ewData.epiweek,
        actual: ewData.wili,
        // lagData: ewData.lagData.map(({
        //   lag,
        //   wili
        // }) => {
        //   return {
        //     lag,
        //     value: wili
        //   }
        // })
      }
    } else {
      return {
        week: ew,
        actual: null,
        //lagData: []
      }
    }
  })
}

/**
 * Return fct csv object for given specifications using the cache
 */
const getCsv = moize(function (modelPath, epiweek) {
  let modelId = path.basename(modelPath)
  return new fct.Csv(path.join(modelPath, epiweek + '.csv'), epiweek, modelId, TARGET)
})

/**
 * Return csv score using cache
 */
const getCsvScore = moize(async function (csv) {
  return await fct.score.score(csv)
}, {
  isPromise: true
})

/**
 * Return formatted point data for the state using the cvs object
 */
function parsePointData(csv, stateId) {
  let seasonEpiweeks = fct.utils.epiweek.seasonEpiweeks(SEASON_ID)

  function getTargetData(target) {
    //let cis = [90, 50] // Confidence Intervals
    let cis = [95, 50]
    try {
      let point = csv.getPoint(target, stateId)
      let ranges = cis.map(c => csv.getConfidenceRange(target, stateId, c))

      let low = ranges.map(r => r[0])
      let high = ranges.map(r => r[1])

      low = low.map(v => v === undefined ? point : v); //replace undefined with point estimates
      high = high.map(v => v === undefined ? point : v); //replace undefined with point estimates

      // if (['peak-wk', 'onset-wk'].indexOf(target) > -1) {
      //   // Return indices for time based targets
      //   point = seasonEpiweeks.indexOf(point)
      //   high = high.map(d => seasonEpiweeks.indexOf(d))
      //   low = low.map(d => seasonEpiweeks.indexOf(d))
      // }

      return {
        point,
        low,
        high
      }
    } catch (err) {}
  }

  let seriesData = []
  let targetSeriesData = ['1-ahead', '2-ahead', '3-ahead', '4-ahead']
  for (const i of targetSeriesData) {
    if (getTargetData(i) != undefined) {
      seriesData.push(getTargetData(i))
    }
  }
  if (seriesData.length != 0) {
    return {
      series: seriesData
    }
  }
}

/**
 * Return bin data for the given state using the csv object
 */
function parseBinData(csv, stateId) {
  function getTargetData(target) {
    let bins = csv.getBins(target, stateId)

    // There are different types of bins that we need to consider
    try {
      let binLength = bins.length
      if (binLength > 0) {
        // These are regular, new style, wili bins with last one being
        // [13, 100] which we skip
        return {
          bins: fct.utils.bins.sliceSumBins(bins.slice(0, -1), 5).map(b => b[2])
        }
      } else if (bins.length === 27) {
        // These are old style wili bins with last one being [13, 100] which
        // we skip
        return {
          bins: bins.slice(0, -1).map(b => b[2])
        }
      } else if (target === 'peak-wk') {
        return {
          bins: bins.map(b => b[2])
        }
      } else if (target === 'onset-wk') {
        // We skip the none bin
        return {
          bins: bins.slice(0, -1).map(b => b[2])
        }
      } else {
        throw new Error(`Unknown bin size ${bins.length} in parseBinData for ${target}, ${stateId}`)
      }
    } catch (err) {}
  }

  return {
    series: ['1-ahead', '2-ahead', '3-ahead', '4-ahead'].map(getTargetData)
  }
}

/**
 * Return formatted data from the csv for a state
 * Each value (point, bin, score) is in the following structure
 * - series: [{}, {}, {}, {}]
 * - peakValue: {}
 * - peakTime: {}
 * - onsetTime: {}
 */
async function parseCsv(csv, stateId) {
  return {
    pointData: parsePointData(csv, stateId),
    binData: parseBinData(csv, stateId)
    // scoreData: (await getCsvScore(csv))[stateId]
  }
}

/**
 * Return formatted data for the complete model with given state
 */
async function parseModelDir(modelPath, stateId) {
  let modelId = path.basename(modelPath)
  let availableEpiweeks = utils.getWeekFiles(modelPath)
  let modelMeta = utils.getModelMeta(modelPath)

  let pointPredictions = []
  let binPredictions = []

  let epiweeks_next_year = fct.utils.epiweek.seasonEpiweeks(SEASON_ID+1)
  let epiweeks_next_year_first_24_ew = epiweeks_next_year.slice(0,24)
  let epiweeks = fct.utils.epiweek.seasonEpiweeks(SEASON_ID).slice(5).concat(epiweeks_next_year_first_24_ew)
  for (let epiweek of epiweeks) {

    if (availableEpiweeks.indexOf(epiweek) === -1) {
      // Prediction not available for this week, return null
      pointPredictions.push(null)
      binPredictions.push(null)
    } else {
      let {
        pointData,
        binData,
        scoreData
      } = await parseCsv(getCsv(modelPath, epiweek), stateId)

      pointPredictions.push(pointData)
      binPredictions.push(binData)
    }
  }

  return {
    pointData: {
      id: modelId,
      meta: modelMeta,
      predictions: pointPredictions
    },
    distsData: {
      id: modelId,
      predictions: binPredictions
    }
  }
}

/**
 * Generate data files for the provided seasonData and using the
 * submission files in dataDir
 */
async function generateFiles(seasonData) {
  // Output to be written in file season-{season}.json
  let seasonOut = {
    seasonId: TARGET, // NOTE: This id is full xxxx-yyyy type id
    regions: []
  }

  // Output to be written in file scores-{season}.json
  let scoresOut = {
    seasonId: TARGET,
    regions: []
  }

  // Output to be written in file distributions/season-{season}-{state}.json
  let distsOut = []

  let statePointData, stateDistsData, stateScoresData
  for (let stateId of fct.meta.stateIds) {
    statePointData = []
    stateDistsData = []
    stateScoresData = []

    for (let model of MODELS_DIR) {
      let modelPath = path.join(DATA_DIR, TARGET, model)
      let {
        pointData,
        distsData,
        scoresData
      } = await parseModelDir(modelPath, stateId)
      statePointData.push(pointData)
      stateDistsData.push(distsData)
      stateScoresData.push(scoresData)
    }
    seasonOut.regions.push({
      id: stateId,
      actual: parseStateActual(seasonData, stateId),
      models: statePointData,
      //baseline: 2.4
    })

    distsOut.push({
      seasonId: SEASON,
      stateId: stateId,
      models: stateDistsData
    })

    scoresOut.regions.push({
      id: stateId,
      models: stateScoresData
    })
  }

  await Promise.all([
    writeSeasonFile(seasonOut),
    writeScoresFile(scoresOut),
    ...distsOut.map(d => writeDistsFile(d, d.stateId))
  ])
  console.log(` Data files for season ${TARGET} written.`)
}

// Entry point
fct.truth.getSeasonDataAllLags(TARGET)
  .then(sd => generateFiles(sd))
  .then(() => {
    console.log('All done')
  })
  .catch(e => {
    console.log(e)
    process.exit(1)
  })