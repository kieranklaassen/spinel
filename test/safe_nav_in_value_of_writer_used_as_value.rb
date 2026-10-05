# A writer used as a value, on a receiver no name holds, with a `&.` writer
# as its own value: the Array the `&.` call stores was made under the nil
# test, where its root ended with the test, and a collection freed it while
# only the stored-into object still held it.
class K
  attr_accessor :w
  def initialize(v) = (@v = v; @w = nil)
  def vv = @v
end

$last = K.new("seed")

def untouched?(a, r)
  a.size == 4 && a.all? { |k| k.w.nil? } && a[0].vv == "a#{r}" && a[3].vv == "d#{r}"
end

def as_value(r)
  pool = [K.new("v#{r}")]
  x = (K.new("u#{r}").w = ($last&.w = [K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")]))
  untouched?($last.w, r) && x.equal?($last.w) && pool.size == 1
end

n = 0
20000.times { |r| n += 1 unless as_value(r) }
puts "as_value #{n}"
