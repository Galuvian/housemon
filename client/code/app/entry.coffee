# This automatically gets called first by SocketStream and must always exist

# Make 'ss' available to all modules and the browser console
window.ss = require 'socketstream'

ss.server.on 'disconnect', ->
  console.log 'Connection down :-('

ss.server.on 'reconnect', ->
  console.log 'Connection back up :-)'

require 'ssAngular'
require '/controllers'

ss.server.on 'ready', ->
  jQuery ->
    require '/app'
