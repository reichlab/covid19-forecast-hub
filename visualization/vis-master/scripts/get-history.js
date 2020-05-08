/**
 * Download and save historical data
 */

const fct = require('../covid-csv-tools')
const fs = require('fs-extra')

const OUTPUT_FILE = './scripts/assets/history.json'

// Get the ending year of the most recent season.
// Example: if current season is 2019/2020, then the most recent previous seasons is 2018/2019 and its ending year is 2019
// Note: if the current month is July or later, it's considered the current season, otherwise it's the previous season.
var today = new Date()
var currentYear = today.getFullYear()
var currentMonth = today.getMonth()
var pad = currentMonth < 6 ? 0 : 1
var numberOfSeasonsSince2003 = currentYear - 2010 + pad - 1

// Download history for seasons 2003 to the season before this current season
let seasonIds = [...Array(numberOfSeasonsSince2003).keys()].map(i => 2010 + i)

console.log(` Downloading historical data for the following seasons\n${seasonIds.join(', ')}`)

/**
 * Convert data returned from fct to the structure used by flusight
 * TODO Make the fct structure standard
 */
function parseHistoryData(seasonData) {
  let output = {}
  fct.meta.stateIds.forEach(rid => {
    output[rid] = seasonIds.map((sid, idx) => {
      if (seasonData[idx] != null) {
        return {
          season: `${sid}-${sid + 1}`,
          data: seasonData[idx][rid].map(({
            epiweek,
            wili
          }) => {
            return {
              week: epiweek,
              data: wili
            }
          })
        }
      }
    })
  })
  return output
}

fct.truth.getSeasonsData(seasonIds).then(d => {
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(parseHistoryData(d)), 'utf8')
  console.log(` Output written at ${OUTPUT_FILE}`)
}).catch(e => {
  console.log(e)
  process.exit(1)
})