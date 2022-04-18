//import history from '!json!../assets/data/history.json'
import metadata from '!json!../assets/data/metadata.json'

// Loading latest data in the main bundle itself
import latestSeasonData from '!json!../assets/data/season-latest.json'
// import latestScoresData from '!json!../assets/data/scores-latest.json'
import latestDistData from '!json!../assets/data/distributions/season-latest-nat.json'

import incCaseSeasonData from '!json!../assets/data/season-Incident Cases.json'

import incDeathSeasonData from '!json!../assets/data/season-Incident Deaths.json'

const seasonDataCtx = require.context(
  'file-loader!../assets/data/',
  false,
  /^\.\/season.*\.json$/
)

// const scoresDataCtx = require.context(
//   'file-loader!../assets/data/',
//   false,
//   /^\.\/scores.*\.json$/
// )

const distDataCtx = require.context(
  'file-loader!../assets/data/distributions/',
  false,
  /^\.\/.*\.json$/
)

const seasonDataUrls = seasonDataCtx.keys().reduce((acc, key) => {
  if (key.startsWith('./season-')) {
    // Identifier is like '2013-2014'
    acc[key.slice(9, -5)] = seasonDataCtx(key)
  }
  return acc
}, {})

// const scoresDataUrls = scoresDataCtx.keys().reduce((acc, key) => {
//   if (key.startsWith('./scores-')) {
//     // Identifier is like '2013-2014'
//     acc[key.slice(9, -5)] = scoresDataCtx(key)
//   }
//   return acc
// }, {})

const distDataUrls = distDataCtx.keys().reduce((acc, key) => {
  if (key.startsWith('./season-')) {
    // Identifier is like '2013-2014-hhs10'
    acc[key.slice(9, -5)] = distDataCtx(key)
  }
  return acc
}, {})

export {
  seasonDataUrls,
  // scoresDataUrls,
  distDataUrls,
  latestSeasonData,
  // latestScoresData,
  latestDistData,
  incCaseSeasonData,
  incDeathSeasonData,
  //history,
  metadata
}