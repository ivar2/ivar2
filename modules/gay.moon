{:color, :utf8} = require'util'
FABULOUS_COLORS = {4, 7, 9, 10, 12, 13, 6}

i = 0

gayify = (s) ->
  if s == "" return ""
  s\gsub utf8.pattern, (c) ->
    ret = color(c, FABULOUS_COLORS[i + 1])
    i = (i + 1) % #FABULOUS_COLORS
    return ret

gaywordify = (s) ->
  if s == "" return ""
  ivar2.util.translateWords s, (c) ->
    ret = color(c, FABULOUS_COLORS[i + 1])
    i = (i + 1) % #FABULOUS_COLORS
    return ret

PRIVMSG:
  '^%pgay (.+)$': (source, destination, arg) =>
      say gayify arg
  '^%pgaywords (.+)$': (source, destination, arg) =>
      say gaywordify arg
  '^%pfabulous (.+)$': (source, destination, arg) =>
      say gaywordify arg
