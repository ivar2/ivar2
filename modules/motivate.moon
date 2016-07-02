PickOne = (l) ->
 l[math.random #l]

phrases = {
  "You're doing good work, %s"
  "%s, you are an inspiration to all of us"
  "Kudos, %s, kudos."
  "Keep up the great work, %s"
  "You're awesome, %s"
  "Keep on truckin', %s"
  "High five, %s, that's awesome"
  "%s: rock on!"
}

PRIVMSG:
  '^%pmotivate (.*)$': (s, d, n) => say PickOne(phrases), n
  '^%^5 (.*)$': => reply '⁵!!'
  '^%^5$': => say '⁵!!'


