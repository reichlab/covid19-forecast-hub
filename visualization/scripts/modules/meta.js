/**
 * Module for metadata
 */

const regions = [
  'US National',
  'HHS Region 1',
  'HHS Region 2',
  'HHS Region 3',
  'HHS Region 4',
  'HHS Region 5',
  'HHS Region 6',
  'HHS Region 7',
  'HHS Region 8',
  'HHS Region 9',
  'HHS Region 10'
]

const targets = [
  'Season onset',
  'Season peak week',
  'Season peak percentage',
  '1 wk ahead cum death',
  '2 wk ahead cum death',
  '3 wk ahead cum death',
  '4 wk ahead cum death'
]

const targets_cats = [
  'Cumulative Deaths',
  'Incident Deaths'
]

module.exports.regions = regions
module.exports.targets = targets
module.exports.targets_cats = targets_cats