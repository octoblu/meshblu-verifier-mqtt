_           = require 'lodash'
commander   = require 'commander'
debug       = require('debug')('meshblu-verifier-mqtt:command')
packageJSON = require './package.json'
Verifier    = require './src/verifier'
MeshbluConfig = require 'meshblu-config'

class Command
  parseOptions: =>
    commander
      .version packageJSON.version
      .parse process.argv

  run: =>
    process.on 'uncaughtException', @die
    @parseOptions()
    meshbluConfig = new MeshbluConfig().toJSON()
    onError = @die
    verifier = new Verifier {meshbluConfig, onError}
    verifier.verify (error) =>
      @die error if error?
      console.log 'meshblu-verifier-mqtt successful'

  die: (error) =>
    return process.exit(0) unless error?
    console.log 'meshblu-verifier-mqtt error'
    console.error error.stack
    process.exit 1

commandWork = new Command()
commandWork.run()
