// Script to download files from zoltar

const fs = require('fs-extra')
const path = require('path')
const moment = require('moment')
const mmwr = require('mmwr-week')
const zoltar = require('./zoltar')

// Config
const config = require('./config')

function forecastToFile (forecast) {
  let tzdate = new mmwr.MMWRDate()
  tzdate.fromMomentDate(moment(forecast['timezero_date']))
  return `${tzdate.year}${('0' + tzdate.week).slice(-2)}.csv`
}

(async function () {
  let z = zoltar.zoltar(config['api-root'])
  let project = (await z.projects).find(p => p.name === config.project)
  let models = project.models
  models.forEach(async (m) => {
    // Request
    m = await m
    let modelPath = config.models[m.name]
    let missing = m.forecasts.filter(f => {
      return !fs.existsSync(path.join(modelPath, forecastToFile(f)))
    })
    console.log(`Downloading ${missing.length} files for ${m.name}`)

    missing.forEach(async (f) => {
      let outputFile = path.join(modelPath, forecastToFile(f))
      let csvData = await (await f.forecast).csv
      await fs.writeFile(outputFile, csvData)
    })
  })
})().then(d => console.log(`Done`))
