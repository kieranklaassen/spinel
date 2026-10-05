# `o&.v = x` holds its receiver while the value is built. The statement
# runs on a temp under a nil test, and the temp was not rooted: a receiver
# nothing else holds was collected while the value allocated, and the
# store went into the object that took its place -- one the value had
# just made, which then no longer answered its own v.

class K
  def initialize(v) = @v = v
  attr_accessor :v
end

def mk(v) = K.new(v)
def nk(r) = r % 3 == 0 ? nil : K.new("v#{r}")

# the receiver is made in place, the value makes objects of its class
bad = 0
20000.times do |r|
  K.new("v#{r}")&.v = (a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
         e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}")
         r)
  bad += 1 unless [a, b, c, d, e, f, g, h].map { |k| k.v } ==
                    ["a#{r}", "b#{r}", "c#{r}", "d#{r}", "e#{r}", "f#{r}", "g#{r}", "h#{r}"]
end
p bad

# ... it comes out of a method, and the value is a String built in place
bad = 0
20000.times do |r|
  mk("v#{r}")&.v = (a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
         e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}")
         "s#{r}" + "t#{r}")
  bad += 1 unless [a, b, c, d, e, f, g, h].map { |k| k.v } ==
                    ["a#{r}", "b#{r}", "c#{r}", "d#{r}", "e#{r}", "f#{r}", "g#{r}", "h#{r}"]
end
p bad

# ... it is nil one round in three, and then the value does not run
bad = 0
made = 0
20000.times do |r|
  a = b = nil
  nk(r)&.v = (made += 1; a = K.new("a#{r}"); b = K.new("b#{r}"); r)
  bad += 1 unless r % 3 == 0 ? a.nil? : a.v == "a#{r}" && b.v == "b#{r}"
end
p bad, made

# ... the value clears the only variable that held it
bad = 0
20000.times do |r|
  o = K.new("v#{r}")
  o&.v = (o = nil
         a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
         e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}")
         r)
  bad += 1 unless o.nil? && [a, b, c, d, e, f, g, h].map { |k| k.v } ==
                    ["a#{r}", "b#{r}", "c#{r}", "d#{r}", "e#{r}", "f#{r}", "g#{r}", "h#{r}"]
end
p bad

# a receiver a variable holds keeps what was stored
o = K.new("v")
20000.times { |r| o&.v = [r, r + 1] }
p o.v
