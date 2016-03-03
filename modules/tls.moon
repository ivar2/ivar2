{:green, :red, :simplehttp, :json, :urlEncode} = require'util'

PRIVMSG:
  '^%ptls (.+)$': (source, destination, target) =>
    simplehttp {url:'https://ip.xt.gg/cert/?target='..urlEncode(target), headers:{accept:'application/json'}}, (data) ->
      if result = json.decode data
        with result
          res = ''
          if .success
            res = "#{green '🔒'} TLS #{green 'ok'}"
          else
            res = "#{red '🔓 '} #{red 'Bad'} TLS"
          say "#{res} for #{.host or target}. #{.err or ''}"
      else
        say 'Service error. :('
