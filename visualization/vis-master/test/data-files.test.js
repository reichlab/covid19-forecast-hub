/**
 * Test the expected data files in ./src/assets/data
 */

/* global describe it */
const chai = require('chai')
const path = require('path')
const fs = require('fs')

chai.should()

describe('History file', function () {
  it('should be generated', function () {
    fs.existsSync('./src/assets/data/history.json').should.be.true
  })
})

describe('Metadata file', function () {
  it('should be generated', function () {
    fs.existsSync('./src/assets/data/metadata.json').should.be.true
  })
})

describe('Season data files should be generated', function () {
  // Get a list of seasons from the ./data directory
  let seasons = fs.readdirSync('./data').filter(file => {
    return fs.statSync(path.join('./data', file)).isDirectory()
  })
  seasons[seasons.length - 1] = 'latest'

  seasons.forEach(season => {
    let fileName = `season-${season}.json`
    it(fileName, function () {
      fs.existsSync(`./src/assets/data/${fileName}`).should.be.true
    })
  })
})

// describe('Score files should be generated', function () {
//   // Get a list of seasons from the ./data directory
//   let seasons = fs.readdirSync('./data').filter(file => {
//     return fs.statSync(path.join('./data', file)).isDirectory()
//   })
//   seasons[seasons.length - 1] = 'latest'

//   seasons.forEach(season => {
//     let fileName = `scores-${season}.json`
//     it(fileName, function () {
//       fs.existsSync(`./src/assets/data/${fileName}`).should.be.true
//     })
//   })
// })

describe('Distribution data files should be generated', function () {
  // Get a list of seasons from the ./data directory
  let seasons = fs.readdirSync('./data').filter(file => {
    return fs.statSync(path.join('./data', file)).isDirectory()
  })

  let regions = ['nat', 'hhs1', 'hhs2', 'hhs3', 'hhs4', 'hhs5', 'hhs6', 'hhs7', 'hhs8', 'hhs9', 'hhs10']

  seasons.forEach(season => {
    regions.forEach(region => {
      let distFileName
      if ((season === seasons[seasons.length - 1]) && (region === 'nat')) {
        distFileName = 'season-latest-nat.json'
      } else {
        distFileName = `season-${season}-${region}.json`
      }
      it(distFileName, function () {
        fs.existsSync(`./src/assets/data/distributions/${distFileName}`).should.be.true
      })
    })
  })
})