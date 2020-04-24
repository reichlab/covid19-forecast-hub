/**
 * Common utility functions
 */

const fs = require('fs-extra')
const path = require('path')
const yaml = require('js-yaml')
const fct = require('../covid-csv-tools')

const readYaml = filePath => {
  return yaml.safeLoad(fs.readFileSync(filePath, 'utf8'))
}

async function writeJSON(filePath, data) {
  return await fs.writeFile(filePath, JSON.stringify(data))
}

/**
 * Return all subdirectoies in given directory
 * @param {string} directory root directory
 * @returns {Array} list of subdirectory
 */
const getSubDirectories = directory => {
  return fs.readdirSync(directory).filter(file => {
    return fs.statSync(path.join(directory, file)).isDirectory()
  })
}

/**
 * Return all csv files (parsing to integer names) in directory
 * @param {string} directory root directory
 * @returns {Array} list of .csv files
 */
const getWeekFiles = directory => {
  let newFiles = fs.readdirSync(directory)
    .filter(f => f.endsWith('.csv'))
  return newFiles.map(file => parseInt(file.split()[0]))
}

/**
 * Get model metadata
 * @param {string} submissionDir path to the submission directory
 * @returns {Object} metadata object
 */
const getModelMeta = submissionDir => {
  let meta = {
    name: 'No metadata found',
    description: '',
    url: ''
  }

  let metaFiles = ['meta.yaml', 'meta.yml']

  for (let i = 0; i < metaFiles.length; i++) {
    try {
      let filePath = path.join(submissionDir, metaFiles[i])
      meta = readYaml(filePath)
    } catch (e) {
      continue
    }
  }

  return meta
}

/**
 * Aggregate the scores for a state by taking mean
 */
function aggregateScores(scores) {
  let targets = fct.meta.targetIds
  let scoreIds = ['logScore', 'logScoreMultiBin', 'absError'] // We use only these scores in flusight
  let meanScores = {}

  for (let target of targets) {
    meanScores[target] = {}
    for (let scoreId of scoreIds) {
      let scoreValues = scores.map(s => s[target][scoreId])
        .filter(s => s !== null)
        .map(s => s === -Infinity ? -10 : s) // Convert -Infinity to -10
      meanScores[target][scoreId] = scoreValues.reduce((a, b) => a + b, 0)
      meanScores[target][scoreId] /= scoreValues.length
    }
  }

  return meanScores
}

exports.readYaml = readYaml
exports.writeJSON = writeJSON
exports.getSubDirectories = getSubDirectories
exports.getWeekFiles = getWeekFiles
exports.getModelMeta = getModelMeta
exports.aggregateScores = aggregateScores