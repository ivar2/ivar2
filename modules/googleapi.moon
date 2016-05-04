key = ivar2.config.youtubeAPIKey
cxid = ivar2.config.googleCSEKey
-- general google api key + google custom searcn engine api key
-- https://console.developers.google.com/apis/

gsearch = (source, destination, term, stype) =>
  nr = 1
  m_nr, m_term = term\match '^([0-9]+) (.*)'
  if m_nr and m_term
    nr = m_nr
    term = m_term
  if not stype
    stype = ''
  else
    stype = '&searchType='..stype
  data, err = ivar2.util.simplehttp 'https://www.googleapis.com/customsearch/v1?key='..key..'&cx='..cxid..stype..'&q='..ivar2.util.urlEncode(term), (data) ->

    if query == 'google'
      return reply "wow. That's really clever."

    unless data
      return reply "no response"

    if data\sub(1, 1) ~= '{' then
      return false, 'invalid reply?'

    res = ivar2.util.json.decode(data)
    if res.error then
      return reply "Error #{res.error.code}, #{res.error.message}"

    unless res.items
      return reply 'no results'

    out = {}
    for i, item in ipairs res.items
      out[#out+1] = '['..ivar2.util.bold(tostring(i))..'] '.. item.title .. ' ' .. item.link
      if i == nr
        break
    say table.concat(out, ', ')

PRIVMSG:
  '^%pimage (.+)': (s,d,a) =>
    gsearch(@, s, d, a, 'image')
  '^%pg (.+)': gsearch

