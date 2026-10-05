# A `&.` call with a block holds its receiver while its arguments are built.
# The arguments are hoisted ahead of the spliced method, under the nil test,
# and the temp the test reads was not rooted there: a receiver nothing else
# holds was collected while an argument allocated, and the method ran on
# the object that took its place.

class K
  def initialize(v) = @v = v
  def tag(a)
    yield(@v, a.size)
  end
  def tag2(a, b)
    yield(@v, a.size + b.size)
  end
end

def mk(v) = K.new(v)
def nk(r) = r % 3 == 0 ? nil : K.new("v#{r}")

# the receiver is made in place, the argument makes eight of its class
bad = 0
20000.times do |r|
  x = K.new("v#{r}")&.tag([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}"),
                           K.new("e#{r}"), K.new("f#{r}"), K.new("g#{r}"), K.new("h#{r}")]) { |v, n| v + n.to_s }
  bad += 1 unless x == "v#{r}8"
end
p bad

# ... it comes out of a method
bad = 0
20000.times do |r|
  x = mk("v#{r}")&.tag2([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")],
                        ["e#{r}", "f#{r}", "g#{r}", "h#{r}"]) { |v, n| v + n.to_s }
  bad += 1 unless x == "v#{r}8"
end
p bad

# ... it is nil one round in three, and then no argument runs
bad = 0
made = 0
20000.times do |r|
  x = nk(r)&.tag([(made += 1; K.new("a#{r}")), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")]) { |v, n| v + n.to_s }
  bad += 1 unless x == (r % 3 == 0 ? nil : "v#{r}4")
end
p bad, made

# ... the argument clears the only variable that held it
bad = 0
20000.times do |r|
  o = K.new("v#{r}")
  x = o&.tag((o = nil; [K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}"),
                        K.new("e#{r}"), K.new("f#{r}"), K.new("g#{r}"), K.new("h#{r}")])) { |v, n| v + n.to_s }
  bad += 1 unless x == "v#{r}8" && o.nil?
end
p bad

# ... the block is a lambda built in place
bad = 0
20000.times do |r|
  x = K.new("v#{r}")&.tag([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}")], &->(v, n) { v + n.to_s })
  bad += 1 unless x == "v#{r}4"
end
p bad

# ... and the call is a statement
bad = 0
20000.times do |r|
  got = nil
  K.new("v#{r}")&.tag([K.new("a#{r}"), K.new("b#{r}"), K.new("c#{r}"), K.new("d#{r}"),
                       K.new("e#{r}"), K.new("f#{r}"), K.new("g#{r}"), K.new("h#{r}")]) { |v, n| got = v + n.to_s }
  bad += 1 unless got == "v#{r}8"
end
p bad
