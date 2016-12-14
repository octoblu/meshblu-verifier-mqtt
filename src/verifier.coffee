_           = require 'lodash'
async       = require 'async'
MeshbluMqtt = require 'meshblu-mqtt'

class Verifier
  constructor: ({@meshbluConfig, @onError, @nonce}) ->
    @nonce ?= Date.now()

  verify: (callback) =>
    async.series [
      @_connect
      @_whoami
      @_message
      @_update
      @_close
    ], (error) =>
      callback error

  _connect: (callback) =>
    @meshblu = new MeshbluMqtt @meshbluConfig
    @meshblu.connect (response) =>
      callback()

  _close: (callback) =>
    @meshblu.close callback

  _message: (callback) =>
    @meshblu.once 'message', (data) =>
      return callback new Error 'wrong message received' unless data?.payload == @nonce
      callback()

    message =
      devices: [@meshbluConfig.uuid]
      payload: @nonce

    @meshblu.message message

  _update: (callback) =>
    return callback() unless @device?

    params =
      uuid: @meshbluConfig.uuid
      nonce: @nonce

    @meshblu.update params, (data) =>
      return callback new Error data.error if data?.error?
      @meshblu.whoami (data) =>
        return callback new Error 'update failed' unless data?.nonce == @nonce
        callback()

  _whoami: (callback) =>
    @meshblu.whoami (data) =>
      return callback new Error data.error if data?.error?
      callback()

module.exports = Verifier
