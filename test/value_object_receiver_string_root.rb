# A small object that is never written is kept by value: the struct lives in
# the C temp its call reads it from. Made in place, its String is held by
# that temp alone, and was collected while the call's arguments were built
# or while the method itself allocated: the method then read a freed String.
# Each line counts the wrong answers of 2,000 calls.
class Name
  def initialize(r) = @s = "hello world " * r
  def has(k) = @s[k] ? 1 : 0
  def len(k) = @s.length + k.length
  def kw(k:) = @s.length + k.length
  def ==(k) = @s.length + k.length == 2885
  def own
    t = "x" * 300
    u = t + "y"
    @s.length + u.length - 301
  end
  def blk
    yield("ab" + "cd")
    @s.length
  end
  def to_s
    t = "x" * 300
    @s + t
  end
end

def mk(r) = Name.new(r)

bad = 0
2_000.times { bad += 1 unless Name.new(240).has("wor" + "ld") == 1 }
p bad

bad = 0
2_000.times { |i| bad += 1 unless Name.new(240).len("w#{i}") == 2881 + i.to_s.length }
p bad

# a method's answer is as fresh as an object made in place
bad = 0
2_000.times { bad += 1 unless mk(240).has("wor" + "ld") == 1 }
p bad

# no argument: the method allocates before it reads its String
bad = 0
2_000.times { bad += 1 unless Name.new(240).own == 2880 }
p bad

bad = 0
2_000.times { bad += 1 unless Name.new(240).kw(k: "k" * 300) == 3180 }
p bad

# a method with a block, expanded where it is called
bad = 0
2_000.times { bad += 1 unless Name.new(240).blk { |x| x * 50 } == 2880 }
p bad

# a comparison the class defines
bad = 0
2_000.times { bad += 1 unless Name.new(240) == "wor" + "ld" }
p bad

# an interpolated part with its own to_s
bad = 0
2_000.times { bad += 1 unless "#{Name.new(240)}".length == 3180 }
p bad

# held in a local, the call was right already
bad = 0
2_000.times do
  n = Name.new(240)
  bad += 1 unless n.has("wor" + "ld") == 1
end
p bad
