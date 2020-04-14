/**
 * Utilities
 */

export const parseDataResponse = response => {
  let jsonText = response.bodyText.slice(17)
  if (jsonText.endsWith(';')) {
    jsonText = jsonText.slice(0, -1)
  }
  return JSON.parse(jsonText)
}
