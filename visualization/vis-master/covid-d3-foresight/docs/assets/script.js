document.addEventListener("DOMContentLoaded", function () {

let config = {
  pointType: 'mmwr-week', // Default is week
  axes: {
    y: {
      title: 'Random numbers' // Title for the y axis
    }
  }
}

let timePoints = [...Array(51).keys()].map(w => {
  return { week: w + 1, year: 2016 }
})

// Random sequence generator
function rseq (n) {
  let seq = [Math.random()]
  for (let i = 1; i < n; i++) {
    seq.push(Math.random() * (1 + seq[i - 1]))
  }
  return seq
}

// Predictions look like [{ series: [{ point: 0.5 }, { point: 1.2 } ...] }, ..., null, null]
let predictions = timePoints.map(tp => {
  if (tp.week > 30) {
    // We only predict upto week 30
    return null
  } else {
    // Provide 10 week ahead predictions
    return {
      series: rseq(10).map(r => { return { point: r } })
    }
  }
})

let data = {
  timePoints,
  models: [
    {
      id: 'mod',
      meta: {
        name: 'Name',
        description: 'Model description here',
        url: 'http://github.com'
      },
      pinned: false, // Setting true shows the model in top section of the legend
                     // In case of absence of `pinned` key (or false), the model
                     // goes in the bottom section
      predictions,
      style: { // Optional parameter for applying custom css on svg elements
        color: '#4682b4', // Defaults to values from the internal palette
        point: {
          // Style for the dots in prediction
        },
        area: {
          // Style for the confidence area (shaded region around the line)
        },
        line: {
          // Style for the main line
        }
      }
    }
  ]
}

// 1. Initialize
// Setup the id of div where we are going to plot
// Also pass in config options
let timeChart = new d3Foresight.TimeChart('#timechart', config)

// 2. Plot
// Provide the data for the complete year
timeChart.plot(data)

// 3. Update
// Move to the given index in the set of timePoints
timeChart.update(10)
// Or simply use
// timeChart.moveForward()
// timeChart.moveBackward()

// Lets also save the timechart object in global namespace
window.timeChart = timeChart

let copy = it => Object.assign({}, it)
function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max))
}

let tcBaseline = new d3Foresight.TimeChart('#tc-baseline', Object.assign(copy(config), {
  baseline: {
    text: 'Baseline', // To show multiline text, pass an array of strings,
    description: 'This is a sample baseline',
    url: 'https://github.com'
  }
}))
tcBaseline.plot(Object.assign(copy(data), {
  baseline: 0.3
}))
tcBaseline.update(10)

// Suppose we have actual data for 20 time steps only. We give null for other points
let actual = rseq(20).concat(timePoints.slice(20).map(tp => null))

let tcActual = new d3Foresight.TimeChart('#tc-actual', config)
tcActual.plot(Object.assign(copy(data), { actual: actual }))
tcActual.update(10)

// Lets only show 20 time steps.
let observed = rseq(20).map((r, idx) => {
  let delta = 0.05
  let lags = []
  for (let l = 20; l >= 0; l--) {
    lags.push({ lag: l, value: r + (delta * (20 - l)) })
  }
  return lags
})

// Add [] for other points
observed = observed.concat(timePoints.slice(20).map(tp => []))

let tcObserved = new d3Foresight.TimeChart('#tc-observed', config)
tcObserved.plot(Object.assign(copy(data), { observed: observed }))
tcObserved.update(10)

let historicalData = [
  {
    id: 'some-past-series',
    actual: rseq(51)
  },
  {
    id: 'another-past-series',
    actual: rseq(51)
  }
]

let tcHistory = new d3Foresight.TimeChart('#tc-history', config)
tcHistory.plot(Object.assign(copy(data), { history: historicalData }))
tcHistory.update(10)

// Predictions now look like [{ series: [
// { point: 0.5, low: [0.3, 0.4], high: [0.7, 0.6] },
// { point: 1.2, low: [1.0, 1.1], high: [1.4, 1.3] }
// ...] }, ..., null, null]
let predictionsWithCI = timePoints.map(tp => {
  if (tp.week > 30) {
    // We only predict upto week 30
    return null
  } else {
    // Provide 10 week ahead predictions adding a dummy 0.2 and 0.1 spacing
    // to show the confidence interval
    return {
      series: rseq(10).map(r => {
        return {
          point: r,
          low: [Math.max(0, r - 0.2), Math.max(0, r - 0.1)],
          high: [r + 0.2, r + 0.1]
        }
      })
    }
  }
})

