{:json, :simplehttp, :bold} = require'util'

round = (x) ->
  x + 0.5 - (x + 0.5) % 1

PRIVMSG:
  '^%pinnev.+r$': (source, destination, input) =>
    simplehttp ivar2.config.cubeapiurl, (data) ->
      result = json.decode data
      if result
        r = result[1]
        temp = r.rtemp
        noise = tonumber(r.noisedba) or 0
        say '\002%.1f\002 °C, \002%s\002 ppm, \002%s\002 %, \002%s\002 lux, \002%s\002 dBA', temp, round(r.voc), round(r.humidity), round(r.light), noise
