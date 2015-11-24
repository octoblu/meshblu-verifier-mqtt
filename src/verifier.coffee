_ = require 'lodash'
MeshbluMqtt = require 'meshblu-mqtt'

class Verifier
  constructor: ({@meshbluConfig, @onError}) ->

  _whoami: (callback) =>
    @meshblu = new MeshbluMqtt @meshbluConfig
    @meshblu.connect (response) =>
      @meshblu.whoami (data) =>
        callback null, data

  _unregister: (callback) =>
    callback()

  verify: (callback) =>
    @_whoami (error) =>
      @meshblu.client.end()
      callback error

module.exports = Verifier
