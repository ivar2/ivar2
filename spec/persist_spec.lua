local busted = require'busted'
local describe = busted.describe
local it = busted.it
local persist
local backend = 'persist'
describe("test persist lib", function()
  it("should load", function()
    persist = require(backend or 'sqlpersist')({
      verbose = true,
      namespace = 'test_please_delete',
      clear = true
    })
  end)
  it("should store", function()
    persist['test'] = 'teststring'
    persist['testtbl'] = {['test1']='teststring',test2='ok'}
  end)
  it("should unload", function()
    package.loaded['persist'] = nil
  end)
  it("should load", function()
    persist = require(backend or 'sqlpersist')({
      verbose = true,
      namespace = 'test_please_delete',
      clear = false
    })
  end)
  it("should fetch", function()
    assert.are_equal(persist['test'], 'teststring')
    assert.are_same({['test1']='teststring',test2='ok'}, persist['testtbl'])
  end)
  it("should clear testkeys", function()
    persist = require(backend or 'sqlpersist')({
      verbose = true,
      namespace = 'test_please_delete',
      clear = true
    })
  end)
end)
