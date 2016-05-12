_           = require 'lodash'
async       = require 'async'
debug       = require('debug')('meshblu-verifier-mqtt')
MeshbluMqtt = require 'meshblu-mqtt'

class Verifier
  constructor: ({@meshbluConfig, @onError}) ->
    @nonce = Date.now()
    @someUuidToCreate = "master-of-the-universe-#{@nonce}"

  _connect: (callback) =>
    debug '+ connect'
    @meshbluConfig.rejectUnauthorized = false
    @meshbluConfig.bridged = true
    @meshblu = new MeshbluMqtt @meshbluConfig
    @meshblu.on 'meshblu/message', @_onMessage
    @meshblu.on 'meshblu/error', (message) =>
       throw new Error message
    @meshblu.connect (response) =>
      callback()

  _updateSetData: (callback) =>
    debug '+ updateSetData'
    @meshblu.update @meshblu.uuid, {$set: nonce: @nonce, thing: @someUuidToCreate}, (error, data) =>
      debug 'updateSetData:', {error, data}
      callback null, data

  _updateRenameData: (callback) =>
    debug '+ updateRenameData'
    @meshblu.update @meshblu.uuid, {$rename: thing: 'uuid'}, (error, data) =>
      debug 'updateSetData:', {error, data}
      callback null, data

  _whoami: (callback) =>
    debug '+ whoami'
    @meshblu.whoami (error, data) =>
      debug 'whoami:', {error, data}
      callback error, data

  _whoamiCheckUuid: (callback) =>
    debug '+ whoamiCheckUuid'
    @_whoami (error, data) =>
      return callback(new Error 'whoami uuid invalid') if !data? or @meshbluConfig.uuid != data.uuid
      callback error, data

  _whoamiCheckUuidAndNonce: (callback) =>
    debug '+ whoamiCheckUuidAndNonce'
    @_whoamiCheckUuid (error, data) =>
      return callback(new Error 'whoami nonce invalid') if !data? or @nonce != data.nonce
      callback error, data

  _whoamiNull: (callback) =>
    debug '+ whoamiNull'
    @_whoami (error, data) =>
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

  _connectFirehose: (callback) =>
    debug '+ connectFirehose'
    @meshblu.connectFirehose null, (error, data) =>
      debug 'connectFirehose:', {error, data}
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

    async.series [
      @_connect
      @_register
      @_close
      @_connect
      @_whoamiCheckUuid
      @_updateSetData
      @_whoami
      @_updateRenameData
      @_whoamiCheckUuidAndNonce
      @_connectFirehose
      # @_subscribeSelf
      @_message
      @_verifyResponse
      # @_subscribeConfig
      @_unregister
      @_whoamiNull
    ], (error) =>
      @_unregister =>
        @_close =>
          callback(error)

module.exports = Verifier
