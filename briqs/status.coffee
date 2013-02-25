exports.info =
  name: 'status'
  description: 'Collect and show the current status'
  menus: [
    title: 'Status'
  ]
  connections:
    feeds:
      'readings': 'collection'
    results:
      'status': 'collection'
  
state = require '../server/state'

models = state.models

adjustValue = (value, info) ->
  if info.factor
    value *= info.factor
  if info.scale < 0
    value *= Math.pow 10, -info.scale
  else if info.scale >= 0
    value /= Math.pow 10, info.scale
    value = value.toFixed info.scale
  value

updateStatus = (obj, loc, info, param, value) ->
  key = "#{loc.title} - #{info.title}"
  tag = obj.key.split '.'
  adj = adjustValue value, info

  state.store 'status',
    key: key
    location: loc.title
    parameter: info.title
    value: adj
    unit: info.unit
    time: obj.time
    origin: tag[0]
    type: tag[1]
    name: param
    origval: value
    factor: info.factor
    scale: info.scale

# TODO linear search, should be replaced by hash index
# TODO location and driver lookup depend on timestamp of the reading
findKey = (collection, key) ->
  for k,v of collection
    if key is v.key
      return v

processReading = (obj, oldObj) ->
  if obj
    [locName, other..., drvName] = obj.key.split '.'

    loc = findKey models.locations, locName
    unless loc
      loc = findKey models.locations, drvName
      drvName = drvName?.replace /-.*/, ''
    drv = findKey models.drivers, drvName

    if loc and drv
      for param, value of obj
        unless param in ['id','key']
          info = drv[param]
          updateStatus obj, loc, info, param, value  if info

exports.factory = class

  constructor: ->
    state.on 'set.readings', processReading

  destroy: ->
    state.off 'set.readings', processReading
