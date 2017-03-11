-- This tool will put entire unicode xml into a sqlite3 database
--
-- First download latest ucd release:
-- http://www.unicode.org/Public/9.0.0/ucdxml/ucd.all.flat.zip
-- Then run this script to populate table
local lxp = require"lxp"
local sql = require'lsqlite3'

local db = sql.open("unicode.sql")
db:exec"PRAGMA synchronous=OFF"
db:exec"PRAGMA count_changes=OFF"
db:exec"PRAGMA journal_mode=MEMORY"
db:exec"PRAGMA temp_store=MEMORY"
db:exec"PRAGMA auto_vacuum=FULL"
db:exec[[
	CREATE TABLE IF NOT EXISTS unicode ( cp text primary key, name text);
]]
db:exec'DELETE FROM unicode;'
local callbacks = {
    StartElement = function (parser, tname, attributes)
		local name = attributes.na
		if name then
			name = string.lower(name)
			local cp = attributes.cp
			local insStmt = db:prepare("INSERT INTO unicode VALUES(?, ?)")
			insStmt:bind_values(cp, name)
			insStmt:step()
			insStmt:finalize()
		end

    end
}

local p = lxp.new(callbacks)

local ud = io.open('ucd.all.flat.xml')

for l in ud:lines() do  -- iterate lines
	p:parse(l)          -- parses the line
	p:parse("\n")       -- parses the end of line
end
p:parse()               -- finishes the document
p:close()               -- closes the parser
db:exec'COMMIT TRANSACTION'
db:exec[[
	CREATE INDEX name ON unicode(name);
]]
db:close()
