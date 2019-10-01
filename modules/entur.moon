util = require'util'
simplehttp = util.simplehttp
json = util.json
urlEncode = util.urlEncode

client_name = 'ivar2 - entur_irc'
access_token = 'jwt bearer token'

--getToken = (name) ->
--	data = simplehttp{
--		method: 'POST',
--		url: 'https://partner.entur.org/oauth/token',
--		headers: 'content-type: application/json',
--		data: '{
--			"client_id": "ivar2",
--			"client_secret": "raviravi",
--			"audience":"https://api.entur.io",
--			"grant_type":"client_credentials"
--		}'
--	}
--
--	info = json.decode data
--	acess_token = info.access_token

parseDate = (datestr) ->
	year, month, day, hour, min, sec = datestr\match "([^-]+)%-([^-]+)%-([^T]+)T([^:]+):([^:]+):(%d%d)"
	return os.time{
		year: year,
		month: month,
		day: day,
		hour: hour,
		min: min,
		sec: sec,
	}

getStop = (name) ->
  data = simplehttp{
    url:"https://api.entur.io/geocoder/v1/autocomplete?text=#{urlEncode name}&lang=nn",-- nynorsk!
    headers: {
        ['Et-Client-Name']: client_name
    }
  }
  info = json.decode data
  if info
    _, feature = next info.features
    return feature


getRoutes = (s, d, frm, to) =>

  frm = getStop(frm)
  to = getStop(to)

  frm_id = frm.properties.id
  to_id = to.properties.id

  graphql = '{
    trip(
      from: {
        place: \\"'..frm_id..'\\",
      },
      to: {
        place: \\"'..to_id..'\\",
      },
      numTripPatterns: 3,
    ) {
   dateTime
   fromPlace {
      name

    }
    toPlace {
      name

    }
    tripPatterns {
      startTime
      endTime
      duration
      waitingTime
      distance
      walkTime
      walkDistance
      weight
    }
    }
  }
  '
  graphql = graphql\gsub '\n', ''
  post_data = '{"query":"'..graphql..'","variables":null}'
  data, uri, response = simplehttp {url:'https://api.entur.io/journey-planner/v2/graphql', method:'POST', data:post_data , headers:{['Et-Client-Name']: client_name, ['Content-Type']:'application/json'}}
  if response.status_code != 200
    say data
  else
    out = {}
    data = json.decode(data).data
    for i, trip in ipairs data.trip.tripPatterns
      time = parseDate trip.startTime
      datetime = os.date '*t', time
      relative = (time - os.time!) / 60

      a_time = parseDate trip.endTime
      a_datetime = os.date '*t', a_time
      out[#out+1] = "#{datetime.hour}:#{string.format('%02d', datetime.min)} (#{string.format('%d', relative)}m) -> #{a_datetime.hour}:#{string.format('%02d', a_datetime.min)}"

    say table.concat(out, ', ')



PRIVMSG:
  '^%pstop (.*)$': (s, d, a) =>
    say json.encode(getStop(a))
  '^%pentur (.+),(.+)$': getRoutes
