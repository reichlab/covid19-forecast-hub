/**
 * Script for generating scores spreadsheet using the ground truth file
 */

const d3 = require('d3')
const Papa = require('papaparse')
const fs = require('fs')
const mmwr = require('mmwr-week')
const meta = require('./modules/meta')
const models = require('./modules/models')
const util = require('./modules/util')

const truthFile = './scores/target-multivals.csv'
const outputFile = './scores/scores.csv'
const errorLogFile = './csv-error.log'

const TOLERANCE = 0.0001

/**
 * Return csv data nested using d3.nest
 */
const getCsvData = (csvFile) => {
  let csvData = Papa.parse(fs.readFileSync(csvFile, 'utf8')).data
    .slice(1)
    .filter(d => !(d.length === 1 && d[0] === ''))

  // Location, Target, Type, Unit, Bin_start_incl, Bin_end_notincl, Value
  return d3.nest()
    .key(d => d[0]) // region
    .key(d => d[1]) // target
    .object(csvData)
}

/**
 * Return nested ground truth data
 */
const getTrueData = truthFile => {
  let data = Papa.parse(fs.readFileSync(truthFile, 'utf8')).data
    .slice(1)
    .filter(d => !(d.length === 1 && d[0] === ''))

  // Year, Calendar Week, Season, Model Week, Location, Target, Valid Bin_start_incl
  return d3.nest()
    .key(d => d[0]) // year
    .key(d => d[1]) // epiweek
    .key(d => d[4]) // region
    .key(d => d[5]) // target
    .object(data)
}

/**
 * Return a season string for given time data
 */
const getSeason = (year, epiweek) => {
  return (epiweek < 40) ? `${year-1}/${year}` : `${year}/${year+1}`
}

/**
 * Tell the last week (52/53) for given time data
 */
const getLastWeek = (year, epiweek) => {
  let seasonFirstYear = parseInt(getSeason(year, epiweek).split('/')[0])
  return (new mmwr.MMWRDate(seasonFirstYear)).nWeeks
}

/**
 * Return a neighbouring region of 1 bin around a given week
 */
const weekNeighbours = (binStart, year, epiweek) => {
  let lastWeek = getLastWeek(year, epiweek)
  let neighbours = []
  // Handle edge cases
  if (binStart === 40) {
    // We are at the beginning of the season
    neighbours = [binStart, 41]
  } else if (binStart === lastWeek) {
    // We are the end of year (but somewhere in between for season)
    // The next bin is 1
    neighbours = [binStart - 1, binStart, 1]
  } else if (binStart === 1) {
    neighbours = [lastWeek, binStart, 2]
  } else {
    // This is regular case
    neighbours = [binStart - 1, binStart, binStart + 1]
  }

  return neighbours.map(Math.round)
}

/**
 * Return expanded set of binStarts for given bin value and target type
 */
const expandBinStarts = (binStarts, targetType, year, epiweek) => {
  if (targetType.endsWith('ahead') || targetType.endsWith('percentage')) {
    // This is a percentage target
    return util.unique(binStarts.reduce((acc, binStart) => {
      return acc.concat(
        util.arange(-0.5, 0.5, 0.1)
        .map(diff => binStart + diff)
        .map(bs => Math.round(bs * 10) / 10) // Round to get just one place decimal
        .filter(bs => (bs >= 0.0 - Number.EPSILON) && (bs <= 13.0 + Number.EPSILON)) // We only need bins from 0.0 to 13.0
      )
    }, []))
  } else {
    // This is a week target
    return util.unique(binStarts.reduce((acc, binStart) => {
      return acc.concat(weekNeighbours(binStart, year, epiweek))
    }, []))
  }
}

/**
 * Return probability assigned by model for given binStarts
 */
const getBinProbabilities = (csvDataSubset, binStarts) => {
  return binStarts.map(bs => {
    // If bs is NaN, then we look for none bin. This is for onset case
    let filteredRows
    if (isNaN(bs)) {
      filteredRows = csvDataSubset.filter(row => row[4] === 'none')
    } else {
      // Assuming we have a bin here
      filteredRows = csvDataSubset.filter(row => util.isClose(parseFloat(row[4]), bs))
      if (filteredRows.length === 0) {
        // This is mostly due to week 53 issue, the truth file has week 53 allowed,
        // while the models might not use a bin start using week 53.
        // We jump to week 1 here
        filteredRows = csvDataSubset.filter(row => util.isClose(parseFloat(row[4]), 1.0))
      }
    }
    return parseFloat(filteredRows[0][6])
  })
}

