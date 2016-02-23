_ = require 'lodash'
async = require 'async'
MeshbluWebsocket = require 'meshblu-websocket'

class Verifier
  constructor: ({@meshbluConfig, @onError, @nonce}) ->
    @nonce ?= Date.now()

  _connect: =>
    @meshblu = new MeshbluWebsocket @meshbluConfig

  _message: (callback) =>
    @meshblu.once 'message', (data) =>
      return callback new Error 'wrong message received' unless data?.payload == @nonce
      callback()

    message =
      devices: [@meshbluConfig.uuid]
      payload: @nonce

    @meshblu.message message

  _register: (callback) =>
    @_connect()
    @meshblu.connect (error) =>
      return callback error if error?

      @meshblu.once 'error', (data) =>
        callback new Error data

      @meshblu.once 'registered', (data) =>
        @device = data
        @meshbluConfig.uuid = @device.uuid
        @meshbluConfig.token = @device.token
        @meshblu.close()
        @_connect()
        @meshblu.connect (error) =>
          return callback error if error?
          callback()

      @meshblu.register type: 'meshblu:verifier'

  _whoami: (callback) =>
    @meshblu.once 'whoami', (data) =>
      callback null, data

    @meshblu.removeAllListeners 'error'
    @meshblu.once 'error', (data) =>
      callback new Error data

    @meshblu.whoami()

  _unregister: (callback) =>
    return callback() unless @device?
    @meshblu.once 'unregistered', (data) =>
      callback null, data

    @meshblu.removeAllListeners 'error'
    @meshblu.once 'error', (data) =>
      callback new Error data

    @meshblu.unregister @device

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_message
      @_unregister
    ], (error) =>
      @meshblu.close()
      callback error

module.exports = Verifier
