# A Proc call of more than 16 arguments fills every slot it passes, so a
# Method's proc, which binds its parameters by the count, reads them all.

def ends(a, *r, z) = [a, r.size, z]

def literal
  pr = method(:ends).to_proc
  [pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17), pr.(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17), pr.yield(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17), pr[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]]
end
p literal

def kinds
  pr = method(:ends).to_proc
  [pr.call("s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "s12", "s13", "s14", "s15", "s16", "s17"), pr.call(1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, :z)]
end
p kinds

def spread
  pr = method(:ends).to_proc
  [pr.call(*(1..20).to_a), pr.call(*(1..17).map(&:to_s)), pr.call(*(1..16).to_a)]
end
p spread

def wide(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17) = a1 + a17

def fixed
  pr = method(:wide).to_proc
  [pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17), pr.call(*(1..17).to_a)]
end
p fixed

def own_parameters
  l = lambda { |a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17| a1 + a17 }
  pr = proc { |a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17| [a16, a17] }
  [l.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17), pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17)]
end
p own_parameters

def keyed(*r, k: 0) = [r.size, r[-1], k]

def keywords
  pr = method(:keyed).to_proc
  [pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, k: 5), pr.call(*(1..30).to_a)]
end
p keywords

def channel
  pr = method(:ends).to_proc
  pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64)
end
p channel

# the seventeenth argument runs, once
def last_runs
  log = []
  pr = method(:ends).to_proc
  r = pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, (log << :last; 17))
  [r, log]
end
p last_runs

def passed(&blk)
  yield(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17)
end
p passed(&method(:ends))

class Holder
  def initialize = @tag = "t"
  def ends(a, *r, z) = [a, r.size, z, @tag]
end

# every argument is held while the call runs
def held
  pr = Holder.new.method(:ends).to_proc
  bad = 0
  300.times do |i|
    r = pr.call(*(1..20).map { |j| "s#{i}-#{j}" })
    bad += 1 unless r == ["s#{i}-1", 18, "s#{i}-20", "t"]
  end
  [bad, pr.call("s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "s12", "s13", "s14", "s15", "s16", "s17")]
end
p held

# an argument past the sixteenth that answers nil runs, and arrives as nil
def none(log) = (log << :none; nil)

def nil_last
  log = []
  pr = method(:ends).to_proc
  q = proc { |a, b| [a, b] }
  [pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, none(log)), q.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, none(log)), q.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, ()), log]
end
p nil_last
