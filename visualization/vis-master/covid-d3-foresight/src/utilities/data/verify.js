/**
 * Functions for verifying if the data object for plotting is valid or not
 */

/**
 * Doc guard
 */
import { IncorrectData } from '../errors'
import Ajv from 'ajv'
import timeChartModelSchema from './time-chart-model.schema.json'

/**
 * Verify data for time chart
 */
export function verifyTimeChartData (data) {
  if (!('timePoints' in data)) {
    throw new IncorrectData('No timePoints key found in provided data')
  }

  if (!('models' in data)) {
    throw new IncorrectData('No models in data')
  }

  let ajv = new Ajv()
  let validate = ajv.compile(timeChartModelSchema)

  // Check if all models have data in correct structure
  if (!data.models.every(m => validate(m))) {
    console.log(validate.errors)
    throw new IncorrectData('Model data not in approprate structure')
  }
}

/**
 * Verify data for distribution chart
 */
export function verifyDistChartData (data) {
  if (!('timePoints' in data)) {
    throw new IncorrectData('No timePoints key found in provided data')
  }

  if (!('models' in data)) {
    throw new IncorrectData('No models in data')
  }
}
