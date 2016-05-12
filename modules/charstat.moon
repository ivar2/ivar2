store = ivar2.persist

key = (c) ->
  "charstat:#{c}"


PRIVMSG:
  '^[a-zA-Z]$': (source, destination, c) =>
    c = c\lower!
    cur = store[key c]
    cur = tonumber(cur) or 0
    cur = cur + 1
    store[key c] = cur
  '^%pcharwin$': (source, destination) =>
    chars = 'abcdefghijklmnopqrstuvxyz'
    out = {}
    i = 1
    for c in chars\gmatch '.'
      cur = store[key c]
      cur = tonumber(cur) or 0
      out[i] = {:c,:cur}
      i = i + 1

    table.sort out, (a, b) ->
      if a.cur > b.cur
        return true
      return false

    out_s = {}
    for i, v in ipairs(out)
      if i > 5
        break
      if v.cur > 0
        out_s[#out_s+1] = "#{ivar2.util.bold v.c}: #{v.cur}"

    say "Winners: #{table.concat(out_s, ' ')}"
