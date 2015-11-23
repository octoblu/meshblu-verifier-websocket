_ = require 'lodash'
async = require 'async'
MeshbluWebsocket = require 'meshblu-websocket'

class Verifier
  constructor: ({@meshbluConfig, @onError}) ->

  _connect: =>
    @meshblu = new MeshbluWebsocket @meshbluConfig

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
      @_unregister
    ], (error) =>
      @meshblu.close()
      callback error

module.exports = Verifier
