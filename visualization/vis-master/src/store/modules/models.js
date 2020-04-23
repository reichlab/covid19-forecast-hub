const state = {
  confidenceIntervals: ['95%', '50%'],

  curveNames: [
    '1 week ahead (% wili)',
    '2 weeks ahead (% wili)',
    '3 weeks ahead (% wili)',
    '4 weeks ahead (% wili)'
  ],

  // Cache for unpacked curve data
  // Identifies curves using `seasonIdx-regionIdx-weekIdx-modelIdx-curveIdx`
  curveCache: {}
}

// getters
const getters = {
  models: (state, getters, rootState, rootGetters) => {
    return rootGetters.selectedData.models
  },

  /**
   * Getter for generating probability distributions
   */
  modelDistributions: (state, getters, rootState, rootGetters) => {
    let models = getters.models
    let currentWeekIdx = rootGetters['weeks/selectedWeekIdx']
    let timePoints = rootGetters['weeks/weeks']

    let curveIdentifierPrefix = rootGetters['switches/selectedSeason'] + '-' + rootGetters['switches/selectedRegion'] + '-' + currentWeekIdx

    let modelDistData = rootGetters.selectedDistData.models

    return models.map((m, idx) => {
      let currentPreds = modelDistData[idx].predictions[currentWeekIdx]
      m.curves = state.curveNames.map(cn => {
        return {
          name: cn,
          data: null,
          actual: null
        }
      })
      if (currentPreds) {
        // Predictions are present
        // Decompress the bins and latch on to curves
        let curves = [
          ...currentPreds.series.map(s => s.bins),
          currentPreds.peakTime.bins,
          currentPreds.peakValue.bins,
          currentPreds.onsetTime.bins
        ]

        for (let i = 0; i < m.curves.length; i++) {
          let paddedArray

          let curveIdentifier = curveIdentifierPrefix + '-' + idx + '-' + i
          if (state.curveCache[curveIdentifier]) {
            paddedArray = state.curveCache[curveIdentifier]
          } else {
            if ([33, 34].indexOf(curves[i].length) > -1) {
              // These are week values
              let startAt = 10
              paddedArray = timePoints.map((tp, idx) => {
                if ((idx >= startAt) && (idx < (startAt + curves[i].length))) {
                  return [tp, curves[i][idx - startAt]]
                } else {
                  return [tp, 0]
                }
              })
            } else {
              // These are value bins
              if (curves[i].length === 26) {
                // New bins
                paddedArray = curves[i].map((val, idx) => [0.5 * idx, val])
              } else {
                // Old bins
                paddedArray = curves[i].map((val, idx) => [idx, val])
              }
            }

            state.curveCache[curveIdentifier] = paddedArray
          }

          m.curves[i].data = paddedArray
          m.curves[i].actual = 0
        }
      }
      return m
    })
  },

  modelIds: (state, getters) => getters.models.map(m => m.id),
  modelMeta: (state, getters) => getters.models.map(m => m.meta),
  modelDomain: (state, getters) => getters.models.map(m => console.log(m)),
  modelCIs: (state, getters) => state.confidenceIntervals
}

export default {
  namespaced: true,
  state,
  getters
}