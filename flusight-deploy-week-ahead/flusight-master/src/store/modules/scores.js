// Getter only scores module

const state = {
  targets: [
    '1-ahead',
    '2-ahead',
    '3-ahead',
    '4-ahead',
    'onset-wk',
    'peak',
    'peak-wk'
  ],
  headersMap: {
    '1-ahead': '1 wk ahead',
    '2-ahead': '2 wk ahead',
    '3-ahead': '3 wk ahead',
    '4-ahead': '4 wk ahead',
    'onset-wk': 'Onset week',
    'peak': 'Peak %',
    'peak-wk': 'Peak week'
  },
  meta: [{
    id: 'absError',
    name: 'Mean Absolute Error',
    url: 'https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Evaluation',
    bestFunc: items => Math.min(...items.filter(d => d !== null)),
    desc: `<a href='https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Evaluation' target='_blank'>
           Absolute error</a> is the absolute value of difference between the eventually
           observe value and point prediction.`
  }, {
    id: 'logScore',
    name: 'Mean Log Score (single bin)',
    url: 'https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Evaluation',
    bestFunc: items => Math.max(...items.filter(d => d !== null)),
    desc: `<a href='https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Evaluation' target='_blank'>
           Single bin log-scores</a> are computed by taking natural log of predicted probability
           for the eventually observed value.`
  }, {
    id: 'logScoreMultiBin',
    name: 'Mean Log Score (multi bin)',
    url: 'https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Evaluation',
    bestFunc: items => Math.max(...items.filter(d => d !== null)),
    desc: `<a href='https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Evaluation' target='_blank'>
           Multi bin log-scores</a> are computed by summing the predicted probabilities around
           a window of the eventually observed values. For the k-week-ahead
           targets, predictions within +/- 0.5 percentage points of the
           eventually observed value are considered accurate. For the targets on
           the scale of weeks, predictions within +/- 1 week of the eventually
           observed value are considered accurate.`
  }]
}

// getters
const getters = {
  scoresMeta: state => state.meta,
  scoresHeadersMap: state => state.headersMap,
  scoresHeaders: state => state.targets.map(t => state.headersMap[t]),
  scoresTargets: state => state.targets
}

export default {
  namespaced: true,
  state,
  getters
}
