# A String that spells a store comes back as written.
#
# The write-barrier pass reads the emitted C as text. A frozen literal is no
# longer in that text (it is a file-scope object written after the pass), but
# the written pieces of an interpolation, the Symbol name table and a Regexp's
# source still are. `puts "q->iv_ary = #{n};"` printed `SP_WBO(q)->i3;`: the
# pass wrapped the store it read inside the piece, and the longer text was cut
# to the piece's length. A Symbol kept the whole longer text, so it missed the
# same name built at run time, a Regexp matched the longer text only, and
# `"(*_cell_n) = #{n};"` beside a captured `n` went the same way in the pass
# for captured locals.
#
# The first lines print such text. The rest count rounds: a store written
# behind such text, on its C line, still takes its barrier. Each stores a
# fresh value into a holder that is old, allocates, and reads the value back;
# the line is the number of rounds that read back something else.
#
# The gc-minor-test leg also runs this under SPINEL_GC_VERIFY_GEN=1
# SPINEL_GC_STRESS=1, which reports a holder that went unrecorded.

class Slot
  attr_accessor :ary
  def initialize
    @ary = nil
  end
end

def churn(n)
  i = 0
  x = nil
  while i < n
    x = ["c#{i}", "d#{i}"]
    i += 1
  end
  x
end

class Owner
  def initialize
    @last = Slot.new
    x = nil
    y = nil
    @set = ->(v) { "(*_cell_x) = #{v.size};".size + (x = v).size }
    @get = -> { x }
    @set2 = ->(v) { /_cell_y\) = 1;/.source.size + (y = v).size }
    @get2 = -> { y }
  end

  def set(which, a, b)
    v = [a, b]   # one allocation, so the value is young when it is stored
    case which
    when 0 then /q->iv_ary = 1;/.source.size + (@last.ary = v).size
    when 1 then { "say \"q->iv_ary = #{a};\"" => (@last.ary = v) }
    when 2 then "it's q->iv_ary = 1;\\#{a}".size + (@last.ary = v).size
    when 3 then @set.call(v)
    when 4 then @set2.call(v)
    end
    nil
  end

  def ok?(which, a, b)
    w = which == 3 ? @get.call : which == 4 ? @get2.call : @last.ary
    w.size == 2 && w[0] == a && w[1] == b
  end
end

def rounds(o, which, n, gap)
  bad = 0
  r = 0
  while r < n
    a = "a#{r}"
    b = "b#{r}"
    o.set(which, a, b)
    churn(gap)
    bad += 1 unless o.ok?(which, a, b)
    r += 1
  end
  bad
end

# Long gaps first, for a plain run, where a collection takes thousands of
# allocations; then short ones for the leg's stress run, where a few do.
def wrong_rounds(which)
  o = Owner.new
  churn(5000)   # the owner and its holder are old from here on
  rounds(o, which, 60, 1500) + rounds(o, which, 600, 30)
end

q = Slot.new
q.ary = [1]
n = [0]
bump = -> { n = [n[0] + 1] }
bump.call
m = n[0]

puts "q->iv_ary = #{m};"
puts "x = y->iv_ary = z; /* \"q->iv_ary=#{m};\" */"
puts "#{m}; q->iv_ary = 1; x"
puts <<~C
  void f(sp_Slot *q) {
    q->iv_ary = #{m};
  }
C
p :"q->iv_ary = 1;"
p %i[q->iv_ary=1; b]
p :"q->iv_ary = 1;" == ("q->" + "iv_ary = 1;").to_sym
p("xq->iv_ary = 1;" =~ /q->iv_ary = 1;/)
p(/q->iv_ary = 1;/.source)
puts "(*_cell_n) = #{m};"
p :"(*_cell_n) = 1;"
p q.ary, n

puts "behind a Regexp's source: #{wrong_rounds(0)}"
puts "behind a Hash key with quotes in it: #{wrong_rounds(1)}"
puts "behind a piece that ends in a backslash: #{wrong_rounds(2)}"
puts "a captured local, behind a piece: #{wrong_rounds(3)}"
puts "a captured local, behind a Regexp's source: #{wrong_rounds(4)}"
