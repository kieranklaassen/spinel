# A writer whose receiver no name holds (`a.pop.w = v`, `K.new(x).w = v`)
# takes that receiver before its value is made. A `&.` call in the value made
# its arguments after it, under the nil test, and a collection there freed
# the receiver: the store landed on an object the arguments had just made.
class K
  attr_accessor :w
  def initialize(v) = (@v = v; @w = nil)
  def vv = @v
  def keep(a) = ($got = a)
end

$last = K.new("seed")
$got = nil

def untouched?(a, r)
  a.size == 4 && a.all? { |k| k.w.nil? } && a[0].vv == "a#{r}" && a[3].vv == "d#{r}"
end

def popped(r)
  pool = [K.new("v#{r}")]
  pool.pop.w = $last&.keep([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")])
  untouched?($got, r)
end

def shifted(r)
  pool = [K.new("v#{r}")]
  pool.shift.w = $last&.keep([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")])
  untouched?($got, r)
end

def safe_writer(r)
  pool = [K.new("v#{r}")]
  pool.pop&.w = $last&.keep([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")])
  untouched?($got, r)
end

def in_block(r)
  [1].each { |q| K.new("v#{r}").w = $last&.keep([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")]) }
  untouched?($got, r)
end

n = 0
20000.times { |r| n += 1 unless popped(r) }
puts "popped #{n}"
n = 0
20000.times { |r| n += 1 unless shifted(r) }
puts "shifted #{n}"
n = 0
20000.times { |r| n += 1 unless safe_writer(r) }
puts "safe_writer #{n}"
n = 0
20000.times { |r| n += 1 unless in_block(r) }
puts "in_block #{n}"