let dataWithCI = {
  timePoints,
  models: [
    {
      id: 'mod',
      meta: {
        name: 'Name',
        description: 'Model description here',
        url: 'https://github.com'
      },
      predictions: predictionsWithCI
    }
  ]
}

let configCI = Object.assign(copy(config), { confidenceIntervals: ['90%', '50%'] })
let tcCI = new d3Foresight.TimeChart('#tc-ci', configCI)
tcCI.plot(dataWithCI)
tcCI.update(10)

let predictionsWithPeakOnset = timePoints.map(tp => {
  if (tp.week > 30) {
    // We only predict upto week 30
    return null
  } else {
    return {
      series: rseq(10).map(r => { return { point: r } }),
      peakTime: { point: 12 + getRandomInt(5) },
      onsetTime: { point: 8 + getRandomInt(5) },
      peakValue: { point: Math.random() }
    }
  }
})

let dataWithPeakOnset = {
  timePoints,
  models: [
    {
      id: 'mod',
      meta: {
        name: 'Name',
        description: 'Model description here',
        url: 'https://github.com'
      },
      predictions: predictionsWithPeakOnset
    }
  ]
}

let configOnset = Object.assign(copy(config), { onset: true })
let tcPeakOnset = new d3Foresight.TimeChart('#tc-peak-onset', configOnset)
tcPeakOnset.plot(dataWithPeakOnset)
tcPeakOnset.update(10)

let tcAdditional = new d3Foresight.TimeChart('#timechart-additional', config)

let additionalLines = [
  {
    id: 'Extra 1',
    data: 1.53, // Scalar makes it show up as horizontal line
    style: { // Optional style parameter
      color: 'red',
      point: {
        // Optional parameter for styling the dots
      },
      line: {
        // Style for the main line
        'stroke-dasharray': '5,5'
      }
    },
    meta: {
      // Similar to what is used in models, all optional
      name: 'Extra baseline',
      description: 'This is an additional baseline',
      url: 'https://github.com'
    },
    tooltip: false, // Should the value show up in tooltip (false by default or when absent)
    legend: true // Should the value show up in legend (true by default or when absent)
  },
  {
    id: 'Extra 2',
    data: rseq(51), // Structure similar to like the actual array
    style: {
      color: '#9b59b6',
      point: {
        r: 0
      }
    },
    tooltip: true
  }
]

tcAdditional.plot(Object.assign(copy(data), { additionalLines }))
tcAdditional.update(10)

// Lets just add 2 to the timezeros for dvds
function addDvts (data) {
  let dvts = data.timePoints.map(tp => {
    return { week: tp.week + 2, year: tp.year }
  })

  data.models.forEach(m => {
    m.predictions.forEach((p, idx) => {
      if (p) {
        p.dataVersionTime = dvts[idx]
      }
    })
  })

  return data
}

let tcDvd = new d3Foresight.TimeChart('#timechart-dvt-plot', config)

tcDvd.plot(addDvts(copy(data)))
tcDvd.update(10)

let options = {
  baseline: {
    text: ['CDC', 'Baseline'], // A list of strings creates multiline text
    description: `Baseline ILI value as defined by CDC.
                    <br><br><em>Click to know more</em>`,
    url: 'http://www.cdc.gov/flu/weekly/overview.htm' // url is optional
  },
  axes: {
    x: {
      title: ['Epidemic', 'Week'],
      description: `Week of the calendar year, as measured by the CDC.
                      <br><br><em>Click to know more</em>`,
      url: 'https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf'
    },
    y: {
      title: 'Weighted ILI (%)',
      description: `Percentage of outpatient doctor visits for
                      influenza-like illness, weighted by state population.
                      <br><br><em>Click to know more</em>`,
      url: 'http://www.cdc.gov/flu/weekly/overview.htm',
      domain: [0, 13] // For explicitly clipping the y values
    }
  },
  pointType: 'mmwr-week',
  confidenceIntervals: ['90%', '50%'], // List of ci labels
  onset: true, // Whether to show onset panel or not
  timezeroLine: false // Whether to show the timezeroLine, skipping this makes us fall back to the
                      // behavior based presence of data version time
}

})
