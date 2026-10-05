# to_a and to_h on a nil held in an Array or a Hash slot answer [] and {}.

class Memo
  def opts = (@opts ||= {a: 1})
  def list = (@list ||= [1, 2])
  def names = (@names ||= ["a"])
  def pairs = (@pairs ||= [[:k, 1]])
  def rows = (@rows ||= [[1, 2]])
  def opts_a = @opts.to_a
  def opts_h = @opts.to_h
  def list_a = @list.to_a
  def names_a = @names.to_a
  def pairs_h = @pairs.to_h
  def rows_a = @rows.to_a
end

m = Memo.new
p m.opts_a, m.opts_h, m.list_a, m.names_a, m.pairs_h, m.rows_a
p m.opts_a.size, m.opts_h.empty?, m.list_a.frozen?, "#{m.opts_a}#{m.opts_h}"
m.list_a << 3
p m.list_a
m.opts; m.list; m.names; m.pairs; m.rows
p m.opts_a, m.opts_h.to_a, m.list_a, m.names_a, m.pairs_h.to_a, m.rows_a
p m.list_a.equal?(m.list), m.opts_h.equal?(m.opts)

class Box
  attr_reader :items, :opts
  def fill = (@items = [1, 2]; @opts = {a: 1})
end

b = Box.new
p b.items.to_a, b.opts.to_a, b.opts.to_h, Array(b.items)
b.fill
p b.items.to_a, b.opts.to_a, b.opts.to_h.size, Array(b.items)

def pairs_of(opts = nil) = opts.to_a
def size_of(opts = nil) = opts.to_h.size
def each_of(list = nil)
  list.to_a.each { |x| p x }
  list.to_a.size
end

p pairs_of, pairs_of({a: 1}), size_of, size_of({a: 1, b: 2})
p each_of, each_of([3, 4])

table = {a: [1], b: [2, 3]}
p table[:c].to_a, table[:b].to_a
