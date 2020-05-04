/**
 * Functions for parsing data object for information
 */

/**
 * Doc guard
 */
import { Timepoint } from '../../interfaces'
import * as errors from '../errors'
import { getTick } from './timepoints'

/**
 * Tell if onset predictions are present in the data
 */
function isOnsetPresent (modelsData): boolean {
  let model = modelsData[0]
  let nonNullPreds = model.predictions.filter(p => p !== null)
  if (nonNullPreds.length === 0) {
    // Just to be safe
    return false
  } else {
    return 'onsetTime' in nonNullPreds[0]
  }
}

/**
 * Tell if peak predictions are present in the data
 */
function isPeakPresent (modelsData): boolean {
  let model = modelsData[0]
  let nonNullPreds = model.predictions.filter(p => p !== null)
  if (nonNullPreds.length === 0) {
    // Just to be safe
    return false
  } else {
    return ('peakTime' in nonNullPreds[0]) && ('peakValue' in nonNullPreds[0])
  }
}

/**
 * Return list of model ids that are to be pinned
 */
function pinnedModelIds (modelsData): string[] {
  return modelsData.filter(model => {
    return 'pinned' in model ? model.pinned : false
  }).map(model => model.id)
}

/**
 * Tell if we have data version date present in the predictions data
 */
function isVersionTimePresent (modelsData): boolean {
  let model = modelsData[0]
  let nonNullPreds = model.predictions.filter(p => p !== null)
  if (nonNullPreds.length === 0) {
    // Keeping the default behavior simple
    return false
  } else {
    return nonNullPreds.every(p => 'dataVersionTime' in p)
  }
}

/**
 * Whether to show the timezeroLine
 */
function showTimezeroLine (data, config): boolean {
  if ('timezeroLine' in config) {
    // key takes priority
    return config.timezeroLine
  } else if ('timezeroLine' in data) {
    return data.timezeroLine
  } else {
    // If version time is present, we show the timezero by default
    return isVersionTimePresent(data.models)
  }
}


/**
 * Parse time chart data and provide information about it
 */
export function getTimeChartDataConfig (data, config) {
  return {
    actual: 'actual' in data,
    observed: 'observed' in data,
    history: 'history' in data,
    baseline: 'baseline' in data,
    timezeroLine: showTimezeroLine(data, config),
    predictions: {
      peak: isPeakPresent(data.models),
      onset: config.onset && isOnsetPresent(data.models),
      versionTime: isVersionTimePresent(data.models)
    },
    pinnedModels: pinnedModelIds(data.models),
    additionalLines: 'additionalLines' in data,
    ticks: data.timePoints.map(tp => getTick(tp, config.pointType)),
    pointType: config.pointType
  }
}

/**
 * Parse distribution chart data and provide information about it
 */
export function getDistChartDataConfig (data, config) {
  return {
    actual: false,
    observed: false,
    history: false,
    pinnedModels: pinnedModelIds(data.models),
    ticks: data.timePoints.map(tp => getTick(tp, config.pointType)),
    pointType: config.pointType,
    curveNames: data.models[0].curves.map(c => c.name)
  }
}
