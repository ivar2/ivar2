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

local add = function(...)
	local t = 0
	for i=1, select('#', ...) do
		t = t + select(i, ...)
	end

	return t
end

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

local exchange = function(self, src, dest, val, from, to)
	from = from:gsub(' [tT]?[oO]?[iI]?[nN]?', '')
	local output

	if(cc[from:upper()] and cc[to:upper()] and from:upper() ~= to:upper()) then
		local success, val, err = run('return [['..val..']]')
		if(not err) then
			if(type(val) == 'string' and not tonumber(val)) then
				val = add(string.byte(val, 1, #val))
			else
				val = tonumber(val)
			end

			if(tonumber(val) and val > 0 and val ~= math.huge and val ~= (0/0)) then
				local url = ('http://finance.google.com/finance/converter?a=%s&from=%s&to=%s'):format(val, from, to)
				local content, status = utils.http(url)
				if(status == 200) then
					local data = content:match'<div id=currency_converter_result>(.-)</span>'
					data = utils.decodeHTML(data:gsub('<.->', '')):gsub('  ', ' ')
					if(data) then
						output = data
					end
				else
					output = 'Unable to contact server. Returned status code: '..tostring(status)
				end
			else
				output = 'assertion failed - invalid number data.'
			end
		else
			output = 'assertion failed - '..err
		end
	else
		output = 'Invalid currency.'
	end

	if dest == self.config.nick then
		-- Send the response in a PM
		local srcnick = self:srctonick(src)
		self:privmsg(srcnick, "%s: %s", srcnick, output)
	else
		-- Send it to the channel
		self:privmsg(dest, "%s: %s", self:srctonick(src), output)
	end
end

return {
	["^:(%S+) PRIVMSG (%S+) :!xe (.-) (.-) (%a%a%a)"] = exchange,
	["^:(%S+) PRIVMSG (%S+) :!cur (.-) (.-) (%a%a%a)"] = exchange,
}
