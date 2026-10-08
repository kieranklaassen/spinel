# A parameter that only an empty literal reaches has no type until every
# call site has been read. A positional `[]` types it as the fixpoint
# converges; an empty keyword literal and a positional `{}` did not, so the
# parameter was typed afterwards, when a proc that returns it had already
# handed its return type (`[n, k]` read as an Integer Array, k unknown) to
# whoever took the proc. Calling the proc through a parameter then raised
# a TypeError, or answered a Hash of zeros. Each case has methods of its
# own: a second proc through the same parameter boxes it and hides the case.

# through a method that hands the proc back
def keep1(x) = x
def kw1(n, k:) = -> { [n, k] }
f = keep1(kw1(1, k: []))
p f.call

def keep2(x) = x
def kw2(n, k:) = -> { [n, k] }
p keep2(kw2(2, k: {})).call

def keep3(x) = x
def pos3(n, k) = -> { [n, k] }
p keep3(pos3(3, {})).call

def keep5(x) = x
def two5(n, k:, j:) = -> { [n, k, j] }
p keep5(two5(5, k: [], j: {})).call

# through a method that calls it
def run6(x) = x.call
def kw6(n, k:) = -> { [n, k] }
p run6(kw6(6, k: []))

def run7(x) = x.call
def pos7(n, k) = -> { [n, k] }
p run7(pos7(7, {}))

# what the answer is used for
def keep8(x) = x
def kw8(n, k:) = -> { [n, k] }
a, b = keep8(kw8(8, k: [])).call
p a, b

def keep9(x) = x
def kw9(n, k:) = -> { [n, k] }
p keep9(kw9(9, k: {})).call.last

def keep10(x) = x
def kw10(n, k:) = -> { [n, k] }
p keep10(kw10(10, k: [])).call.size

def keep11(x) = x
def kw11(n, k:) = -> { [n, k] }
v = keep11(kw11(11, k: []))
r = v.call
p r, r == [11, []]

# a Hash of the captured values
def keep15(x) = x
def vals15(n, k:) = -> { {"n" => n, "k" => k} }
h = keep15(vals15(15, k: [])).call
p h.keys, h.values

def run16(x) = x.call
def vals16(n, k:) = -> { {"n" => n, "k" => k} }
p run16(vals16(16, k: {})).values

# the other kind of empty literal at a second call site
def keep17(x) = x
def kw17(n, k:) = -> { [n, k] }
p keep17(kw17(17, k: [])).call
p keep17(kw17(18, k: {})).call

# as it was: the proc called where it was made, kept in an instance
# variable, called by map
def kw19(n, k:) = -> { [n, k] }
g = kw19(19, k: [])
p g.call
def pos20(n, k) = -> { [n, k] }
p pos20(20, {}).call

def keep12(x) = x
def kw12(n, k:) = -> { [n, k] }
@held = keep12(kw12(12, k: {}))
p @held.call

def keep13(x) = x
def kw13(n, k:) = -> { [n, k] }
p [keep13(kw13(13, k: [])), keep13(kw13(14, k: []))].map(&:call)

# filled before the proc is made, and by the proc
def keep23(x) = x
def kw23(n, k:)
  k << n
  -> { [n, k] }
end
p keep23(kw23(23, k: [])).call

def keep24(x) = x
def kw24(n, k:) = ->(v) { k << v; [n, k] }
f24 = keep24(kw24(24, k: []))
f24.call(5)
p f24.call("x")

# as it was: a parameter the method reads some other way is left alone
# (the first proc is never called; the second is right as it is)
def keep21(x) = x
def kw21(n, k:) = -> { k.max_by { |x| x.to_s }; [n, k] }
f21 = keep21(kw21(21, k: []))
p f21.lambda?

def keep22(x) = x
def kw22(n, k:) = -> { k.empty? ? [n] : [n, k] }
p keep22(kw22(22, k: [])).call

# a bare `super` hands the parameter on: left alone as well (the parent's
# proc is never called)
class Up25
  def hold(n, k:) = -> { k << n; k.max_by { |x| x.to_s } }
end
class Kw25 < Up25
  def hold(n, k:)
    @up = super
    -> { [n, k] }
  end
end
def keep25(x) = x
p keep25(Kw25.new.hold(25, k: [])).lambda?

# the answer read in a proc that captures a name of the builtin's own
# (`max_by` calls its parameter n)
def keep26(x) = x
def kw26(n, k:) = -> { [n, k] }
f26 = keep26(kw26(26, k: []))
n = 3
g26 = -> { n += 1; f26.call.last.max_by { |x| x.to_s } }
p g26.call, n
f26.call.last << 5 << 12
p g26.call, n
