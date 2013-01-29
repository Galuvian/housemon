# see http://jeelabs.org/2013/01/30/remote-compilation/
#
exports.info =
  name: 'jcw-compile'
  description: 'Compile for embedded systems'
  menus: [
    title: 'Compile'
    controller: 'CompileCtrl'
  ]

state = require '../server/state'
fs = require 'fs'
child_process = require 'child_process'
ss = require 'socketstream'

# TODO hardcoded paths for now
SKETCHDIR = switch process.platform
  when 'darwin' then '/Users/jcw/Tools/sketch'
  when 'linux' then '/home/pi/sketchbook/sketch'

# callable from client as: rpc.exec 'host.api', 'compile', path
ss.api.add 'compile', (path, cb) ->
  # TODO totally unsafe, will accept any path as input file
  wr = fs.createWriteStream "#{SKETCHDIR}/sketch.ino"
  fs.createReadStream(path).pipe wr
  wr.on 'close', ->
    make = child_process.spawn 'make', ['upload'], cwd: SKETCHDIR
    make.stdout.on 'data', (data) ->
      ss.api.publish.all 'ss-output', 'stdout', "#{data}"
    make.stderr.on 'data', (data) ->
      ss.api.publish.all 'ss-output', 'stderr', "#{data}"
    make.on 'exit', (code) ->
      cb? null, code

# triggered when bodyParser middleware finishes processing a file upload
state.on 'upload', (url, files) ->
  for file, info of files
    state.store 'uploads',
      key: info.path
      file: file
      name: info.name
      size: info.size
      date: Date.parse(info.lastModifiedDate)

# triggered when the uploads collection changes, used to clean up files
state.on 'store.uploads', (obj, oldObj) ->
  unless obj.key # only act on deletions
    fs.unlink oldObj.key
