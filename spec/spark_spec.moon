busted = require'busted'
describe = busted.describe
it = busted.it
util = require'util'

Reverse = (L) ->
  out = {}
  for i=#L,1,-1
    out[#out+1] = L[i]
  return out

describe "spark util", ->
  it "should draw sparkline given numbers", ->
    numbers = {10,11,12,13,14,15,16,17}
    ticks = {'▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'}
    assert.are_same table.concat(ticks), util.spark.sparkline(numbers)
    assert.are_same Reverse(table.concat(ticks)), Reverse(util.spark.sparkline(numbers))
    numbers = {40,40,40,40,41}
    line = '▁▁▁▁█'
    assert.are_same line, util.spark.sparkline(numbers)
    numbers = {
    145.41
    145.138
    144.61
    142.555
    142.555
    141.9115
    142.044
    141.1755
    141.949
    142.923
    143.59
    143.59
    145.8115
    146.7205
    146.645
    147.865
    145.594
    136.84
    136.84
    134.25
    132.23
    133.545
    134.558
    133.29
    132.73
    132.73
    132.828
    132.79
    129.6055
    }
    line = '▇▆▆▅▅▅▅▅▅▆▆▆▇▇▇█▇▃▃▂▂▂▂▂▂▂▂▂▁'
    assert.are_same line, util.spark.sparkline([n for n in *numbers])

