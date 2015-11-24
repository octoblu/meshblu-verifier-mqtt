http = require 'http'
mosca = require 'mosca'

class MockMeshbluMQTT
  constructor: (options) ->
    {@onPublished, @port} = options

  start: (callback) =>
    @server = new mosca.Server port: @port
    @server.on 'published', @onPublished

    @server.on 'ready', callback

  publish: (uuid, topic, payload) =>
    @server.publish topic: uuid, payload: JSON.stringify {topic, payload}

  stop: (callback) =>
    @server.close callback

module.exports = MockMeshbluMQTT
