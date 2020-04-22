// Test data files for inconsistencies

const chai = require('chai')
const path = require('path')
const fs = require('fs')
const yaml = require('js-yaml')
const models = require('./modules/models')

chai.should()

// Metadata tests
describe('metadata.txt', function () {
    let modelDirs = models.getModelDirs(
        '../data-processed',
        ['component-models']
    )

    describe('should be present', function () {
        modelDirs.forEach(function (modelDir) {
            it(modelDir, function () {
                fs.existsSync(path.join(modelDir, models.getMetadataFile(modelDir))).should.be.true
            })
        })
    })

    let metadataFiles = modelDirs.map(function (modelDir) {
        return path.join(modelDir, models.getMetadataFile(modelDir))
    })

    describe('should be yaml readable', function () {
        metadataFiles.forEach(function (metaFile) {
            it(metaFile, function (done) {
                try {
                    yaml.safeLoad(fs.readFileSync(metaFile, 'utf8'))
                    done()
                } catch (e) {
                    done(e)
                }
            })
        })
    })

})