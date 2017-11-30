-- Ported from luabot cards.lua by xt.
-- License: GPLv2
-- Copyright 2012-2014 Christopher E. Miller
-- Copyright 2016 xt
--

local commands = {}
local _C = {
	['PRIVMSG'] = commands
}
local function botExpectChannelBotCommand(pattern, handler)
	commands['^'..pattern] = handler
end

-- TODO persist this
local alData = {bank={}}

local nickFromSource = function(source)
	if type(source) == 'table' then
		return source.nick
	end
	return source
end

local function pickone(list)
	return list[math.random(#list)]
end

local function splitWords(str)
	local result = {}
	for w in str:gmatch("[^ ]+") do
		table.insert(result, w)
	end
	return result
end

local function isnan(n)
  return n ~= n
end

local function dollarsOnly(client, to, nick)
	nick = nick or to
	local witty = {
		"we don't work with pennies here",
		"I don't like having pockets full of change",
		"the math is too difficult",
		"thanks!",
		}
	client:Privmsg(to, nick .. ": Please specify dollar amounts, " .. pickone(witty));
end

local function tooMuchMoney(client, to, nick)
	nick = nick or to
	client:Privmsg(to, nick .. ": Sorry, that's too much money to be throwing around")
end

local function needMoreMoneyWitty()
	return {
		"this isn't a charity you know",
		"it's better this way",
		"glad you understand",
		"heh",
		"lol",
		"how embarrassing",
		"try playing some cheap games!",
		"I'm running a business here",
		-- "do you manage your finances using microsoft bob?",
		-- "maybe you can click a monkey for some cash",
		}
end

local giveUserCash
local giveUserCashDealer
local getUserCash
giveUserCashDealer = function(user, diff)
	return giveUserCash(user, diff, "$dealer")
end

giveUserCash = function(toUser, diff, fromUser)
	assert(type(diff) == "number")
	if isnan(diff) then
		error("nan cash detected", 0)
	end
	assert(toUser and toUser ~= "", "giveUserCash: toUser expected")
	assert(fromUser and fromUser ~= "", "giveUserCash: fromUser expected")
	toUser = toUser:lower()
	fromUser = fromUser:lower()

	alData["bank"][fromUser] = getUserCash(fromUser, true) - diff

	local result = (alData["bank"][toUser] or 100) + diff
	-- alData["bank"][toUser] = round(result, 2)
	alData["bank"][toUser] = result
	result = math.floor(result)

	return result
end

getUserCash = function(user, real)
	user = user:lower()
	--[[
	if user == "$dealer" then
		return getDealerCash(real)
	end
	--]]
	local xcash = alData["bank"][user]
	local rcash = xcash
	if not rcash then
		rcash = 100
		if user:sub(1, 1) == '$' then
			rcash = 0
		end
	end
	if real then
		return rcash
	end
	return math.floor(rcash)
end

local winfactor = 1
local bjwinfactor = 1

local bold = '\002'
local armleghelp = {}

local tryNextBjAction
local doBjAction

local function createCard(info, suit)
	if suit:sub(1, 1):lower() == 'c' then
		suit = "Club"
	elseif suit:sub(1, 1):lower() == 'd' then
		suit = "Diamond"
	elseif suit:sub(1, 1):lower() == 'h' then
		suit = "Heart"
	elseif suit:sub(1, 1):lower() == 's' then
		suit = "Spade"
	else
		return
	end
	local i = tonumber(info, 10)
	if i then
		return { value = info, suit = suit, number = i }
	else
		local ch = info:sub(1, 1):lower()
		if ch == "k" then
			return { value = "King", suit = suit, face = true }
		elseif ch == "q" then
			return { value = "Queen", suit = suit, face = true }
		elseif ch == "j" then
			return { value = "Jack", suit = suit, face = true }
		elseif ch == "a" then
			return { value = "Ace", suit = suit, ace = true }
		elseif ch == "*" then
			return { value = "Joker", suit = suit, joker = true }
		end
	end
end

local function createJoker(color)
	local ch = color:sub(1, 1):lower()
	if ch == 'r' then
		return createCard('*', "h")
	elseif ch == 'b' then
		return createCard('*', "s")
	end
end

local function appendCardsAllOneSuit(result, suit)
	-- Forwards:
	table.insert(result, { value = "Ace", suit = suit, ace = true, face = false })
	for i = 2, 10 do
		table.insert(result, { value = tostring(i), suit = suit, number = i, face=false })
	end
	table.insert(result, { value = "Jack", suit = suit, face = true })
	table.insert(result, { value = "Queen", suit = suit, face = true })
	table.insert(result, { value = "King", suit = suit, face = true })
end

-- Don't forget to shuffleCards!
local function getCards(numberOfDecks, wantJokers)
	numberOfDecks = numberOfDecks or 1
	local result = {}
	for i = 1, numberOfDecks do
		appendCardsAllOneSuit(result, "Club")
		appendCardsAllOneSuit(result, "Diamond")
		appendCardsAllOneSuit(result, "Heart")
		appendCardsAllOneSuit(result, "Spade")
		if wantJokers then
			table.insert(result, createJoker('red'))
			table.insert(result, createJoker('black'))
		end
	end
	return result
end

-- randFunc is optional, defaults to lua's math.random
-- randFunc(m) which returns a value from 1 to m inclusive.
local function shuffleCards(cards, randFunc)
	if not randFunc then
		math.randomseed(math.random() + os.time())
		randFunc = math.random
	end
	local ncards = #cards
	for i = 1, ncards do
		local rn = randFunc(ncards)
		local tmp = cards[rn]
		cards[rn] = cards[i]
		cards[i] = tmp
	end
	return cards
end

-- Removes and returns the next card from the end.
-- Returns nil if no more cards.
local function popCard(cards)
	if #cards > 0 then
		local result = cards[#cards]
		table.remove(cards)
		return result
	end
	return nil
end

local function cardString(card)
	local suiticode = {
		Club = "\226\153\163",
		Diamond = "\226\153\166",
		Heart ="\226\153\165",
		Spade = "\226\153\160",
	}

	local printvalue = card.value
	if card.joker then
		if card.suit:sub(1, 1) == 'H' then
			printvalue = "RedJoker"
		else
			printvalue = "BlackJoker"
		end
	elseif card.value:find("^%a") then
		printvalue = card.value:sub(1, 1)
	end
	local color
	if card.suit:sub(1, 1) == 'C' then
		color = 1
	elseif card.suit:sub(1, 1) == 'D' then
		color = 4
	elseif card.suit:sub(1, 1) == 'H' then
		color = 4
	elseif card.suit:sub(1, 1) == 'S' then
		color = 1
	end
	return ("%s%s"):format(
		ivar2.util.color(suiticode[card.suit], color, 0),
		ivar2.util.color(ivar2.util.bold(printvalue), 1, 0)
		)
end

local function cardsString(cards, boldLastCard, snazzy)
	local lastmarker = "*"
	if not boldLastCard then
		boldLastCard = 0
	elseif boldLastCard and type(boldLastCard) ~= "number" then
		boldLastCard = 1
	end
	local result = ""
	for i = 1, #cards do
		if i > 1 then
			result = result .. " "
		end
		if i == (#cards - boldLastCard + 1) then
			result = result .. lastmarker .. cardString(cards[i], snazzy) .. lastmarker
		else
			result = result .. cardString(cards[i], snazzy)
		end
	end
	return result
end

local function getGame(raw, client, chan)
	local g = raw[client.network .. "." .. chan:lower()]
	return g
end

local function newGame(raw, client, chan)
	local gkey = client.network .. "." .. chan:lower()
	assert(not raw[gkey])
	local g = { client = client, chan = chan:lower() }
	g.players = {}
	setmetatable(g.players, {
		__index = function(table, key)
			if type(key) == "string" then
				local lkey = key:lower()
				for i = 1, #table do
					if table[i].nick:lower() == lkey then
						return table[i]
					end
				end
			end
			return rawget(table, key)
		end
		})
	g.startTime = os.time()
	raw[gkey] = g
	return g
end

local function removeGame(raw, g)
	raw[g.client.network .. "." .. g.chan:lower()] = nil
end

local function gameAddPlayer(g, nick)
	local result = { nick = nick }
	table.insert(g.players, result)
	return result
end

-- Dealer chosen last if game.dealer exists.
local function getNextPlayer(game)
	for i = 1, #game.players do
		local player = game.players[i]
		if not player.done then
			if not player.t then
				player.t = os.time()
			end
			return player
		end
	end
	if game.dealer and not game.dealer.done then
		return game.dealer
	end
end

local rawBj = {}
local function getBj(client, chan)
	return getGame(rawBj, client, chan)
end
local function newBj(client, chan)
	return newGame(rawBj, client, chan)
end
local function removeBj(bj)
	return removeGame(rawBj, bj)
end
local function bjAddPlayer(bj, nick)
	return gameAddPlayer(bj, nick)
end
local function getNextBjPlayer(bj)
	return getNextPlayer(bj)
end


local function getBestBjCardTotal(cards)
	local total = 0
	local nAces = 0
	for i = 1, #cards do
		local card = cards[i]
		if card.ace then
			nAces = nAces + 1
			total = total + 11
		elseif card.face then
			total = total + 10
		else
			total = total + card.number
		end
	end
	while nAces > 0 and total > 21 do
		nAces = nAces - 1
		total = total - 10
	end
	return total
end


local function maxBjBet(user)
	local cash = getUserCash(user)
	local maxbet = cash
	if maxbet < 150 then
		maxbet = 50
	end
	if cash >= 150 then
		maxbet = 50 + math.floor((cash - 150) / 2)
	-- elseif cash < -500 then
	-- 	maxbet = math.floor(-cash / 10)
	end
	if maxbet > 1000 then
		maxbet = 1000
	end
	return maxbet
end


local specialBadBjPlayer = "chimp"
local specialGoodBjPlayer = "freck"

local function addBadBjPlayer(bj)
	local splayer = bjAddPlayer(bj, specialBadBjPlayer)
	splayer.special = "bad"
	splayer.bet = 1
	return splayer
end

local function addGoodBjPlayer(bj)
	local splayer = bjAddPlayer(bj, specialGoodBjPlayer)
	splayer.special = "good"
	--[[
	splayer.bet = math.floor(maxBjBet(splayer.nick) / (math.random(4) + 1))
	if splayer.bet < 25 then splayer.bet = 25 end
	--]]
	splayer.bet = bj.players[1].bet or 25
	return splayer
end


local function bjGameStarting(state)
	local bj = state.bj
	local chan = state.chan
	local client = bj.client

	if 0 == #bj.players then
		addBadBjPlayer(bj)
		addGoodBjPlayer(bj)
	else
		local rn = math.random(104)
		if rn <= 50 then
			addBadBjPlayer(bj)
		elseif rn <= 100 then
			addGoodBjPlayer(bj)
		elseif rn <= 102 then
			addBadBjPlayer(bj)
			addGoodBjPlayer(bj)
		end
	end

	if #bj.players >= 8 then
		bj.cards = getCards(3) -- 3 decks.
	elseif #bj.players >= 4 then
		bj.cards = getCards(2) -- 2 decks.
	else
		bj.cards = getCards(1) -- 1 deck.
	end
	shuffleCards(bj.cards)
	shuffleCards(bj.cards, function(m) return math.random(m) end)

	bj.state = "deal"

	bj.dealer = {}
	bj.dealer.nick = "$Dealer"
	bj.dealer.special = "dealer"
	bj.dealer.cards = {}
	table.insert(bj.dealer.cards, popCard(bj.cards)) -- hidden
	table.insert(bj.dealer.cards, popCard(bj.cards)) -- visible
	assert(#bj.dealer.cards == 2)

	for i = 1, #bj.players do
		local player = bj.players[i]
		player.cards = {}
		table.insert(player.cards, popCard(bj.cards))
		table.insert(player.cards, popCard(bj.cards))
		assert(#player.cards == 2)
	end

	local msg = "Blackjack game started! Cards on table:"
	for i = 1, #bj.players do
		local player = bj.players[i]
		msg = msg .. " (" .. bold .. player.nick .. bold .. "=" ..getBestBjCardTotal(player.cards)
			.. ": " .. cardString(player.cards[1]) .. ", " .. cardString(player.cards[2]) .. ")"
	end
	msg = msg .. " (" .. bold .. "Dealer" .. bold .. ": ?, " .. cardString(bj.dealer.cards[2]) .. ")"
	msg = msg .. " - players, please type: " .. bold .. "hit, stand, surrender or double"
	client:Privmsg(chan, msg)

	tryNextBjAction(bj)

	ivar2:Timer('bjtoolong.' .. chan:lower(), 23, function(timer)
		local now = os.time()
		for k, bjg in pairs(rawBj) do
			if bjg.state == "deal" then
				local player = getNextBjPlayer(bjg)
				if player.t and os.difftime(now, player.t) >= 20 then
					player.done = true
					player.t = nil
					bjg.client:Privmsg(bjg.chan, player.nick .. " waited too long, standing with " .. cardsString(player.cards));
					tryNextBjAction(bjg)
				end
			end
		end
	end)


end

local goodBjPlayerTable = {   -- Dealer's card up
  '',       2,   3,   4,   5,   6,  7,  8,   9,  10,  'A',
  2,       'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H',
  3,       'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H',
  4,       'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H',
  5,       'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H',
  6,       'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H',
  7,       'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H',
  8,       'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H',
  9,       'H', 'D', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H',
  10,      'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H', 'H',
  11,      'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H',
  12,      'H', 'H', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H',
  13,      'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H',
  14,      'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H',
  15,      'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H',
  16,      'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H',
  'A-2',   'H', 'H', 'H', 'D', 'D', 'H', 'H', 'H', 'H', 'H',
  'A-3',   'H', 'H', 'H', 'D', 'D', 'H', 'H', 'H', 'H', 'H',
  'A-4',   'H', 'H', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H',
  'A-5',   'H', 'H', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H',
  'A-6',   'H', 'D', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H',
  'A-7',   'S', 'D', 'D', 'D', 'D', 'S', 'S', 'H', 'H', 'H',
  'A-8',   'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S',
  'A-8',   'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S',
  '5-5',   'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H', 'H',
}
local goodBjPlayerTableNumCols = 11

local function lookGoodBjPlayerTable(left, dealer)
	local row = 1 -- 0-based
	while true do
		local p = goodBjPlayerTable[row * goodBjPlayerTableNumCols + 1]
		if not p then
			break
		end
		if p == left then
			for i = 2, goodBjPlayerTableNumCols do
				if dealer == goodBjPlayerTable[i] then
					-- Don't need to add 1 to the index since 'i' has 1 added already.
					-- print("index " .. (row * goodBjPlayerTableNumCols + i), goodBjPlayerTable[row * goodBjPlayerTableNumCols + i])
					return goodBjPlayerTable[row * goodBjPlayerTableNumCols + i]
				end
			end
			break
		end
		row = row + 1
	end
end

assert(lookGoodBjPlayerTable('A-7', 2) == 'S')
assert(lookGoodBjPlayerTable('A-7', 3) == 'D')
assert(lookGoodBjPlayerTable('A-7', 4) == 'D')
assert(lookGoodBjPlayerTable('A-7', 5) == 'D')
assert(lookGoodBjPlayerTable('A-7', 6) == 'D')
assert(lookGoodBjPlayerTable('A-7', 7) == 'S')
assert(lookGoodBjPlayerTable('A-7', 8) == 'S')
assert(lookGoodBjPlayerTable('A-7', 9) == 'H')
assert(lookGoodBjPlayerTable('A-7', 10) == 'H')

local function bjLetterCmd(letter)
	if letter == 'H' then return "$hit" end
	if letter == 'S' then return "$stand" end
	if letter == 'D' then return "$double" end
end

local function goodBjPlayerMove(cards, dealerCard)
	local dealerCardX = dealerCard.number
	if dealerCard.face then dealerCardX = 10 end
	if dealerCard.ace then dealerCardX = 'A' end
	if #cards == 2 then
		if cards[1].ace and cards[2].number then
			local x = bjLetterCmd(lookGoodBjPlayerTable('A-' .. cards[2].value, dealerCardX))
			if x then return x end
		elseif cards[2].ace and cards[1].number then
			local x = bjLetterCmd(lookGoodBjPlayerTable('A-' .. cards[1].value, dealerCardX))
			if x then return x end
		elseif cards[1].number == 5 and cards[2].number == 5 then
			local x = bjLetterCmd(lookGoodBjPlayerTable('5-5', dealerCardX))
			if x then return x end
		end
	end
	local tot = getBestBjCardTotal(cards)
	if tot > 16 then return "$stand" end
	local x = bjLetterCmd(lookGoodBjPlayerTable(tot, dealerCardX))
	if x then
		if x == "$double" and #cards ~= 2 then return "$hit" end
		return x
	end
	return "$stand"
end

assert(goodBjPlayerMove({ createCard('3', 'c'), createCard('6', 'h') }, createCard('2', 'd')) == "$hit")
assert(goodBjPlayerMove({ createCard('3', 'c'), createCard('6', 'h') }, createCard('3', 'd')) == "$double")
assert(goodBjPlayerMove({ createCard('7', 'c'), createCard('A', 'h') }, createCard('9', 'd')) == "$hit")
assert(goodBjPlayerMove({ createCard('7', 'c'), createCard('A', 'h') }, createCard('8', 'd')) == "$stand")
assert(goodBjPlayerMove({ createCard('K', 'c'), createCard('9', 'h') }, createCard('8', 'd')) == "$stand")
assert(goodBjPlayerMove({ createCard('K', 'c'), createCard('9', 'h') }, createCard('3', 'd')) == "$stand")


local function _bjGameOver(bj, short)
	local msg = "Blackjack game is over! "
	if short then msg = "GAME OVER: " end
	local dealerTot = getBestBjCardTotal(bj.dealer.cards)
	local anyprint = false
	for i = 1, #bj.players do
		local player = bj.players[i]
		if player.bet ~= 0 then
			local win = 1
			local tot = getBestBjCardTotal(player.cards)
			if dealerTot <= 21 then
				if tot > 21 or tot < dealerTot then
					win = -1
				elseif tot == dealerTot then
					win = 0
				end
			else
				-- Dealer busts, so only busters lose.
				if tot > 21 then
					win = -1
				end
			end
			if anyprint then
				msg = msg .. ", "
			end
			if win == 1 then
				local amt = player.bet
				if #player.cards == 2 and tot == 21 then
					amt = math.floor(amt * 1.5)
				end
				amt = amt * winfactor * bjwinfactor
				msg = msg .. bold .. player.nick .. bold .. " wins $" .. amt .. " ($" .. giveUserCashDealer(player.nick, amt) .. ")"
			elseif win == -1 then
				msg = msg .. bold .. player.nick .. bold .. " loses $" .. player.bet .. " ($" .. giveUserCashDealer(player.nick, -player.bet) .. ")"
			elseif win == 0 then
				msg = msg .. bold .. player.nick .. bold .. " pushes ($" .. getUserCash(player.nick) .. ")"
			end
			anyprint = true
		end
	end
	removeBj(bj)
	-- print("Blackjack", msg)
	return msg
end

doBjAction = function(bj, sender, chan, cmd, args)
	local client = bj.client
	local nick = nickFromSource(sender)
	if not args then args = '' end
	cmd = cmd:lower() -- $hit, $stand, $split, $surrender or $double
	local extra = ""
	if #args> 0 then
		extra = "   " .. args
	end
	local name = nick
	if nick:sub(1, 1) == '$' then
		name = nick:sub(2)
	end
	local player = getNextBjPlayer(bj)
	if player.nick:lower() == nick:lower() then
		local msg
		if cmd == "$hit" or cmd == "hit" then
			local card = popCard(bj.cards)
			table.insert(player.cards, card)
			local tot = getBestBjCardTotal(player.cards)
			if tot > 21 then
				msg = (name .. " hits and BUSTS: " .. cardsString(player.cards, true) .. extra)
				player.done = true
			elseif tot == 21 then
				msg = (name .. " hits and stands with 21: " .. cardsString(player.cards, true) .. extra)
				player.done = true
			else
				-- Don't show every hit for automated.
				if not player.special then
					msg = (name .. " hits, total " .. tot .. ": " .. cardsString(player.cards, true)
						.. " - " .. name .. ": please hit again or stand" .. extra)
				end
			end
		elseif cmd == "$stand" or cmd == "stand" then
			local tot = getBestBjCardTotal(player.cards)
			if player.special or #player.cards == 2 then
				msg = (name .. " stands with " .. tot .. ": " .. cardsString(player.cards) .. extra)
			end
			player.done = true
		elseif cmd == "$double" or cmd == "double" then
			if #player.cards == 2 then
				player.bet = player.bet * 2
				local card = popCard(bj.cards)
				table.insert(player.cards, card)
				local tot = getBestBjCardTotal(player.cards)
				if tot > 21 then
					msg = (name .. " doubles and BUSTS: " .. cardsString(player.cards, true) .. extra)
				else
					msg = (name .. " doubles, total " .. tot .. ": " .. cardsString(player.cards, true) .. extra)
				end
				player.done = true
			else
				msg = (name .. ": You cannot double at this time; please hit or stand")
			end
		elseif cmd == "$surrender" or cmd == "surrender" then
			if #player.cards == 2 then
				local keep = math.floor(player.bet / 2)
				msg = name .. " surrenders the game, keeping $" .. keep
				giveUserCashDealer(nick, -player.bet + keep)
				player.bet = 0
				player.done = true
			else
				msg = (name .. ": You cannot surrender at this time; please hit or stand")
			end
		elseif cmd == "$cheat" or cmd == "cheat" then
			local r = math.random(100)
			if player.nocheat or r < 50 then
				local witty = {
					"everyone's looking",
					"maybe you're just not good at it",
					"practice makes perfect",
					"it's just impossible",
					"what would everyone think if you got caught?",
					"idi*t",
					"u wot m8?",
				}
				client:Privmsg(chan, name .. ": It's too difficult to cheat right now, " .. pickone(witty))
			else
				local caught
				if r < 50 + 25 then
					caught = true
				end
				if not caught or math.random(100) < 50 then
					local witty = {
						"That was a close one!",
						"I hope it was worth it!",
						"I don't think anyone saw",
						"ok -.-",
					}
					client:Privmsg(chan, name .. ": The next card is " .. cardString(bj.cards[#bj.cards])
						.. " " .. pickone(witty))
				end
				if caught then
					local penalty = (player.bet * 2) + 300
					giveUserCashDealer(nick, -penalty)
					player.nocheat = true
					player.bet = 0
					player.done = true
					local witty = {
						"What do you have to say for yourself?",
						"I hope you've learned your lesson!",
						"This goes on your permanent record.",
						"Go to jail.",
					}
					client:Privmsg(chan, name .. " caught cheating! Pay a penalty of $" .. penalty .. " " .. pickone(witty))
				end
			end
			player.nocheat = true
		end
		if msg then
			if player.done and player.special == "dealer" then
				msg = msg .. " - " .. _bjGameOver(bj, true)
			end
			client:Privmsg(chan, msg)
			--clownpromo(bj.client, bj.chan)
		end
		if not player.done then
			player.t = os.time() -- Update time.
		end
		tryNextBjAction(bj)
	else
		-- Not the next player, so save their choice...
		if player.special then return end
		player = bj.players[nick]
		if player then
			player.move = cmd
		end
	end
end

tryNextBjAction = function(bj)
	local player = getNextBjPlayer(bj)
	if player then
		-- io.stderr:write(" & player\n")
		local tot = getBestBjCardTotal(player.cards)
		if tot == 21 and #player.cards == 2 then
			player.move = nil
			doBjAction(bj, player.nick, bj.chan, "$stand", bold .. "Blackjack!")
		elseif player.move then
			-- io.stderr:write(" & player.move\n")
			local cmd = player.move
			player.move = nil
			doBjAction(bj, player.nick, bj.chan, cmd, "")
		elseif player.special then
			-- io.stderr:write(" & player.special = " .. player.special .. "\n")
			if player.special == "good" then
				local witty = {
					"watch and learn",
					"this is so easy",
					"you could learn a thing or two",
					"see what I did there?",
					"ha!",
					"",
					"",
					"",
					"",
					}
				local wit = ""
				if player.nick == specialGoodBjPlayer then
					wit = pickone(witty)
				end
				doBjAction(bj, player.nick, bj.chan, goodBjPlayerMove(player.cards, bj.dealer.cards[2]), wit)
			elseif player.special == "bad" then
				local witty = {
					"banana",
					":(|)",
					"ooo",
					"*scratch*",
					"",
					"",
					}
				if #player.cards == 2 then
					local rn = math.random(3)
					if rn == 1 then
						doBjAction(bj, player.nick, bj.chan, "$stand", pickone(witty))
					elseif rn == 2 then
						doBjAction(bj, player.nick, bj.chan, "$double", pickone(witty))
					else
						doBjAction(bj, player.nick, bj.chan, "$hit", pickone(witty))
					end
				else
					doBjAction(bj, player.nick, bj.chan, "$stand", pickone(witty))
				end
			elseif player.special == "dealer" then
				-- local tot = getBestBjCardTotal(player.cards)
				if tot <= 16 then
					doBjAction(bj, player.nick, bj.chan, "$hit", "")
				else
					doBjAction(bj, player.nick, bj.chan, "$stand", "")
				end
			end
		end
		-- GAME OVER
	end
end


local function bjAction(client, sender, chan, cmd, args)
	local bj = getBj(client, chan)
	if bj and bj.state == "deal" then
		doBjAction(bj, sender, chan, cmd, args)
	end
end

local function bjActionFromServer(client, sender, chan, arg)
	--[[
	if not alValidUser(sender) then
	client:Privmsg(chan, nick .. ": access denied")
	return
	end
	--]]
	local cmd, args = arg:match('^(.-) (.*)$')
	if not cmd then cmd = arg end
	if not args then args = '' end
	return bjAction(client, sender, chan, cmd, args)
end

armleghelp.hit = "Request a new card in a game of blackjack"
botExpectChannelBotCommand("$hit", bjActionFromServer)
botExpectChannelBotCommand("hit", bjActionFromServer)

armleghelp.stand = "Keep the hand you have in a game of blackjack"
botExpectChannelBotCommand("$stand", bjActionFromServer)
botExpectChannelBotCommand("stand", bjActionFromServer)

--botExpectChannelBotCommand("$split", bjActionFromServer)

armleghelp.surrender = "Surrender your hand in a game of blackjack"
botExpectChannelBotCommand("$surrender", bjActionFromServer)
botExpectChannelBotCommand("surrender", bjActionFromServer)

armleghelp.double = "Double your bet and take one last card in a game of blackjack"
botExpectChannelBotCommand("$double", bjActionFromServer)
botExpectChannelBotCommand("double", bjActionFromServer)

armleghelp.cheat = "Attempt to cheat at blackjack, but you might get caught..."
botExpectChannelBotCommand("$cheat", bjActionFromServer)
botExpectChannelBotCommand("cheat", bjActionFromServer)


armleghelp.blackjack = "Start or join a game of blackjack"
botExpectChannelBotCommand("$blackjack", function(client, sender, chan, arg)
	local nick = nickFromSource(sender)
	client:Privmsg(chan, nick .. ": To play a game of blackjack, place your bet using $bj <amount>")
end)


armleghelp.bj = armleghelp.blackjack
botExpectChannelBotCommand("$bj ?(.*)$", function(client, source, chan, args)
	local nick = nickFromSource(source)

	if nick == specialBadBjPlayer or nick == specialGoodBjPlayer then
		return
	end

	local input = splitWords(args)
	local bj
	local amount = (input[1] or ""):match("^[$]?(%w+[.]?%d*)")
	if amount == "max" then
		amount = tostring(maxBjBet(nick))
	end
	if amount and amount:find(".", 1, true) then
		dollarsOnly(client, chan, nick)
		return
	end
	amount = tonumber(amount, 10)
	if amount and (amount <= 0 or isnan(amount)) then
		client:Privmsg(chan, nick .. ": Nice try")
		return
	end
	if amount and amount > 25 then
		if amount > 1000 then
			tooMuchMoney(client, chan, nick)
			return
		else
			local maxbet = maxBjBet(nick)
			if amount > maxbet then
				--[[
				client:Privmsg(chan, nick .. ": Sorry, you do not have enough money for this bet."
					.. " The maximum you can bet is $" .. maxbet
					.. " at this time, " .. pickone(needMoreMoneyWitty())
					-- .. " (min $25 + 25% reserve of your $" .. getUserCash(nick) .. ")"
					.. " ($25 + 25% reserve)"
					, "armleg")
				return
				--]]
				client:Privmsg(chan, nick .. ": The maximum you can bet is $" .. maxbet
					.. " at this time, " .. pickone(needMoreMoneyWitty())
					-- .. " (min $25 + 25% reserve of your $" .. getUserCash(nick) .. ")"
					-- .. " ($25 + 25% reserve)"
				)
				amount = maxbet
			end
		end
	end

	-- See if a game should start, join, or too late...
	bj = getBj(client, chan)
	if bj then
		if bj.players[nick] then
			client:Privmsg(nick, nick .. ": You are in the game; your bet is $" .. bj.players[nick].bet)
			return
		else
			if bj.state ~= "start" then
				client:Privmsg(nick, nick .. ": Sorry, a game is already in progress; please wait for it to finish.")
				return
			end
		end
	end

	if not amount then
		client:Privmsg(chan, nick .. ": To play a game of blackjack, place your bet using $bj <amount>")
		return
	end

	local player
	local wait = 20
	if bj then
		--[[
		client:sendNotice(nick, nick .. ": You are also entered in the next game of blackjack!"
			-- .. " You have $" .. getUserCash(nick)
			.. " - The game will start in a few seconds so have your friends join in!")
		--]]
		player = bjAddPlayer(bj, nick)
		client:Privmsg(chan, nick .. " is now in the next game of blackjack!")
	else
		bj = newBj(client, chan)
		bj.state = "start"
		--[[
		client:sendNotice(nick, nick .. ": You are entered in the next game of blackjack!"
			-- .. " You have $" .. getUserCash(nick)
			.. " - The game will start in 20 seconds so have your friends join in!")
		--]]
		client:Privmsg(chan, "A game of blackjack will start in "..wait.." seconds!"
			.. " Type $bj <bet> if you want to get in on the action with " .. nick .. "!"
			.. " Everyone starts out with a credit line of $100")
		player = bjAddPlayer(bj, nick)
		client:Timer('bjGameWait.' .. chan:lower(), wait, function()
			bjGameStarting{ what = "bj", bj = bj, chan = chan:lower() }
		end)
	end
	player.bet = amount
	if input[2] == "auto" then
		player.special = "good"
	end
end)

local flip
function flip(client, sender, chan, cmd, args)
	local nick = nickFromSource(sender)
	-- local choice = args
	local choice, amount = args:match("([^ ]+) ?[$]?([-]?%d*)")
	if not choice or (choice ~= "heads" and choice ~= "tails") then
		local witty = {
			"It's so fun!",
			"Sounds great, doesn't it?",
			"I can't wait!",
			"I'd try heads...",
			"Tails is sure to win!",
			"*yawn*",
			":D",
			}
		client:Privmsg(chan, nick .. ": Please use \"$flip heads\" or \"$flip tails\" to bet $5 on a coin flip! " .. pickone(witty))
	else
		-- Note: allowing negatives! it's betting on the other side.
		amount = tonumber(amount, 10)
		if not amount or amount > 20 then
			amount = 5
		end
		if amount < -20 then
			amount = -5
		end
		local rn = math.random(102)
		local outcome = nil
		local prep = "landed on"
		if rn <= 50 then
			outcome = "heads"
		elseif rn <= 100 then
			outcome = "tails"
		elseif rn == 101 then
			prep = "landed on its"
			outcome = "edge"
		elseif rn == 102 then
			prep = "fell down a"
			outcome = "drain"
		end
		if outcome == choice then
			client:Privmsg(chan, nick .. ": The coin landed on " .. outcome
				.. ", you win! You now have $" .. giveUserCashDealer(nick, amount * winfactor))
		else
			client:Privmsg(chan, nick .. ": Sorry, the coin " .. prep .. " " .. outcome
				.. ". You now have $" .. giveUserCashDealer(nick, -amount))
		end
	end
	--clownpromo(client, chan)
end

local rps
function rps(client, sender, chan, cmd, args)
	local nick = nickFromSource(sender)
	local choice = cmd:sub(2, 2):upper() .. cmd:sub(3):lower()
	local amount = args:match("[$]?([-]?%d*)")
	-- Note: allowing negatives! it's betting on the other side.
	amount = tonumber(amount, 10)
	if not amount or amount > 20 then
		amount = 5
	end
	if amount < -20 then
		amount = -5
	end
	local rn = math.random(150)
	local outcome
	if rn <= 50 then
		outcome = "Rock"
	elseif rn <= 100 then
		outcome = "Paper"
	else
		outcome = "Scissors"
	end
	if outcome == choice then
		client:Privmsg(chan, nick .. ": " .. outcome .. "! Tied.")
	else
		local win = false
		local beats = "beats"
		if choice == "Rock" then
			if outcome == "Scissors" then
				win = true
				beats = "smashes"
			else -- paper -> rock
				beats = "covers"
			end
		elseif choice == "Paper" then
			if outcome == "Rock" then
				win = true
				beats = "covers"
			else -- scissors -> paper
				beats = "cuts"
			end
		elseif choice == "Scissors" then
			if outcome == "Paper" then
				win = true
				beats = "cuts"
			else -- rock -> scissors
				beats = "smashes"
			end
		end
		if win then
			client:Privmsg(chan, nick .. ": Your " .. choice .. " " .. beats .. " my " .. outcome .. "! You win! You now have $" .. giveUserCashDealer(nick, amount * winfactor))
		else
			client:Privmsg(chan, nick .. ": My " .. outcome .. " " .. beats .. " your " .. choice .. "! You lose! You now have $" .. giveUserCashDealer(nick, -amount))
		end
	end
	--clownpromo(client, chan)
end

armleghelp.rock = "Play a game of rock, paper, scissors - you will be rock"
botExpectChannelBotCommand("%prock(.*)$", function(client, sender, target, args)
	rps(client, sender, target, "$rock", args)
end)
botExpectChannelBotCommand("%ppaper(.*)$", function(client, sender, target, args)
	rps(client, sender, target, "$paper", args)
end)
botExpectChannelBotCommand("%pscissors(.*)$", function(client, sender, target, args)
	rps(client, sender, target, "$scissors", args)
end)

armleghelp.flip = "Flip a coin - play a game of heads or tails, choose heads or tails"
botExpectChannelBotCommand("%pflip(.*)$", function(client, sender, target, args)
	flip(client, sender, target, "$flip", "heads " .. args)
end)

armleghelp.heads = "Play a game of heads or tails, you will be heads"
botExpectChannelBotCommand("%pheads(.*)$", function(client, sender, target, args)
	flip(client, sender, target, "$flip", "heads " .. args)
end)
armleghelp.tails = "Play a game of heads or tails, you will be tails"
botExpectChannelBotCommand("%ptails(.*)$", function(client, sender, target, args)
	flip(client, sender, target, "$flip", "tails " .. args)
end)

return _C
