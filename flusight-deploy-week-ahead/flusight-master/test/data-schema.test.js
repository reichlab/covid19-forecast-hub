/**
 * Test data files for schema compliance
 */

/* global describe it */

const chai = require('chai')
const fs = require('fs')

chai.use(require('chai-json-schema'))
chai.should()

describe('History.json', function () {
  it('should comply with history.schema.json', function (done) {
    fs.readFile('./src/assets/data/history.json', 'utf8', function (err, data) {
      if (err) throw err
      let dataJSON = JSON.parse(data)
      fs.readFile('./schema/history.schema.json', 'utf8', function (err, data) {
        if (err) throw err
        let schema = JSON.parse(data)
        dataJSON.should.be.jsonSchema(schema)
        done()
      })
    })
  })
})

describe('Metadata.json', function () {
  it('should comply with metadata.schema.json', function (done) {
    fs.readFile('./src/assets/data/metadata.json', 'utf8', function (err, data) {
      if (err) throw err
      let dataJSON = JSON.parse(data)
      fs.readFile('./schema/metadata.schema.json', 'utf8', function (err, data) {
        if (err) throw err
        let schema = JSON.parse(data)
        dataJSON.should.be.jsonSchema(schema)
        done()
      })
    })
  })
})
