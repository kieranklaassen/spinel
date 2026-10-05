# A store read for its value takes its write barrier after the value is built.
#
# `def fill(h, i); h.s = mk(i); end` answers the store, so the store is the
# last statement of a C statement expression. The barrier pass has no room
# for a statement there in its own form and wrapped the holder instead,
# `SP_WBO(h)->iv_s = sp_mk(i)`: the barrier ran, then the value was built,
# then the store was made. A collection while the value was built started
# the remembered set over, so the old holder's young value was recorded
# nowhere and the next minor mark freed it in the slot.
#
# Every case writes once into each of a row of holders that are old,
# allocates, and reads the holders back. Each line is the number of holders
# that read back something else:
#
#   * the store as a method's value, as a local's value, as an argument and
#     under `||=`, the value a String a method builds
#   * a Range of two built Strings stored through `self`
#   * a store in the value of such a store, `y = (k.s = last.s = v)`, which
#     the pass goes on into
#
# The gc-minor-test leg also runs this under SPINEL_GC_VERIFY_GEN=1
# SPINEL_GC_STRESS=1, which reports the holder that went unrecorded.

class Slot
  attr_accessor :s, :r

  def initialize(s)
    @s = s
    @r = nil
  end

  def span(a, z)
    self.r = (a..z)
  end
end

def churn(n)
  i = 0
  x = nil
  while i < n
    x = [Slot.new("c#{i}"), "d#{i}"]
    i += 1
  end
  x
end

# enough allocation for a collection to fall inside the value
def mk(i)
  churn(200)
  "a" + i.to_s
end

def id(x) = x

def as_value(h, i)
  h.s = mk(i)
end

def as_local(h, i)
  x = (h.s = mk(i))
  x.size
end

def as_argument(h, i)
  id(h.s = mk(i)).size
end

def as_or_assign(h, i)
  h.s = nil
  h.s ||= mk(i)
  nil
end

def as_range(h, i)
  h.span("a" + i.to_s, "f" + i.to_s)
  nil
end

def nested(h, k, i)
  y = (k.s = h.s = mk(i))
  y.size
end

def wrong_holders(which)
  hs = []
  i = 0
  while i < 400
    hs << Slot.new("h")
    i += 1
  end
  k = Slot.new("k")
  churn(5000)   # the holders are old from here on
  i = 0
  while i < 400
    case which
    when 0 then as_value(hs[i], i)
    when 1 then as_local(hs[i], i)
    when 2 then as_argument(hs[i], i)
    when 3 then as_or_assign(hs[i], i)
    when 4 then as_range(hs[i], i)
    when 5 then nested(hs[i], k, i)
    end
    i += 1
  end
  churn(5000)
  bad = 0
  i = 0
  while i < 400
    if which == 4
      r = hs[i].r
      bad += 1 unless r.first == "a" + i.to_s && r.last == "f" + i.to_s
    else
      bad += 1 unless hs[i].s == "a" + i.to_s
    end
    i += 1
  end
  bad
end

puts "a method's value: #{wrong_holders(0)}"
puts "a local's value: #{wrong_holders(1)}"
puts "an argument: #{wrong_holders(2)}"
puts "under ||=: #{wrong_holders(3)}"
puts "a Range through self: #{wrong_holders(4)}"
puts "in the value of such a store: #{wrong_holders(5)}"
