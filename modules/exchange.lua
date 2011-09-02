local httpclient = require'handler.http.client'
local html2unicode = require'html'

local client = httpclient.new(ivar2.Loop)

local cc = {
	["AED"] = "United Arab Emirates Dirham (AED)",
	["ANG"] = "Netherlands Antillean Gulden (ANG)",
	["ARS"] = "Argentine Peso (ARS)",

	["AUD"] = "Australian Dollar (AUD)",
	["BGN"] = "Bulgarian Lev (BGN)",
	["BHD"] = "Bahraini Dinar (BHD)",
	["BND"] = "Brunei Dollar (BND)",
	["BOB"] = "Bolivian Boliviano (BOB)",
	["BRL"] = "Brazilian Real (BRL)",
	["BWP"] = "Botswana Pula (BWP)",
	["CAD"] = "Canadian Dollar (CAD)",
	["CHF"] = "Swiss Franc (CHF)",

	["CLP"] = "Chilean Peso (CLP)",
	["CNY"] = "Chinese Yuan (renminbi) (CNY)",
	["COP"] = "Colombian Peso (COP)",
	["CSD"] = "Serbian Dinar (CSD)",
	["CZK"] = "Czech Koruna (CZK)",
	["DKK"] = "Danish Krone (DKK)",
	["EEK"] = "Estonian Kroon (EEK)",
	["EGP"] = "Egyptian Pound (EGP)",
	["EUR"] = "Euro (EUR)",

	["FJD"] = "Fijian Dollar (FJD)",
	["GBP"] = "British Pound (GBP)",
	["HKD"] = "Hong Kong Dollar (HKD)",
	["HNL"] = "Honduran Lempira (HNL)",
	["HRK"] = "Croatian Kuna (HRK)",
	["HUF"] = "Hungarian Forint (HUF)",
	["IDR"] = "Indonesian Rupiah (IDR)",
	["ILS"] = "New Israeli Sheqel (ILS)",
	["INR"] = "Indian Rupee (INR)",

	["ISK"] = "Icelandic Króna (ISK)",
	["JPY"] = "Japanese Yen (JPY)",
	["KRW"] = "South Korean Won (KRW)",
	["KWD"] = "Kuwaiti Dinar (KWD)",
	["KZT"] = "Kazakhstani Tenge (KZT)",
	["LKR"] = "Sri Lankan Rupee (LKR)",
	["LTL"] = "Lithuanian Litas (LTL)",
	["MAD"] = "Moroccan Dirham (MAD)",
	["MUR"] = "Mauritian Rupee (MUR)",

	["MXN"] = "Mexican Peso (MXN)",
	["MYR"] = "Malaysian Ringgit (MYR)",
	["NOK"] = "Norwegian Krone (NOK)",
	["NPR"] = "Nepalese Rupee (NPR)",
	["NZD"] = "New Zealand Dollar (NZD)",
	["OMR"] = "Omani Rial (OMR)",
	["PEN"] = "Peruvian Nuevo Sol (PEN)",
	["PHP"] = "Philippine Peso (PHP)",
	["PKR"] = "Pakistani Rupee (PKR)",

	["PLN"] = "Polish Złoty (PLN)",
	["QAR"] = "Qatari Riyal (QAR)",
	["RON"] = "New Romanian Leu (RON)",
	["RUB"] = "Russian Ruble (RUB)",
	["SAR"] = "Saudi Riyal (SAR)",
	["SEK"] = "Swedish Krona (SEK)",
	["SGD"] = "Singapore Dollar (SGD)",
	["SIT"] = "Slovenian Tolar (SIT)",
	["SKK"] = "Slovak Koruna (SKK)",

	["THB"] = "Thai Baht (THB)",
	["TRY"] = "New Turkish Lira (TRY)",
	["TTD"] = "Trinidad and Tobago Dollar (TTD)",
	["TWD"] = "New Taiwan Dollar (TWD)",
	["UAH"] = "Ukrainian Hryvnia (UAH)",
	["USD"] = "United States Dollar (USD)",
	["VEB"] = "Venezuelan Bolívar (VEB)",
	["ZAR"] = "South African Rand (ZAR)",
}

local conv = {
	['euro'] = 'eur',
}

-- make environment
local _X = setmetatable({
	math = math,
	print = function(val) if(val and tonumber(val)) then return tonumber(val) end end
}, {__index = math})

-- run code under environment
local function run(untrusted_code)
	local untrusted_function, message = loadstring(untrusted_code)
	if not untrusted_function then return nil, message end
	setfenv(untrusted_function, _X)
	return pcall(untrusted_function)
end

local parseData = function(data)
	local data = data:match'<div id=currency_converter_result>(.-)</span>'
	return html2unicode(data:gsub('<.->', '')):gsub('  ', ' ')
end

local checkInput = function(value, from, to)
	if(not (cc[from] and cc[to])) then
		return nil, string.format('Invalid currency: %s.', (not cc[from] and from) or (not cc[to] and to))
	end

	-- Control the input.
	value = value:gsub(',', '.')
	local success, value, err = run('return ' .. value)
	if(err) then
		return nil, string.format('Parsing of input failed: %s', err)
	end

	-- Number validation, serious business!
	if(type(value) ~= 'number' or value <= 0 or value == math.huge or value ~= value) then
		return nil, string.format('Invalid number provided: %s', tonumber(value))
	end

	return true, value
end

local handleExchange = function(self, source, destination, value, from, to)
	-- Strip away to/in.
	from = from:lower():gsub(' [toin]+', '')
	from = (conv[from] or from):upper()
	to = (conv[to] or to):upper()

	local success, value = checkInput(value, from, to)
	if(not success) then
		self:Msg('privmsg', destination, source, '%s: %s', source.nick, value)
	else
		local sink = {}
		client:request{
			url = ('http://www.google.com/finance/converter?a=%s&from=%s&to=%s'):format(value, from, to),

			on_data = function(request, response, data)
				if(data) then sink[#sink + 1] = data end
			end,

			on_finished = function()
				local data = parseData(table.concat(sink))
				if(data) then
					self:Msg('privmsg', destination, source, '%s: %s', source.nick, data)
				end
			end,
		}
	end
end

return {
	PRIVMSG = {
		['!xe (.-) (.-) (%a+)$'] = handleExchange,
		['!cur (.-) (.-) (%a+)$'] = handleExchange,
	},
}
