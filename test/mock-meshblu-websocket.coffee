http = require 'http'
WebSocket = require 'faye-websocket'

class MockMeshbluWebsocket
  constructor: (options) ->
    {@onConnection, @port} = options

  start: (callback) =>
    @server = http.createServer()
    @server.on 'upgrade', @_onUpgrade
    @server.listen @port, callback

  stop: (callback) =>
    @server.close callback

  _onUpgrade: (request, socket, body) =>
    return unless WebSocket.isWebSocket request

    ws = new WebSocket request, socket, body
    @onConnection ws

module.exports = MockMeshbluWebsocket
