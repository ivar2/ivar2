--- Stats about the bot

util = require'util'

-- hardcoded, update as you see fit
hz = 250

--- Line named field reader
lineparser = (fname, fields) ->
  vals = {}
  fd = io.open(fname, 'r')
  data = fd\read'*a'
  fd\close!
  i = 1
  for field in data\gmatch '(.-) '
    -- lazy attempt
    val = tonumber(field) or field
    fname = fields[i] or i
    vals[fname] = val
    i = i +1
  return vals

--- Get all them stats
stats = (source, dest) =>

  vals = lineparser '/proc/self/stat', {'pid', 'comm', 'state', 'ppid', 'pgrp', 'session', 'tty_nr', 'tpgid', 'flags', 'minflt', 'cminflt', 'majflt', 'cmajflt', 'utime', 'stime', 'cutime', 'cstime', 'priority', 'nice', 'num_threads', 'itrealvalue', 'starttime', 'vsize', 'rss', 'rsslim', 'startcode', 'endcode', 'startstack', 'kstkesp', 'kstkeip', 'signal', 'blocked', 'siginore', 'sigcatch', 'wchan', 'nswap', 'cnswap', 'exit_signal', 'processor', 'rt_priority', 'policy', 'delayacct_blkio_ticks', 'guest_time', 'cguest_time', 'start_data', 'end_data', 'start_brk', 'arg_start', 'arg_end', 'env_start', 'env_end', 'exit_codei'}

  local cpu_s
  with vals
    uptime = math.floor .starttime/hz/86400
    cpu_s = "Uptime: #{uptime} days, user time: #{.utime/hz}, system time: #{.stime/hz}"

  mvals = lineparser '/proc/self/statm', {'size', 'resident', 'share', 'text', 'lib', 'data', 'dt'}
  mem_s = "Mem usage: #{math.floor((mvals.size - mvals.resident - mvals.share)/1024)}M"

  modules = 0
  commands = 0
  for moduleName, moduleTable in pairs @Events!['PRIVMSG']
    modules += 1
    for patt, cb in pairs(moduleTable)
      commands += 1
  mod_s = "#{modules} modules loaded totalling #{commands} commands"
  say "#{cpu_s}, #{mem_s}, #{mod_s}"

'PRIVMSG':
  '^%pstats$': stats
