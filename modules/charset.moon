iconv = require'iconv'

iso2utf = iconv.new('UTF-8'.."//TRANSLIT", 'ISO-8859-1')
utf2iso = iconv.new('ISO-8859-1'.."//TRANSLIT", 'UTF-8')

toUtf = (s) ->
  iso2utf\iconv(s)

toIso = (s) ->
  utf2iso\iconv(s)

latinpattern = "^#{toIso'æøå'}%??$"


PRIVMSG:
  '^æøå%??$': =>
    reply "UTF-8. Relax, you're doing fine."
  [latinpattern]: =>
    reply 'ISO-8859-1. Pls stahp.'
  '^Ã¦Ã¸Ã¥%??$': =>
    reply 'WTF8. Is very nice.'
  '^fxe%??$': =>
    reply 'fxe is Latin1 with 8th bit stripped'
  '^{%|}%??$': =>
    reply 'du sender NS-4551-1 (aka. ISO-646-NO).. og det er jo litt ut.'
  '^��?%??$': =>
    reply 'du sender replacement chars.'
  '^aeoeaa%?$': =>
    reply 'ASCII!'
  '^���?%??$': =>
    reply 'du sender replacement chars.'
  '^+AOYA+ADl?%??$': =>
    reply 'du sender UTF-7'
  '^%piconv (.+) (.+) (.+)$': (source, dest, frm, to, arg) =>
    convert = iconv.new("#{to\upper!}//TRANSLIT", frm\upper!)
    unless convert
      return say 'Invalid encoding given'
    nstr, err = convert\iconv(arg)
    if err
      return say err

    say nstr
