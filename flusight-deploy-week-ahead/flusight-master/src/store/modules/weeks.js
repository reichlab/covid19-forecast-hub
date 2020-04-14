import * as types from '../mutation-types'

const state = {
  pointer: 0
}

// getters
const getters = {
  selectedWeekIdx: state => state.pointer,
  selectedWeekName: (state, getters) => {
    let text = getters.weeks[getters.selectedWeekIdx]
    text += ' ('
    text += Math.floor(getters.years[getters.selectedWeekIdx])
    text += ')'
    return text
  },
  weeks: (state, getters, rootState, rootGetters) => {
    return rootGetters.timePoints.map(d => d.week)
  },
  years: (state, getters, rootState, rootGetters) => {
    return rootGetters.timePoints.map(d => d.year)
  },
  actualIndices: (state, getters, rootState, rootGetters) => {
    return rootGetters.actual.map((d, idx) => {
      return (d ? idx : null)
    }).filter(d => d !== null)
  },
  predictionWeekIdxRange: (state, getters, rootState, rootGetters) => {
    let minMaxes = rootGetters['models/models'].map(m => {
      let min = 0
      let max = m.predictions.length - 1

      let inRange = false
      for (let i = 0; i < m.predictions.length; i++) {
        if (inRange) {
          if (m.predictions[i] === null) {
            max = i - 1
            break
          }
        } else {
          if (m.predictions[i] !== null) {
            min = i
            inRange = true
          }
        }
      }
      return [min, max]
    })

    let first = Math.min(...minMaxes.map(mm => mm[0]))
    let last = Math.max(...minMaxes.map(mm => mm[1]))

    return [first, last]
  },
  actualWeekIdxRange: (state, getters) => {
    return [
      getters.actualIndices[0],
      getters.actualIndices[getters.actualIndices.length - 1]
    ]
  },
  firstPlottingWeekIdx: (state, getters, rootState, rootGetters) => {
    // Check if season is current
    let isLiveSeason = getters.actualIndices.length < rootGetters.timePoints.length

    if (isLiveSeason) {
      return getters.predictionWeekIdxRange[1]
    } else {
      return getters.predictionWeekIdxRange[0]
    }
  }
}

// actions
const actions = {
  resetToFirstIdx ({ commit, getters }) {
    commit(types.UPDATE_SELECTED_WEEK, getters.firstPlottingWeekIdx)
  },

  updateSelectedWeek ({ commit, getters }, val) {
    let capped = Math.max(Math.min(getters.actualWeekIdxRange[1], val), getters.actualWeekIdxRange[0])
    commit(types.UPDATE_SELECTED_WEEK, capped)
  },

  readjustSelectedWeek ({ commit, getters, rootGetters }) {
    let idx = getters.selectedWeekIdx
    let limits
    if (rootGetters['switches/showTimeChart']) {
      limits = getters.actualWeekIdxRange
    } else {
      limits = getters.predictionWeekIdxRange
    }
    let capped = Math.max(Math.min(limits[1], idx), limits[0])
    commit(types.UPDATE_SELECTED_WEEK, capped)
  },

  forwardSelectedWeek ({ commit, getters, rootGetters }) {
    let idx = Math.min(getters.weeks.length - 1, getters.selectedWeekIdx + 1)
    let limits
    if (rootGetters['switches/showTimeChart']) {
      limits = getters.actualWeekIdxRange
    } else {
      limits = getters.predictionWeekIdxRange
    }
    let capped = Math.max(Math.min(limits[1], idx), limits[0])
    commit(types.UPDATE_SELECTED_WEEK, capped)
  },

  backwardSelectedWeek ({ commit, getters, rootGetters }) {
    let idx = Math.max(0, getters.selectedWeekIdx - 1)
    let limits
    if (rootGetters['switches/showTimeChart']) {
      limits = getters.actualWeekIdxRange
    } else {
      limits = getters.predictionWeekIdxRange
    }
    let capped = Math.max(Math.min(limits[1], idx), limits[0])
    commit(types.UPDATE_SELECTED_WEEK, capped)
  }
}

// mutations
const mutations = {
  [types.UPDATE_SELECTED_WEEK] (state, val) {
    state.pointer = val
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
