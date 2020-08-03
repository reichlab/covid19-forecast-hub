import * as types from './mutation-types'
import * as d3 from 'd3'
import * as util from '../util'
import * as getters from './getters'
import {
  TimeChart,
  DistributionChart,
  events
} from '../../covid-d3-foresight/dist/d3-foresight'

// Initializations
// ---------------

/**
 * Import data from the latest chunk
 */
export const importLatestChunk = (context, dataChunk) => {
  initSeasonDataUrls(context, dataChunk.seasonDataUrls)
  initScoresDataUrls(context, dataChunk.scoresDataUrls)
  initDistDataUrls(context, dataChunk.distDataUrls)
  addSeasonData(context, dataChunk.latestSeasonData)
  addScoresData(context, dataChunk.latestScoresData)
  addDistData(context, dataChunk.latestDistData)
  initMetadata(context, dataChunk.metadata)
  //initHistory(context, dataChunk.history)
}

/**
 * Check for season data corresponding to asked id and fetch if necessary
 */
export const downloadSeasonData = (context, reqData) => {
  let getters = context.getters
  let seasonId = reqData.id

  if (getters.downloadedSeasons.indexOf(seasonId) === -1) {
    let dataUrl = getters.seasonDataUrls[seasonId]
    reqData.http.get(dataUrl).then(response => {
      let data = util.parseDataResponse(response)
      addSeasonData(context, data)
      reqData.success()
    }, response => {
      reqData.fail(response)
    })
  } else {
    reqData.success()
  }
}

/**
 * Check for scores data corresponding to asked id and fetch if necessary
 */
export const downloadScoresData = (context, reqData) => {
  let getters = context.getters
  let seasonId = reqData.id

  if (getters.downloadedScores.indexOf(seasonId) === -1) {
    let dataUrl = getters.scoresDataUrls[seasonId]
    reqData.http.get(dataUrl).then(response => {
      let data = util.parseDataResponse(response)
      addScoresData(context, data)
      reqData.success()
    }, response => {
      reqData.fail(response)
    })
  } else {
    reqData.success()
  }
}

/**
 * Check for dist data corresponding to asked id and fetch if necessary
 */
export const downloadDistData = (context, reqData) => {
  let getters = context.getters
  let distId = reqData.id

  if (getters.downloadedDists.indexOf(distId) === -1) {
    let dataUrl = getters.distDataUrls[distId]
    reqData.http.get(dataUrl).then(response => {
      let data = util.parseDataResponse(response)
      addDistData(context, data)
      reqData.success()
    }, response => {
      reqData.fail(response)
    })
  } else {
    reqData.success()
  }
}

export const addSeasonData = ({
  commit,
  getters
}, val) => {
  if (getters.downloadedSeasons.indexOf(val.seasonId) === -1) {
    commit(types.ADD_SEASON_DATA, val)
  }
}

export const addScoresData = ({
  commit,
  getters
}, val) => {
  if (getters.downloadedScores.indexOf(val.seasonId) === -1) {
    commit(types.ADD_SCORES_DATA, val)
  }
}

export const addDistData = ({
  commit,
  getters
}, val) => {
  if (getters.downloadedDists.indexOf(`${val.seasonId}-${val.regionId}`) === -1) {
    commit(types.ADD_DIST_DATA, val)
  }
}

export const initMetadata = ({
  commit,
  getters
}, val) => {
  if (!getters.metadata) {
    commit(types.SET_METADATA, val)
  }
}

export const initSeasonDataUrls = ({
  commit,
  getters
}, val) => {
  if (!getters.seasonDataUrls) {
    commit(types.SET_SEASON_DATA_URLS, val)
  }
}

export const initScoresDataUrls = ({
  commit,
  getters
}, val) => {
  if (!getters.scoresDataUrls) {
    commit(types.SET_SCORES_DATA_URLS, val)
  }
}

export const initDistDataUrls = ({
  commit,
  getters
}, val) => {
  if (!getters.distDataUrls) {
    commit(types.SET_DIST_DATA_URLS, val)
  }
}

// export const initHistory = ({
//   commit,
//   getters
// }, val) => {
//   if (!getters.history) {
//     commit(types.SET_HISTORY, val)
//   }
// }

