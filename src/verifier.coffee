_ = require 'lodash'
MeshbluMqtt = require 'meshblu-mqtt'
debug = require('debug')('meshblu-verifier-mqtt')

class Verifier
  constructor: ({@meshbluConfig, @onError}) ->

  _whoami: (callback) =>
    @meshblu = new MeshbluMqtt @meshbluConfig
    @meshblu.connect (response) =>
      # @meshblu.message {device:'*',payload:'hello world'}, (error, data) =>
        # callback error, data
      @meshblu.whoami (error, data) =>
        console.log {error, data}
        callback null, data

  _subscribeSelf: (callback) =>
    debug '+ subscribeSelf'
    subscription =
      emitterUuid: @meshbluConfig.uuid
      subscriberUuid: @meshbluConfig.uuid
      type: 'message.received'

    @meshblu.subscribe @meshbluConfig.uuid, subscription, (error, data) =>
      debug {error,data}
      callback error

  _unregister: (callback) =>
    callback()

  verify: (callback) =>
    @_whoami (error) =>
      @_subscribeSelf (error) =>
        @meshblu.message {devices: [@meshbluConfig.uuid], payload: 'hello world'}, (error) =>
          debug 'message:', {error}
          setTimeout =>
            @meshblu.client.end()
            callback error
          , 3000

module.exports = Verifier
