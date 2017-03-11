{:simplehttp, :json, :bold} = require'util'

PRIVMSG:
  '^%pbtc$': =>
    say "#{bold '1'} BTC is worth #{bold '%s'} € (~15m)", json.decode((simplehttp 'https://blockchain.info/no/ticker'))['EUR']['15m']
