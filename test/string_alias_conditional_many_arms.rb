# A String a conditional hands over is the arm's own String however many
# arms the conditional has. The list of a write's arms held sixteen, and a
# local read only by a later arm was left off it: that arm handed over a
# copy, and a change made through the new name never reached the String.
# Every arm is taken once, and each append is of LONG, which always
# reallocates.

LONG = "!" * 100

def grow(x) = (x << LONG; nil)

# a `case` of eighteen arms, appended to
def pick(k)
  s0 = +"0"; s1 = +"1"; s2 = +"2"; s3 = +"3"; s4 = +"4"; s5 = +"5"
  s6 = +"6"; s7 = +"7"; s8 = +"8"; s9 = +"9"; s10 = +"a"; s11 = +"b"
  s12 = +"c"; s13 = +"d"; s14 = +"e"; s15 = +"f"; s16 = +"g"; s17 = +"h"
  t = case k
      when 0 then s0
      when 1 then s1
      when 2 then s2
      when 3 then s3
      when 4 then s4
      when 5 then s5
      when 6 then s6
      when 7 then s7
      when 8 then s8
      when 9 then s9
      when 10 then s10
      when 11 then s11
      when 12 then s12
      when 13 then s13
      when 14 then s14
      when 15 then s15
      when 16 then s16
      else s17
      end
  t << LONG
  all = [s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17]
  p all.index { |s| s.size > 1 }, all.index { |s| t.equal?(s) }
end
18.times { |k| pick(k) }

# the same handed to a method that appends, then replaced in place
def lend(k)
  s0 = +"0"; s1 = +"1"; s2 = +"2"; s3 = +"3"; s4 = +"4"; s5 = +"5"
  s6 = +"6"; s7 = +"7"; s8 = +"8"; s9 = +"9"; s10 = +"a"; s11 = +"b"
  s12 = +"c"; s13 = +"d"; s14 = +"e"; s15 = +"f"; s16 = +"g"; s17 = +"h"
  t = case k
      when 0 then s0
      when 1 then s1
      when 2 then s2
      when 3 then s3
      when 4 then s4
      when 5 then s5
      when 6 then s6
      when 7 then s7
      when 8 then s8
      when 9 then s9
      when 10 then s10
      when 11 then s11
      when 12 then s12
      when 13 then s13
      when 14 then s14
      when 15 then s15
      when 16 then s16
      else s17
      end
  grow(t)
  all = [s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17]
  i = all.index { |s| s.size > 1 }
  t.replace("R")
  p i, all.index("R")
end
18.times { |k| lend(k) }

# the seventeenth arm at the top level, and a frozen String there
k = ARGV.size + 16
a = +"a"; b = +"b"
t = case k
    when 0 then a
    when 1 then a
    when 2 then a
    when 3 then a
    when 4 then a
    when 5 then a
    when 6 then a
    when 7 then a
    when 8 then a
    when 9 then a
    when 10 then a
    when 11 then a
    when 12 then a
    when 13 then a
    when 14 then a
    when 15 then a
    when 16 then b
    else a
    end
t << LONG
p a.size, b.size, t.equal?(b)
z = "v".freeze
begin
  y = case k
      when 0 then a
      when 1 then a
      when 2 then a
      when 3 then a
      when 4 then a
      when 5 then a
      when 6 then a
      when 7 then a
      when 8 then a
      when 9 then a
      when 10 then a
      when 11 then a
      when 12 then a
      when 13 then a
      when 14 then a
      when 15 then a
      when 16 then z
      else a
      end
  y << LONG
rescue FrozenError => err
  p err.class
end