// E N T R Y  P O I N T
// For each model, for each csv (year, week), for each region, get the 7 targets
// and find log scores, append those to the output file.

// Clear output file
let header = [
  'Model',
  'Year',
  'Epiweek',
  'Season',
  'Model Week',
  'Location',
  'Target',
  'Score',
  'Multi bin score'
]

let outputLines = [header.join(',')]
let errorLogLines = []
let errorBlacklistLines = []
let trueData = getTrueData(truthFile)
let csvData

// NOTE: For scores, we only consider these two directories
models.getModelDirs(
  './model-forecasts',
  ['component-models', 'cv-ensemble-models']
).forEach(modelDir => {
  let modelId = models.getModelId(modelDir)
  console.log(` > Parsing model ${modelDir}`)
  let csvs = models.getModelCsvs(modelDir)
  console.log(`     Model provides ${csvs.length} CSVs`)

  csvs.forEach(csvFile => {
    let {
      year,
      epiweek
    } = models.getCsvTime(csvFile)
    try {
      csvData = getCsvData(csvFile)
      meta.regions.forEach(region => {
        meta.targets.forEach(target => {
          let trueTargets = trueData[year][epiweek][region][target]
          let trueBinStarts = trueTargets.map(tt => parseFloat(tt[6]))
          let expandedTrueBinStarts = expandBinStarts(trueBinStarts, target, parseInt(year), parseInt(epiweek))
          let season = trueTargets[0][2]
          let modelWeek = trueTargets[0][3]
          let modelProbabilities = csvData[region][target]
          try {
            let binProbs = getBinProbabilities(modelProbabilities, trueBinStarts)
            let expandedBinProbs = getBinProbabilities(modelProbabilities, expandedTrueBinStarts)
            let score = Math.log(binProbs.reduce((a, b) => a + b, 0))
            let expandedScore = Math.log(expandedBinProbs.reduce((a, b) => a + b, 0))

            // Bail out if we get greater than 1 expanded probability
            if (Math.log(expandedBinProbs.reduce((a, b) => a + b, 0)) > TOLERANCE) {
              console.log(`Error in ${csvFile}, region ${region} and target ${target}`)
              console.log(`Getting expanded probability higher than 1 for bin starts ${trueBinStarts}`)
              console.log(`Bin probabilties sum: ${binProbs.reduce((a, b) => a + b, 0)}, score: ${score}`)
              console.log(`Expanded bin starts ${expandedTrueBinStarts}`)
              console.log(`Expanded probabilties sum: ${expandedBinProbs.reduce((a, b) => a + b, 0)}, score: ${expandedScore}`)
              process.exit(1)
            }

            // Fix score ranges
            score = util.clip(score, -999, 0, TOLERANCE)
            expandedScore = util.clip(expandedScore, -999, 0, TOLERANCE)

            outputLines.push(
              `${modelId},${year},${epiweek},${season},${modelWeek},${region},${target},${score},${expandedScore}`
            )
          } catch (e) {
            errorLogLines.push(`Error in ${csvFile} for ${region}, ${target}`)
            errorLogLines.push(e.name)
            errorLogLines.push(e.message)
            errorLogLines.push('')
            errorBlacklistLines.push(`- ${csvFile}`)
            console.log(`Error in ${csvFile} for ${region}, ${target}`)
            console.log(e)
          }
        })
      })
    } catch (e) {
      errorLogLines.push(`Error in ${csvFile}`)
      errorLogLines.push(e.name)
      errorLogLines.push(e.message)
      errorLogLines.push('')
      errorBlacklistLines.push(`- ${csvFile}`)
      console.log(`Error in ${csvFile}`)
      console.log(e)
    }
  })
})

// The main scores.csv
util.writeLines(outputLines, outputFile)

// Error logs
util.writeLines(errorLogLines, errorLogFile)