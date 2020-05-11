"use strict";
/**
 * Metadata and mappings from abbreviations to corresponding text in csv
 */
Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * The headers expected in the csv files
 */
exports.headers = [
  'location',
  'target',
  'type',
  'unit',
  'quantile',
  'value'
];
/**
 * Short ids representing a region in the code.
 */
exports.regionIds = [
  'nat',
  'hhs1',
  'hhs2',
  'hhs3',
  'hhs4',
  'hhs5',
  'hhs6',
  'hhs7',
  'hhs8',
  'hhs9',
  'hhs10'
];
/**
 * Short ids representing a target in the code.
 */
exports.targetIds = [
  '1-ahead',
  '2-ahead',
  '3-ahead',
  '4-ahead',
  'peak',
  'peak-wk',
  'onset-wk'
];
/**
 * Short ids representing a score in the code.
 */
exports.scoreIds = [
  'logScore',
  'logScoreMultiBin',
  'error',
  'absError'
];
/**
 * Mapping from target ids to full name as used in the csvs
 */
exports.targetFullNameInc = {
  '1-ahead': '1 wk ahead inc death',
  '2-ahead': '2 wk ahead inc death',
  '3-ahead': '3 wk ahead inc death',
  '4-ahead': '4 wk ahead inc death'
};
exports.targetFullNameCum = {
  '1-ahead': '1 wk ahead cum death',
  '2-ahead': '2 wk ahead cum death',
  '3-ahead': '3 wk ahead cum death',
  '4-ahead': '4 wk ahead cum death'
};
/**
 * Target type for each target. Note that there can be only two
 * target types, 'percent' and 'week'.
 */
exports.targetType = {
  '1-ahead': 'percent',
  '2-ahead': 'percent',
  '3-ahead': 'percent',
  '4-ahead': 'percent',
  'peak': 'percent',
  'peak-wk': 'week',
  'onset-wk': 'week'
};
/**
 * Mapping from region ids to full region name as used in
 * the csvs
 */
exports.regionFullName = {
  'nat': 'US National',
  'hhs1': 'HHS Region 1',
  'hhs2': 'HHS Region 2',
  'hhs3': 'HHS Region 3',
  'hhs4': 'HHS Region 4',
  'hhs5': 'HHS Region 5',
  'hhs6': 'HHS Region 6',
  'hhs7': 'HHS Region 7',
  'hhs8': 'HHS Region 8',
  'hhs9': 'HHS Region 9',
  'hhs10': 'HHS Region 10'
};
/**
 * List of US state abbreviations
 */
exports.stateIds = ['nat', 'AK', 'AL', 'AR', 'AZ', 'CA',
  'CO', 'CT', 'DC', 'DE', 'FL',
  'GA', 'HI', 'IA', 'ID', 'IL',
  'IN', 'KS', 'KY', 'LA', 'MA',
  'MD', 'ME', 'MI', 'MN', 'MO',
  'MS', 'MT', 'NC', 'ND', 'NE',
  'NH', 'NJ', 'NM', 'NV', 'NY',
  'OH', 'OK', 'OR', 'PA', 'RI',
  'SC', 'SD', 'TN', 'TX', 'UT',
  'VA', 'VT', 'WA', 'WI', 'WV',
  'WY'
]; // 50

exports.stateForNatIds = ['AK', 'AL', 'AR', 'AZ', 'CA',
  'CO', 'CT', 'DC', 'DE', 'FL',
  'GA', 'HI', 'IA', 'ID', 'IL',
  'IN', 'KS', 'KY', 'LA', 'MA',
  'MD', 'ME', 'MI', 'MN', 'MO',
  'MS', 'MT', 'NC', 'ND', 'NE',
  'NH', 'NJ', 'NM', 'NV', 'NY',
  'OH', 'OK', 'OR', 'PA', 'RI',
  'SC', 'SD', 'TN', 'TX', 'UT',
  'VA', 'VT', 'WA', 'WI', 'WV',
  'WY'
]; // 50

/**
 * Mapping from region ids to the states in those regions
 */
exports.regionStates = {
  'nat': exports.stateForNatIds,
  'hhs1': [6, 19, 21, 30, 39, 46].map(i => exports.stateForNatIds[i]),
  'hhs2': [31, 34].map(i => exports.stateForNatIds[i]),
  'hhs3': [8, 20, 38, 45, 49].map(i => exports.stateForNatIds[i]),
  'hhs4': [1, 9, 10, 17, 25, 27, 40, 42].map(i => exports.stateForNatIds[i]),
  'hhs5': [14, 15, 22, 23, 35, 48].map(i => exports.stateForNatIds[i]),
  'hhs6': [2, 18, 32, 36, 43].map(i => exports.stateForNatIds[i]),
  'hhs7': [12, 16, 24, 29].map(i => exports.stateForNatIds[i]),
  'hhs8': [5, 26, 28, 41, 44, 50].map(i => exports.stateForNatIds[i]),
  'hhs9': [3, 4, 11, 33].map(i => exports.stateForNatIds[i]),
  'hhs10': [0, 13, 37, 47].map(i => exports.stateForNatIds[i])
};
//# sourceMappingURL=meta.js.map 

/**
 * Mapping from state ids to full State name as used in
 * the csvs
 */
