import * as utils from './utils'

export const branding = state => state.branding
export const metadata = state => state.metadata
//export const history = state => state.history
export const seasonDataUrls = state => state.seasonDataUrls
// export const scoresDataUrls = state => state.scoresDataUrls
export const distDataUrls = state => state.distDataUrls
export const updateTime = state => {
  return state.metadata ? state.metadata.updateTime : 'NA'
}

/**
 * Return seasons for which we have downloaded the data
 */
export const downloadedSeasons = state => {
  return state.seasonData.map(d => d.seasonId)
}

/**
 * Return selection ids for which we have downloaded distributions
 */
export const downloadedDists = state => {
  return state.distData.map(d => `${d.seasonId}-${d.regionId}`)
}

export const selectedSeasonId = (state, getters) => {
  return getters.seasons[getters['switches/selectedSeason']]
}

export const selectedRegionId = (state, getters) => {
  return getters.metadata.regionData[getters['switches/selectedRegion']].id
}

/**
 * Return distributions data for the current selection
 */
export const selectedDistData = (state, getters) => {
  let selectedDistId = `${getters.selectedSeasonId}-${getters.selectedRegionId}`
  let distDataIdx = getters.downloadedDists.indexOf(selectedDistId)
  return state.distData[distDataIdx]
}

/**
 * Return subset of data reflecting current selection
 * Assume that we have already downloaded the data needed
 */
export const selectedData = (state, getters) => {
  let selectedRegionIdx = getters['switches/selectedRegion']
  let seasonSubset = state.seasonData[getters.downloadedSeasons.indexOf(getters.selectedSeasonId)]
  return seasonSubset.regions[selectedRegionIdx]
}

/**
 * Return list of seasons available for us
 */
export const seasons = (state, getters) => {
  if (state.metadata) {
    return state.metadata.seasonIds
  } else {
    return ['']
  }
}

export const regions = (state, getters) => {
  if (state.metadata) {
    return state.metadata.regionData.map(r => r.subId)
  } else {
    return ['']
  }
}

export const choropleths = state => ['Actual Weighted ILI (%)', 'Relative Weighted ILI (%)']

export const timeChart = state => state.timeChart
export const choropleth = state => state.choropleth
export const distributionChart = state => state.distributionChart

/**
 * Return observed data for currently selected state
 */
// export const observed = (state, getters) => {
//   return getters.selectedData.actual.map(d => d.lagData)
// }

/**
 * Return a series of time points to be referenced by all series
 */
export const timePoints = (state, getters) => {
  if (state.seasonData.length > 0) {
    return getters.selectedData.actual.map(d => {
      return {
        week: d.week % 100,
        year: Math.floor(d.week / 100)
      }
    })
  } else {
    return [{
      week: 0,
      year: 0
    }]
  }
}

/**
 * Return actual data for currently selected state
 */
export const actual = (state, getters) => {
  return getters.selectedData.actual.map(d => d.actual)
}

/**
 * Return historical data for selected state
 * All data older than currently selected season
 */
export const historicalData = (state, getters) => {
  let selectedRegionIdx = getters['switches/selectedRegion']
  let selectedRegionId = getters.selectedRegionId
  let selectedSeasonIdx = getters['switches/selectedSeason']
  let weeksCount = getters.selectedData.actual.length

  let output = []

  // Add data from history store
  // getters.history[selectedRegionId].forEach(h => {
  //   output.push({
  //     id: h.season,
  //     actual: utils.trimHistory(h.data, weeksCount)
  //   })
  // })

  // NOTE: Skipping season not yet downloaded
  for (let i = 0; i < selectedSeasonIdx; i++) {
    let downloadedSeasonIdx = getters.downloadedSeasons.indexOf(getters.seasons[i])
    if (downloadedSeasonIdx !== -1) {
      let seasonActual = state.seasonData[downloadedSeasonIdx].regions[selectedRegionIdx].actual
      output.push({
        id: getters.seasons[i],
        actual: utils.trimHistory(
          seasonActual.map(d => {
            return {
              week: d.week,
              data: d.actual
            }
          }),
          weeksCount
        )
      })
    }
  }

  return output
}

/**
 * Baseline for selected state
 */
// export const baseline = (state, getters) => {
//   return getters.selectedData.baseline
// }

/**
 * Return data subset for chart as specified in region/season selected
 */
export const timeChartData = (state, getters) => {
  return {
    timePoints: getters.timePoints,
    // observed:  getters.actual,
    actual: getters.actual,
    //baseline: getters.baseline,
    models: getters['models/models'],
    // history: getters.historicalData
  }
}


/**
 * Return data for distribution plot
 */
export const distributionChartData = (state, getters) => {
  return {
    timePoints: getters.timePoints,
    currentIdx: getters['weeks/selectedWeekIdx'],
    models: getters['models/modelDistributions']
  }
}

/**
 * Return actual data for all regions for current selections
 */
export const choroplethData = (state, getters) => {
  let selectedSeasonIdx = getters['switches/selectedSeason']
  let relative = getters['switches/choroplethRelative']
  let output = {
    data: [],
    type: relative ? 'diverging' : 'sequential',
    decorator: relative ? x => x + ' % (baseline)' : x => x + ' %'
  }
  let downloadedSeasonIdx = getters.downloadedSeasons.indexOf(getters.seasons[selectedSeasonIdx])

  state.seasonData[downloadedSeasonIdx].regions.map((reg, regIdx) => {
    let values = reg.actual.map(d => d.actual)
    //if (relative) values = utils.baselineScale(values, reg.baseline)
    output.data.push({
      region: getters.metadata.regionData[regIdx].subId,
      states: getters.metadata.regionData[regIdx].states,
      values: values
    })
  })

  // Get choropleth map range
  output.data = output.data.slice(1) // Remove national data
  let rangeData = output.data
  let dataRange = []
  let maxVals = []
  let minVals = []
  rangeData.map(regionData => {
    let actual = regionData.values.filter(d => d)
    maxVals.push(Math.max(...actual))
    minVals.push(Math.min(...actual))
  })
  dataRange = [Math.min(...minVals), Math.max(...maxVals)]


  output.range = dataRange

  //output.range = utils.choroplethDataRange(state.seasonData, relative)

  return output
}