// Script for finding week number for ensemble file creation process
const mmwr = require('mmwr-week')
const models = require('./modules/models')

const travisCommitMessage = process.env.TRAVIS_COMMIT_MESSAGE
const travisEventType = process.env.TRAVIS_EVENT_TYPE

const getCommitWeek = message => {
  if (travisEventType === 'cron') {
    return NaN
  } else if (travisCommitMessage) {
    let pattern = /week\ [0-5]?[0-9]/
    let splits = travisCommitMessage.trim().match(pattern)[0].split(' ')
    return parseInt(splits[1])
  } else {
    return NaN
  }
}

const incrementTimeStamp = ts => {
  let year = Math.trunc(ts / 100)
  let week = ts % 100
  let mdate = new mmwr.MMWRDate(year, week)
  mdate.applyWeekDiff(1)
  return mdate.year * 100 + mdate.week
}

let commitWeek = getCommitWeek()

if (isNaN(commitWeek)) {
  // Figure out the week by other means
  let submissionDir = models.getModelDirs(
    './model-forecasts',
    ['submissions']
  )[0]

  let modelCsvs = models.getModelCsvs(submissionDir)
  let modelTimeStamps = modelCsvs
      .map(models.getCsvTime)
      .map(time => parseInt(time.year) * 100 + parseInt(time.epiweek))

  let currentWeek = incrementTimeStamp(
    modelTimeStamps.sort((a, b) => b - a)[0]
  ) % 100

  process.stdout.write(currentWeek + '')

} else {
  process.stdout.write(commitWeek + '')
}
