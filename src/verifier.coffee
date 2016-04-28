_           = require 'lodash'
async       = require 'async'
debug       = require('debug')('meshblu-verifier-mqtt')
MeshbluMqtt = require 'meshblu-mqtt'

class Verifier
  constructor: ({@meshbluConfig, @onError}) ->

  _connect: (callback) =>
    debug '+ connect'
    @meshblu = new MeshbluMqtt @meshbluConfig
    @meshblu.on 'message', @_onMessage
    @meshblu.connect (response) =>
      callback()

  _whoami: (callback) =>
    debug '+ whoami'
    @meshblu.whoami (error, data) =>
      debug 'whoami:', {error, data}
      return callback(new Error 'whoami invalid') if !data? or @meshbluConfig.uuid != data.uuid
      callback error, data

  _whoamiNull: (callback) =>
    debug '+ whoamiNull'
    @meshblu.whoami (error, data) =>
      debug 'whoamiNull:', {error, data}
      return callback(new Error 'whoamiNull is not null') if data?
      callback null, data

  _subscribeSelf: (callback) =>
    debug '+ subscribeSelf'
    subscription =
      emitterUuid: @meshbluConfig.uuid
      subscriberUuid: @meshbluConfig.uuid
      type: 'message.received'

    @meshblu.subscribe @meshbluConfig.uuid, subscription, (error, data) =>
      debug 'subscribeSelf:', {error, data}
      callback error, data

  _register: (callback) =>
    debug '+ register'
    @meshblu.register null, (error, data) =>
      debug 'register:', {error, data}
      @meshbluConfig.uuid = data.uuid
      @meshbluConfig.token = data.token
      callback error, data

  _unregister: (callback) =>
    debug '+ unregister'
    @meshblu.unregister @meshbluConfig.uuid, (error, data) =>
      debug 'unregister:', {error, data}
      callback error, data

  _message: (callback) =>
    debug '+ message'
    message =
      devices: [@meshbluConfig.uuid]
      payload: @nonce

    @meshblu.message message, (error) =>
      debug 'message:', {error}
      callback error

  _verifyResponse: (callback) =>
    (
      verify = =>
        return setTimeout(verify, 100) unless @receivedMessage?
        return callback(new Error 'invalid response') if @receivedMessage.payload != @nonce
        callback()
    )()

  _close: (callback) =>
    @meshblu.client.end()
    callback()

  _onMessage: (message) =>
    debug '+ onMessage'
    debug 'onMessage:', {message}
    @receivedMessage = message

  verify: (callback) =>
    delete @meshbluConfig.uuid
    delete @meshbluConfig.token
    @nonce = Date.now()

    async.series [
      @_connect
      @_register
      @_close
      @_connect
      @_whoami
      # @_subscribeSelf
      @_message
      @_verifyResponse
      # @_subscribeConfig
      # @_update
      @_unregister
      @_whoamiNull
    ], (error) =>
      @_close =>
        callback(error)

module.exports = Verifier
