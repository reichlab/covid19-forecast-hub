/**
 * Script to wrap text in model metadata files
 */

const models = require('./modules/models')

const rootPath = './model-forecasts'

// NOTE: This step goes through all type of models
const modelParents = [
  'component-models',
  'cv-ensemble-models',
  'real-time-component-models',
  'real-time-ensemble-models'
]

let modelDirs = models.getModelDirs(rootPath, modelParents)
modelDirs.forEach(md => models.writeModelMetadata(models.getModelMetadata(md), md))
