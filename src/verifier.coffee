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

  _update: (callback) =>
    @meshblu.once 'whoami', (data) =>
      return callback new Error 'update failed' unless data?.nonce == @nonce
      callback null, data

    @meshblu.once 'updated', (data) =>
      @meshblu.whoami()

    @meshblu.removeAllListeners 'error'
    @meshblu.once 'error', (data) =>
      callback new Error 'Update Error:', JSON.stringify(data, null, 2)

    query = uuid: @meshbluConfig.uuid
    params =
      uuid: @meshbluConfig.uuid
      nonce: @nonce

    @meshblu.update(query, params)

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
      @_update
      @_unregister
    ], (error) =>
      @meshblu.close()
      callback error

module.exports = Verifier
