_           = require 'lodash'
commander   = require 'commander'
debug       = require('debug')('meshblu-verifier-websocket:command')
packageJSON = require './package.json'
Verifier    = require './src/verifier'
MeshbluConfig = require 'meshblu-config'

class Command
  parseOptions: =>
    commander
      .version packageJSON.version
      .parse process.argv

  run: =>
    @parseOptions()
    timeoutSeconds = 30
    timeoutSeconds = parseInt(process.env.TIMEOUT_SECONDS) if process.env.TIMEOUT_SECONDS
    setTimeout @timeoutAndDie, timeoutSeconds * 1000
    meshbluConfig = new MeshbluConfig().toJSON()
    verifier = new Verifier {meshbluConfig}
    verifier.verify (error) =>
      @die error if error?
      console.log 'meshblu-verifier-websocket successful'

  die: (error) =>
    return process.exit(0) unless error?
    console.log 'meshblu-verifier-websocket error'
    console.error error.stack
    process.exit 1

  timeoutAndDie: =>
    console.log 'meshblu-verifier-websocket timeout'
    @die new Error 'Timeout Exceeded'

commandWork = new Command()
commandWork.run()