exports.stateFullName = {
  'nat': 'US National',
  'AK': 'Alaska',
  'AL': 'Alabama',
  'AR': 'Arkansas',
  'AZ': 'Arizona',
  'CA': 'California',
  'CO': 'Colorado',
  'CT': 'Connecticut',
  'DC': 'District of Columbia',
  'DE': 'Delaware',
  'FL': 'Florida',
  'GA': 'Georgia',
  'HI': 'Hawaii',
  'IA': 'Iowa',
  'ID': 'Idaho',
  'IL': 'Illinois',
  'IN': 'Indiana',
  'KS': 'Kansas',
  'KY': 'Kentucky',
  'LA': 'Louisiana',
  'MA': 'Massachusetts',
  'MD': 'Maryland',
  'ME': 'Maine',
  'MI': 'Michigan',
  'MN': 'Minnesota',
  'MO': 'Missouri',
  'MS': 'Mississippi',
  'MT': 'Montana',
  'NC': 'North Carolina',
  'ND': 'North Dakota',
  'NE': 'Nebraska',
  'NH': 'New Hampshire',
  'NJ': 'New Jersey',
  'NM': 'New Mexico',
  'NV': 'Nevada',
  'NY': 'New York',
  'OH': 'Ohio',
  'OK': 'Oklahoma',
  'OR': 'Oregon',
  'PA': 'Pennsylvania',
  'RI': 'Rhode Island',
  'SC': 'South Carolina',
  'SD': 'South Dakota',
  'TN': 'Tennessee',
  'TX': 'Texas',
  'UT': 'Utah',
  'VA': 'Virginia',
  'VT': 'Vermont',
  'WA': 'Washington',
  'WI': 'Wisconsin',
  'WV': 'West Virginia',
  'WY': 'Wyoming'
};

/**
 * Mapping from state name to state ids
 */
exports.stateStates = {
  'nat': exports.stateForNatIds,
  'AK': [0].map(i => exports.stateForNatIds[i]),
  'AL': [1].map(i => exports.stateForNatIds[i]),
  'AR': [2].map(i => exports.stateForNatIds[i]),
  'AZ': [3].map(i => exports.stateForNatIds[i]),
  'CA': [4].map(i => exports.stateForNatIds[i]),
  'CO': [5].map(i => exports.stateForNatIds[i]),
  'CT': [6].map(i => exports.stateForNatIds[i]),
  'DC': [7].map(i => exports.stateForNatIds[i]),
  'DE': [8].map(i => exports.stateForNatIds[i]),
  'FL': [9].map(i => exports.stateForNatIds[i]),
  'GA': [10].map(i => exports.stateForNatIds[i]),
  'HI': [11].map(i => exports.stateForNatIds[i]),
  'IA': [12].map(i => exports.stateForNatIds[i]),
  'ID': [13].map(i => exports.stateForNatIds[i]),
  'IL': [14].map(i => exports.stateForNatIds[i]),
  'IN': [15].map(i => exports.stateForNatIds[i]),
  'KS': [16].map(i => exports.stateForNatIds[i]),
  'KY': [17].map(i => exports.stateForNatIds[i]),
  'LA': [18].map(i => exports.stateForNatIds[i]),
  'MA': [19].map(i => exports.stateForNatIds[i]),
  'MD': [20].map(i => exports.stateForNatIds[i]),
  'ME': [21].map(i => exports.stateForNatIds[i]),
  'MI': [22].map(i => exports.stateForNatIds[i]),
  'MN': [23].map(i => exports.stateForNatIds[i]),
  'MO': [24].map(i => exports.stateForNatIds[i]),
  'MS': [25].map(i => exports.stateForNatIds[i]),
  'MT': [26].map(i => exports.stateForNatIds[i]),
  'NC': [27].map(i => exports.stateForNatIds[i]),
  'ND': [28].map(i => exports.stateForNatIds[i]),
  'NE': [29].map(i => exports.stateForNatIds[i]),
  'NH': [30].map(i => exports.stateForNatIds[i]),
  'NJ': [31].map(i => exports.stateForNatIds[i]),
  'NM': [32].map(i => exports.stateForNatIds[i]),
  'NV': [33].map(i => exports.stateForNatIds[i]),
  'NY': [34].map(i => exports.stateForNatIds[i]),
  'OH': [35].map(i => exports.stateForNatIds[i]),
  'OK': [36].map(i => exports.stateForNatIds[i]),
  'OR': [37].map(i => exports.stateForNatIds[i]),
  'PA': [38].map(i => exports.stateForNatIds[i]),
  'RI': [39].map(i => exports.stateForNatIds[i]),
  'SC': [40].map(i => exports.stateForNatIds[i]),
  'SD': [41].map(i => exports.stateForNatIds[i]),
  'TN': [42].map(i => exports.stateForNatIds[i]),
  'TX': [43].map(i => exports.stateForNatIds[i]),
  'UT': [44].map(i => exports.stateForNatIds[i]),
  'VA': [45].map(i => exports.stateForNatIds[i]),
  'VT': [46].map(i => exports.stateForNatIds[i]),
  'WA': [47].map(i => exports.stateForNatIds[i]),
  'WI': [48].map(i => exports.stateForNatIds[i]),
  'WV': [49].map(i => exports.stateForNatIds[i]),
  'WY': [50].map(i => exports.stateForNatIds[i])
};