const yaml = require('js-yaml')
const fs = require('fs-extra')
const path = require('path')
const models = require('./modules/models')
const util = require('./modules/util')
const meta = require('./modules/meta')
const mmwr = require('mmwr-week')
const moment = require('moment')

const parseMetadata = (modelDir) => {
  // Return a flusight compatible metadata object
  let rootMetadata = models.getModelMetadata(modelDir)
  let desc = rootMetadata.methods
  let descMaxLen = 400
  if (desc.length > descMaxLen) {
    desc = desc.slice(0, descMaxLen) + '...'
  }
  let repoUrl = 'https://github.com/reichlab/covid19-death-forecasts'
  let metaPath = repoUrl + '/blob/master/' + path.join(modelDir.slice(3), models.getMetadataFile(modelDir))
  let linkToMore = " Click <i class='icon-link-ext'></i> for more."
  return {
    name: rootMetadata.team_name + ' - ' + rootMetadata.model_name,
    description: desc + linkToMore,
    url: metaPath
  }
}

const ensureMetadata = (filePath, data) => {
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, yaml.safeDump(data))
  }
}

const parseCSVInfo = (fileName) => {
  // Return season and formatted name for the csv
  let splits = fileName.split('-')
  let year = parseInt(splits[0])
  let month = parseInt(splits[1])
  let day = parseInt(splits[2])
  let epiDate = fileName.slice(0, 10)
  let mdate = new mmwr.MMWRDate(2016, 48)
  mdate.fromMomentDate(moment(epiDate))
  let epiweek = mdate.week // shift data by 1
  if (mdate.day > 2) { // forecast is on a Tuesday - Saturday
    epiweek = epiweek + 1;
  }
  // Week >=30 of year X are in season {X}-{X+1}
  // Week <30 of year Y are in season {Y-1}-{Y}
  return {
    name: `${year * 100 + epiweek}.csv`,
    season: epiweek >= 30 ? `${year}-${year+1}` : `${year-1}-${year}`
  }
}

// Main entry point
let modelDirs = models.getModelDirs(
  '../data-processed',
  ['component-models']
)

modelDirs.forEach(modelDir => {
  // Read metadata and parse to usable form
  let flusightMetadata = parseMetadata(modelDir)
  let modelId = models.getModelId(modelDir)
  let target_categories = meta.targets_cats

  target_categories.forEach(target_cats => // Cumulative Deaths, Incident Deaths
    models.getModelCsvs(modelDir)
    .forEach(csvFile => {
      let info = parseCSVInfo(path.basename(csvFile))

      // CSV target path
      let csvTargetDir = path.join('./data', target_cats, modelId)
      fs.ensureDirSync(csvTargetDir)

      // Copy csv
      fs.copySync(csvFile, path.join(csvTargetDir, info.name))

      // Write metadata
      ensureMetadata(path.join(csvTargetDir, 'meta.yml'), flusightMetadata)
    })
  )
})