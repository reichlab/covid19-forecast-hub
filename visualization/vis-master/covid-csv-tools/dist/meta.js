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
exports.targetFullNameIncCase = {
  '1-ahead': '1 wk ahead inc case',
  '2-ahead': '2 wk ahead inc case',
  '3-ahead': '3 wk ahead inc case',
  '4-ahead': '4 wk ahead inc case'
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
exports.stateIds = [
  'nat',
  'AK', 'AL', 'AR', 'AS', 'AZ',
  'CA', 'CO', 'CT', 'DC', 'DE',
  'FL', 'GA', 'GU', 'HI', 'IA',
  'ID', 'IL', 'IN', 'KS', 'KY',
  'LA', 'MA', 'MD', 'ME', 'MI',
  'MN', 'MO', 'MS', 'MT', 'NC',
  'ND', 'MP', 'NE', 'NH', 'NJ',
  'NM', 'NV', 'NY', 'OH', 'OK',
  'OR', 'PA', 'PR', 'RI', 'SC',
  'SD', 'TN', 'TX', 'UT', 'VA',
  'VI', 'VT', 'WA', 'WI', 'WV',
  'WY'  
]; // 56

exports.stateForNatIds = [
  'AK', 'AL', 'AR', 'AS', 'AZ',
  'CA', 'CO', 'CT', 'DC', 'DE',
  'FL', 'GA', 'GU', 'HI', 'IA',
  'ID', 'IL', 'IN', 'KS', 'KY',
  'LA', 'MA', 'MD', 'ME', 'MI',
  'MN', 'MO', 'MS', 'MT', 'NC',
  'ND', 'MP', 'NE', 'NH', 'NJ',
  'NM', 'NV', 'NY', 'OH', 'OK',
  'OR', 'PA', 'PR', 'RI', 'SC',
  'SD', 'TN', 'TX', 'UT', 'VA',
  'VI', 'VT', 'WA', 'WI', 'WV',
  'WY'
]; // 55

/**
 * Mapping from region ids to the states in those regions
 */
exports.regionStates = {
  'nat': exports.stateForNatIds,
  'hhs1': ['CT', 'ME', 'MA', 'NH', 'RI', 'VT'],
  'hhs2': ['NJ', 'NY', 'PR', 'VI'],
  'hhs3': ['DE', 'DC', 'MD', 'PA', 'VA', 'WV'],
  'hhs4': ['AL', 'FL', 'GA', 'KY', 'MS', 'NC', 'SC', 'TN'],
  'hhs5': ['IL', 'IN', 'MI', 'MN', 'OH', 'WI'],
  'hhs6': ['AR', 'LA', 'NM', 'OK', 'TX'],
  'hhs7': ['IA', 'KS', 'MO', 'NE'],
  'hhs8': ['CO', 'MT', 'ND', 'SD', 'UT', 'WY'],
  'hhs9': ['AZ', 'AS', 'CA', 'HI', 'NV', 'MP'],
  'hhs10': ['AK', 'ID', 'OR', 'WA']
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
  'WY': 'Wyoming',
  'PR': 'Puerto Rico',
  'VI': 'Virgin Islands',
  'GU': 'Guam',
  'MP': 'Northern Mariana Islands',
  'AS': 'American Samoa'
};

/**
 * Mapping from state name to state ids
 * TODO: [refactor] this is a "hacky" use of original functionality
 */
exports.stateStates = {
  'nat': exports.stateForNatIds,
  'AK': ['AK'], 'AL': ['AL'], 'AR': ['AR'], 'AZ': ['AZ'], 'CA': ['CA'], 'CO': ['CO'],
  'CT': ['CT'], 'DC': ['DC'], 'DE': ['DE'], 'FL': ['FL'], 'GA': ['GA'], 'HI': ['HI'],
  'IA': ['IA'], 'ID': ['ID'], 'IL': ['IL'], 'IN': ['IN'], 'KS': ['KS'], 'KY': ['KY'],
  'LA': ['LA'], 'MA': ['MA'], 'MD': ['MD'], 'ME': ['ME'], 'MI': ['MI'], 'MN': ['MN'],
  'MO': ['MO'], 'MS': ['MS'], 'MT': ['MT'], 'NC': ['NC'], 'ND': ['ND'], 'NE': ['NE'],
  'NH': ['NH'], 'NJ': ['NJ'], 'NM': ['NM'], 'NV': ['NV'], 'NY': ['NY'], 'OH': ['OH'],
  'OK': ['OK'], 'OR': ['OR'], 'PA': ['PA'], 'RI': ['RI'], 'SC': ['SC'], 'SD': ['SD'],
  'TN': ['TN'], 'TX': ['TX'], 'UT': ['UT'], 'VA': ['VA'], 'VT': ['VT'], 'WA': ['WA'],
  'WI': ['WI'], 'WV': ['WV'], 'WY': ['WY'], 'PR': ['PR'], 'VI': ['VI'], 'GU': ['GU'],
  'MP': ['MP'], 'AS': ['AS']
};