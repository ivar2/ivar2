-- Clue module requires clue data files and tosql.py from emnh/clue2

dbi = require 'DBI'
require'logging.console'
log = logging.console()
conn = false

attrs = {'grammar','reference', 'country', 'context', 'text'}

connect = ->
  conn, err = DBI.Connect('PostgreSQL', ivar2.config.dbname, ivar2.config.dbuser, ivar2.config.dbpass, ivar2.config.dbhost, ivar2.config.dbport)
  unless conn
    log\error "Unable to connect to DB: #{err}"
    return

  conn\autocommit(true)

dbh = ->
  connect! unless conn

  -- Check if connection is alive
  alive = conn\ping!
  connect! unless alive

  success, err = DBI.Do(conn, 'SELECT NOW()')
  unless success
    log\error "SQL Connection :#{err}"
    connect!

  return conn

lookup = (source, destination, lookup) =>
  stmt = dbh!\prepare [[
    SELECT
      tablename
    from
      pg_catalog.pg_tables
    where
      tablename like 'cl%'
    ]]
  stmt\execute!
  tables = {}
  for row in stmt\rows(true) -- true for column names
    tables[#tables+1] = row.tablename

  out = {}
  for dict in *tables
    out[dict] = {}
    stmt = dbh!\prepare [[
      SELECT
        *
      FROM
        ]]..dict..[[
      WHERE
        word = ?
      ]]
    stmt\execute lookup
    for row in stmt\rows(true) -- true for column names
      table.insert(out[dict], row)


  i = 0
  for dict, rows in pairs out
    res = {}
    dfrom = dict\sub(3, 4)
    to = dict\sub(5, 6)
    first = true
    for row in *rows
      i += 1
      if first
        table.insert(res, "[#{ivar2.util.bold row.word}]")
        table.insert(res, "(#{ivar2.util.italic dfrom}")
        table.insert(res, "-> #{ivar2.util.italic to})")
        first = false
      for attr in *attrs
        if row[attr] != nil and row[attr] != ''
          if attr == 'grammar'
            table.insert(res, "(#{row[attr]}. )")
          else
            table.insert(res, row[attr])
    say table.concat(res, ' ')
  if i == 0
    reply 'Nope.'

upper = (s) ->
  (string.upper(s)\gsub('æ','Æ')\gsub('ø','Ø')\gsub('å','Å'))

getWord = (lang, wordclass, count, maxlen, startswith) ->
  unless startswith
    startswith = ''
  else
    startswith = "AND left(word,1) = '#{startswith}'"
  sql = [[
    SELECT
     *
    FROM
      ]]..lang..[[
    WHERE
      grammar = ?
    AND
      length(word) < ?
    ]]..startswith..[[
    ORDER BY
      random()
    LIMIT ?
  ]]
  stmt = dbh!\prepare sql
  stmt\execute wordclass, maxlen, count
  out = {}
  for row in stmt\rows(true) -- true for column names
    table.insert(out, row)
  return out

bankid = (source, destination) =>

  adj = getWord 'clnono', 'adj', 1, 8
  sub = getWord 'clnono', 's', 1, 10

  say "#{upper adj[1].word} #{upper sub[1].word}"

isLogWord = (word) ->
  myconn = dbh!
  sql = [[
    SELECT
     count(*)
    FROM
      log
    WHERE
      message ~* '\y]]..word..[[\y'
  ]]
  stmt = myconn\prepare sql
  stmt\execute!
  count = 0
  row = stmt\fetch!
  count = row[1]
  return tonumber(count) > 0

bankid2 = (source, destination) =>

  adj = ""
  sub = ""
  while true
    adj = getWord 'clnono', 'adj', 1, 20
    adj = adj[1].word
    continue unless isLogWord(adj)
  while true
    sub = getWord 'clnono', 's', 1, 20
    sub = sub[1].word
    continue unless isLogWord(sub)

  say "#{upper adj} #{upper sub}"

bankidmany = (source, destination, count) =>
  count = math.min(count, 100)

  adj = getWord 'clnono', 'adj', count, 8
  sub = getWord 'clnono', 's', count, 10

  out = {}
  for i=1, count
    table.insert(out, "#{upper adj[i].word} #{upper sub[i].word}")
  say table.concat(out, ', ')

adjsub = (source, destination, count) =>
  count = tonumber count
  if not count
    count = 1
  count = math.min(count, 100)

  adj = getWord 'clukuk', 'adj', count, 8
  sub = getWord 'clukuk', 'n', count, 10

  out = {}
  for i=1, count
    table.insert(out, "#{adj[i].word} #{sub[i].word}")
  say table.concat(out, ', ')

PRIVMSG:
  '^%pclue (.+)$': lookup
  '^%pbankid$': bankid
  '^%pbankid (%d+)$': bankidmany
  '^%padjsub$': adjsub
  '^%padjsub (%d+)$': adjsub
  '^%p?fluffle (.+)$': (source, destination, arg) =>
    choice = math.random(1, 26)
    alliteration = ('abcdefghjijklmnopqrstuvxyz')\sub(choice, choice)
    adj = getWord 'clukuk', 'adj', 1, 8, alliteration
    sub = getWord 'clukuk', 'n', 1, 10, alliteration
    n = ''
    if alliteration\match '[aeiou]'
      n = 'n'
    say "#{ivar2.util.trim arg} got fluffled by a#{n} #{adj[1].word} #{sub[1].word}"
  --'^%pbankid2$': bankid2


