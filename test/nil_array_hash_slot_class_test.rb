# is_a?, kind_of? and instance_of? on a nil held in an Array or a Hash slot:
# nil is a NilClass and is neither an Array nor a Hash.

class Shelf
  def initialize(full) = (if full then @list = [1]; @opts = {a: 1}; @rows = [[1]] end)

  def list_tests
    [@list.is_a?(Array), @list.kind_of?(Enumerable), @list.instance_of?(Array), @list.is_a?(NilClass),
     @list.instance_of?(NilClass), @list.is_a?(Object), @list.is_a?(Hash), @list.is_a?(Comparable)]
  end

  def opts_tests
    [@opts.is_a?(Hash), @opts.kind_of?(Enumerable), @opts.instance_of?(Hash), @opts.is_a?(NilClass),
     @opts.instance_of?(NilClass), @opts.is_a?(Kernel), @opts.is_a?(Array)]
  end

  def rows_tests = [@rows.is_a?(Array), @rows.is_a?(NilClass)]
end

full = Shelf.new(true)
p full.list_tests, full.opts_tests, full.rows_tests
empty = Shelf.new(false)
p empty.list_tests, empty.opts_tests, empty.rows_tests

def none?(list = nil) = list.is_a?(NilClass)
def list?(list = nil) = list.kind_of?(Array)
p none?, none?([1]), list?, list?([1])
p [1].is_a?(Array), ({a: 1}).is_a?(Hash), [1].is_a?(NilClass)