export const setBrandLogo = ({
  commit,
  getters
}, val) => {
  commit(types.SET_BRAND_LOGO, val)
}

export const initTimeChart = ({
  commit,
  getters,
  dispatch
}, divSelector) => {
  let timeChartOptions = {
    // baseline: {
    //   text: ['CDC', 'Baseline'],
    //   description: `Baseline ILI value as defined by CDC.
    //                 <br><br><em>Click to know more</em>`,
    //   url: 'http://www.cdc.gov/flu/weekly/overview.htm'
    // },
    axes: {
      x: {
        title: ['Epidemic', 'Week'],
        description: `Week of the calendar year, as measured by the CDC.
                      <br><br><em>Click to know more</em>`,
        url: 'https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf'
      },
      y: {
        //title: 'Cumulative Deaths',
        title: getters.selectedSeasonId,
        description: `Cumulative deaths due to COVID-19
                      <br><br><em>Click to know more</em>`,
        url: 'https://github.com/reichlab/covid19-death-forecasts',
        //domain: [0, getters.timeChartMax]
      }
    },
    pointType: 'mmwr-week',
    confidenceIntervals: getters['models/modelCIs'],
    onset: true
  }

  // Clear div
  d3.select(divSelector).selectAll('*').remove()
  let timeChart = new TimeChart(divSelector, timeChartOptions)

  timeChart.addHook(events.JUMP_TO_INDEX, (index) => {
    dispatch('weeks/updateSelectedWeek', index)
    dispatch('weeks/readjustSelectedWeek')
  })

  commit(types.SET_TIMECHART, timeChart)
}

export const initChoropleth = ({
  commit
}, val) => {
  commit(types.SET_CHOROPLETH, val)
}

export const initDistributionChart = ({
  commit,
  getters,
  dispatch
}, divSelector) => {
  let distributionChartConfig = {
    axes: {
      x: {
        title: ['Epidemic', 'Week'],
        description: `Week of the calendar year, as measured by the CDC.
                      <br><br><em>Click to know more</em>`,
        url: 'https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf'
      }
    }
  }

  // Clear div
  d3.select(divSelector).selectAll('*').remove()
  let distributionChart = new DistributionChart(divSelector, distributionChartConfig)

  distributionChart.addHook(events.JUMP_TO_INDEX, (index) => {
    dispatch('weeks/updateSelectedWeek', index)
    dispatch('weeks/readjustSelectedWeek')
  })

  commit(types.SET_DISTRIBUTIONCHART, distributionChart)
}

// Plotting (data-changing) actions
// --------------------------------

/**
 * Plot (update) time chart with region / season data
 */
export const plotTimeChart = ({
  dispatch,
  getters
}) => {
  if (getters.timeChart) {
    getters.timeChart.updateYAxisTitle(getters.selectedSeasonId)
    getters.timeChart.plot(getters.timeChartData)
    dispatch('weeks/readjustSelectedWeek')
    dispatch('updateTimeChart')
  }
}

/**
 * Plot distribution chart
 */
export const plotDistributionChart = ({
  getters
}) => {
  if (getters.distributionChart) {
    getters.distributionChart.plot(getters.distributionChartData)
  }
}

/**
 * Plot (update) choropleth with currently selected data
 */
export const plotChoropleth = ({
  commit,
  dispatch,
  getters
}) => {
  getters.choropleth.plot(getters.choroplethData)
  dispatch('updateChoropleth')
}

/**
 * Tell time chart to move markers to weekIdx
 */
export const updateTimeChart = ({
  getters
}) => {
  if (getters.timeChart) {
    getters.timeChart.update(getters['weeks/selectedWeekIdx'])
  }
}

/**
 * Tell choropleth to move to weekidx and highlight a region
 */
export const updateChoropleth = ({
  getters
}) => {
  let payload = {
    weekIdx: getters['weeks/selectedWeekIdx'],
    regionIdx: getters['switches/selectedRegion'] - 1
  }

  getters.choropleth.update(payload)
}

/**
 * Clear timeChart
 */
export const clearTimeChart = ({
  commit
}) => {
  commit(types.SET_TIMECHART, null)
}

/**
 * Clear distributionChart
 */
export const clearDistributionChart = ({
  commit
}) => {
  commit(types.SET_DISTRIBUTIONCHART, null)
}