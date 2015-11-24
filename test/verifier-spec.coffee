shmock = require 'shmock'
Verifier = require '../src/verifier'
MockMeshbluMQTT = require './mock-meshblu-mqtt'

describe 'Verifier', ->
  beforeEach (done) ->
    @whoamiHandler = sinon.stub()

    onPublished = (packet, publish) =>
      {topic, payload} = packet

      if topic == 'whoami'
        @whoamiHandler payload, (response) =>
          @meshblu.publish 'some-device', 'whoami', response

    @meshblu = new MockMeshbluMQTT port: 0xd00d, onPublished: onPublished
    @meshblu.start done

  afterEach (done) ->
    @meshblu.stop => done()

  describe '-> verify', ->
    beforeEach ->
      meshbluConfig = hostname: 'localhost', port: 0xd00d, uuid: 'some-device', token: 'some-token'
      @sut = new Verifier {meshbluConfig}

    context 'when everything works', ->
      beforeEach ->
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'

      beforeEach (done) ->
        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@whoamiHandler).to.be.called
