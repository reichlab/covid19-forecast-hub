// Utilities

/**
 * Return values scaled by baseline
 */
export const baselineScale = (values, baseline) => {
  return values.map(d => {
    return baseline ? ((d / baseline) - 1) * 100 : -1
  })
}

/**
 * Trim history data to fit in length 'numWeeks'
 */
export const trimHistory = (historyActual, numWeeks) => {
  let historyTrimmed = historyActual.slice()

  if (numWeeks === 52) {
    // Clip everyone else to remove 53rd week
    historyTrimmed = historyTrimmed.filter(d => d.week % 100 !== 53)
  } else if (historyTrimmed.length === 52) {
    // Expand to add 53rd week
    // Adding a dummy year 1000, this will also help identify the adjustment
    historyTrimmed.splice(23, 0, {
      week: 100053,
      data: (historyTrimmed[22].data + historyTrimmed[23].data) / 2.0
    })
  }

  return historyTrimmed.map(d => d.data)
}

/**
 * Return range for choropleth color scale
 */
export const choroplethDataRange = (seasonsData, relativeToggle) => {
  let maxVals = []
  let minVals = []

  seasonsData.map(seasonData => {
    seasonData.regions.map(regionData => {
      let actual = regionData.actual.map(d => d.actual).filter(d => d)

      if (relativeToggle) {
        // Use baseline scaled data
        maxVals.push(Math.max(...actual.map(d => ((d / regionData.baseline) - 1) * 100)))
        minVals.push(Math.min(...actual.map(d => ((d / regionData.baseline) - 1) * 100)))
      } else {
        maxVals.push(Math.max(...actual))
        minVals.push(Math.min(...actual))
      }
    })
  })

  let range = [Math.min(...minVals), Math.max(...maxVals)]

  // Patch range to work for new season data
  if (relativeToggle) {
    // Fix the range as -150 to 150% in worst case
    let clipped = Math.max(...range.map(Math.abs), 150)
    return [-clipped, clipped]
  } else {
    // Fix the range as 0 to 10 in worst case
    return [range[0], Math.max(10, range[1])]
  }
}
