-- yr.no API consumer, using the new unofficial API
import urlEncode, simplehttp, json, red, lightblue, utf8 from require'util'

apiBase = 'http://www.yr.no'
-- default
default_lang = 'en'

windSpeedToName = (ws, lang) ->
  windtext = ''
  n = (lang\match '^n')
  unless ws
    return windtext
  if ws > 32
    windtext = 'orkan!'
    unless n
      windtext = 'hurricane!'
  elseif ws > 28.5
    windtext = 'sterk storm'
    unless n
      windtext = 'violent storm'
  elseif ws > 24.5
    windtext = 'full storm'
    unless n
      windtext = 'storm'
  elseif ws > 20.8
    windtext = 'liten storm'
    unless n
      windtext = 'severe gale'
  elseif ws > 17.2
    windtext = 'sterk kuling'
    unless n
      windtext = 'gale'
  elseif ws > 13.9
    windtext = 'stiv kuling'
    unless n
      windtext = 'near gale'
  elseif ws > 10.8
    windtext = 'liten kuling'
    unless n
      windtext = 'strong breeze'
  elseif ws > 8
    windtext = 'frisk bris'
    unless n
      windtext = 'fresh breeze'
  elseif ws > 5.5
    windtext = 'laber bris'
    unless n
      windtext = 'moderate breeze'
  elseif ws > 3.4
    windtext = 'lett bris'
    unless n
      windtext = 'gentle breeze'
  elseif ws > 1.5
    windtext = 'svak vind'
    unless n
      windtext = 'light breeze'
  elseif ws > 0.3
    windtext = 'flau vind'
    unless n
      windtext = 'light air'
  else
    windtext = 'vindstille'
    unless n
      windtext = 'calm'
  return windtext

arrow = (dir) ->
  -- Turn the direction of arrow to the way wind is coming from
  utf8arrow = utf8.arrow
  ndir = dir\gsub '.', (n) ->
    if     n == 'N' then n = 'S'
    elseif n == 'E' then n = 'W'
    elseif n == 'S' then n = 'N'
    elseif n == 'W' then n = 'E'
    return n
  utf8arrow(ndir)

color = (value) ->
  if tonumber(value) > 0 then
    return red
  else
    return lightblue

deg2name = (deg) ->
  val = math.floor((deg/22.5)+.5)
  arr = {"N","NNE","NE","ENE","E","ESE", "SE", "SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"}
  return arr[ (val % 16) +1 ]

getLang = (self, source, destination) ->
  lang = ivar2.persist['yr:lang:'..source.nick]
  switch lang
    when 'stad'
      return 'nn'
    when 'sted'
      return 'nb'
    when 'place'
      return 'en'
    -- else pass

  clocale = @DestinationLocale(destination)
  if (clocale\match('^nn'))
    return 'nn'
  elseif(clocale\match('^nb'))
    return 'nb'

  return default_lang

getLocation = (arg, lang) ->
  lang = lang or default_lang
  data = simplehttp apiBase..'/api/v0/locations/suggest?language='..lang..'&q='..urlEncode(arg)
  js = json.decode(data)
  if js.totalResults == 0
    return nil, 'No results'
  locations = js['_embedded']['location']
  _, location = next locations
  return location

getPlace = (self, source, destination, input) ->
  if not input or input == ''
    persist = self.persist['yr:place:'..source.nick]
    unless persist
      patt = @ChannelCommandPattern('^%pset yr <location>', "yr", destination)\sub(1)
      patt = patt\gsub('^%^%%p', '!')
      @Msg('privmsg', destination, source, 'Set your location first. Like this: '..patt)
      return
    input = persist

  return input

handleTempLookup = (source, destination, arg) =>
  place = getPlace @, source, destination, arg
  unless place
    return
  lang = getLang(@, source, destination)
  location = getLocation place, lang
  unless location
    reply 'yr.no came up "wah?"'
  whereabouts = {location.name}
  category = location.category and location.category.name
  table.insert whereabouts, category if category
  subregion = location.subregion and location.subregion.name
  table.insert whereabouts, subregion if subregion
  region = location.region and location.region.name
  table.insert whereabouts, region if region
  country = location.country.name
  table.insert whereabouts, country

  whereabouts = table.concat whereabouts, ', '

  f_link = apiBase .. location._links.forecast.href
  f_data = simplehttp f_link
  forecast = json.decode f_data

  _, now = next forecast.shortIntervals

  temp = now.temperature.value
  feelsLike = ''
  if now.feelsLike and now.feelsLike.value
    the_feels = now.feelsLike.value
    feels_word = 'feels like'
    if lang\match '^n'
      feels_word = 'følt'
    feelsLike = "(#{feels_word} #{color(the_feels)(the_feels)} °C) "

  windDirection = now.wind.direction
  windDirectionarrow = arrow deg2name windDirection
  windSpeed = now.wind.speed
  windSpeedname = windSpeedToName windSpeed, lang

  cloudCover = now.cloudCover.value
  cloudCovername = 'cloud cover'
  if lang\match '^n'
    cloudCovername = 'skydekke'

  say '%s °C, %s%s%% %s, %s %s (%s m/s) (%s)', color(temp)(temp), feelsLike, cloudCover, cloudCovername, windDirectionarrow, windSpeedname, windSpeed, whereabouts


PRIVMSG:
  '^%pbtemp%s*(.*)$': handleTempLookup
  '^%pdeg (.*)$': (s, d, a) =>
    say deg2name(tonumber(a))
