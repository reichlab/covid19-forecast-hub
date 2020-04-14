/**
 * Module for model directory related functions
 */

const fs = require('fs')
const path = require('path')
const util = require('./util')
const wildcard = require('wildcard');

/**
 * Return model directories
 */
const getMetadataFile = (rootDir) => {
  return wildcard('metadata*', fs.readdirSync(rootDir)).toString()
}

const getModelDirs = (rootDir, modelTypes) => {
  return modelTypes.reduce((acc) => {
      return acc.concat(fs.readdirSync(rootDir).map(it => path.join(rootDir, it)))
    }, [])
    .filter(it => fs.statSync(it).isDirectory())
    .filter(it => fs.existsSync(path.join(it, getMetadataFile(it))))
}

const getModelMetadata = modelDir => {
  return util.readYamlFile(path.join(modelDir, getMetadataFile(modelDir)))
}

const writeModelMetadata = (data, modelDir) => {
  util.writeYamlFile(data, path.join(modelDir, getMetadataFile(modelDir)))
}

/**
 * Return model id from modelDir
 */
const getModelId = modelDir => {
  let meta = getModelMetadata(modelDir)
  return `${meta.team_abbr}-${meta.model_abbr}`
}

/**
 * Return timing information about the csv
 */
const getCsvTime = csvFile => {
  let baseName = path.basename(csvFile)
  let [epiweek, year, ] = baseName.split('-')
  return {
    epiweek: parseInt(epiweek.slice(2)) + '',
    year: year
  }
}

const getModelCsvs = modelDir => {
  return fs.readdirSync(modelDir)
    .filter(item => item.endsWith('csv'))
    .map(fileName => path.join(modelDir, fileName))
}

module.exports.getMetadataFile = getMetadataFile
module.exports.getModelDirs = getModelDirs
module.exports.getModelMetadata = getModelMetadata
module.exports.writeModelMetadata = writeModelMetadata
module.exports.getModelId = getModelId
module.exports.getCsvTime = getCsvTime
module.exports.getModelCsvs = getModelCsvs