/**
 * Script for converting the scores data from scores.csv to json for visualization
 */

const fs = require('fs-extra')
const path = require('path')
const Papa = require('papaparse')
const d3 = require('d3')

const inputFile = '../scores/scores.csv'
const outputFile = './scores.json'

const readCSV = csvFile => {
  return Papa.parse(fs.readFileSync(csvFile, 'utf8')).data
    .slice(1)
    .filter(d => !(d.length === 1 && d[0] === ''))
}


/**
 * Prune columns and change keys of csv entries to match visualizer's
 */
const pruneColumns = csvRows => {
  // Columns: Model, Year, Epiweek, Season, Model Week, Location, Target, Score
  let formatLocation = location => {
    let splits = location.split(' ')
    return splits.length === 2 ? 'nat' : `hhs${splits[2]}`
  }
  return csvRows.map(row => {
    return [
      row[3].split('/').join('-'), // Season
      formatLocation(row[5]), // Location
      row[0], // Model
      row[6], // Target,
      row[7] // Score
    ]
  })
}

/**
 * Return an averaged version of scores over seasons and states
 */
const averageScores = scores => {
  // Columns: Season, Location, Model, Target, Score
  return d3.nest()
    .key(d => d[0])
    .key(d => d[1])
    .key(d => d[2])
    .key(d => d[3])
    .rollup(leafs => {
      return leafs.reduce((acc, l) => parseFloat(l[4]) + acc, 0) / leafs.length
    })
    .object(scores)
}

const writeJSON = (data, jsonFile) => {
  fs.writeFileSync(jsonFile, JSON.stringify(data))
}

// E N T R Y  P O I N T
writeJSON(averageScores(pruneColumns(readCSV(inputFile))), outputFile)