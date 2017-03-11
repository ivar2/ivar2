-- Module to follow and track DotA2 broadcasts

{:simplehttp, :json, :bold, :red, :green} = require 'util'

siValue = (val) ->
  val = tonumber(val)
  if(val >= 1e6) then
    ('%.1f')\format(val / 1e6)\gsub('%.', 'M')\gsub('M0', 'M')
  elseif(val >= 1e4) then
    ("%.1f")\format(val / 1e3)\gsub('%.', 'k')\gsub('k0', 'k')
  else
    val


dota = (source, destination, arg) =>
  url = 'http://www.trackdota.com/data/games_v2.json'
  simplehttp url, (data) ->
    js = json.decode data
    for _, m in ipairs(js.enhanced_matches)
      -- Use first game in series.
      _, g = next m.games
      -- team_tag
      --
      simplehttp "http://www.trackdota.com/data/game/#{g.id}/core.json", (core) ->
        cjs = json.decode core
        streams = cjs.streams
        -- Find English twitch and youtube stream with highest viewer count
        stream = ''
        count = 0
        youtubestream = ''
        for _, s in ipairs cjs.streams
          if s.provider == 'twitch' and s.language == 'en' and s.viewers > count
            stream = 'English stream: http://twitch.tv/'..s.channel
            count = s.viewers
          elseif s.provider == 'youtube' and s.language == 'en'
            youtubestream = 'https://gaming.youtube.com/watch?v='..s.embed_id
        say "[#{bold m.name}] #{green g.radiant_team.team_name} vs #{red g.dire_team.team_name} (#{siValue g.spectators} viewers). #{stream} #{youtubestream}"
      break

PRIVMSG:
  '^%pdota$': dota
