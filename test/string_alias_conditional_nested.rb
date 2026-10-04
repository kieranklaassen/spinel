# A String a conditional hands over is the arm's own String however deep
# the arm stands. The walks that hand the value over arm by arm stopped at
# the eighth level of nesting, and an arm below it was handed over as nil:
# a ternary in the else of a ternary in the else of a ternary, an `if` in
# an `else` in an `else`, the tenth arm of an `elsif` chain. Every arm is
# taken once, and each probe appends LONG, which always reallocates.

LONG = "!" * 100

def seen(s) = [s[0], s.size]
def grow(x) = (x << LONG; nil)

# ternaries nested in the else, five Strings
def tern(k)
  a = +"a"; b = +"b"; c = +"c"; d = +"d"; e = +"e"
  t = k == 0 ? a : k == 1 ? b : k == 2 ? c : k == 3 ? d : e
  t << LONG
  p [a, b, c, d, e].map { |s| s.size }, [a, b, c, d, e].map { |s| t.equal?(s) }
end
5.times { |k| tern(k) }

# an `if` in each `else`
def ifs(k)
  a = +"a"; b = +"b"; c = +"c"; d = +"d"
  t = if k == 0
    a
  else
    if k == 1
      b
    else
      if k == 2
        c
      else
        d
      end
    end
  end
  t << LONG
  p [a, b, c, d].map { |s| s.size }, [a, b, c, d].map { |s| t.equal?(s) }
end
4.times { |k| ifs(k) }

# an `if` in each `then`, an `unless` in each `else`
def thens(k)
  a = +"a"; b = +"b"; c = +"c"; d = +"d"; e = +"e"
  t = if k != 0 then if k != 1 then if k != 2 then if k != 3 then e else d end else c end else b end else a end
  u = unless k != 0 then a else unless k != 1 then b else unless k != 2 then c else unless k != 3 then d else e end end end end
  t << LONG
  p [a, b, c, d, e].map { |s| s.size }, t.equal?(u)
end
5.times { |k| thens(k) }

# an `elsif` chain of twelve arms
def chain(k)
  a = +"a"; b = +"b"; c = +"c"; d = +"d"; e = +"e"; f = +"f"
  g = +"g"; h = +"h"; i = +"i"; j = +"j"; l = +"l"; m = +"m"
  t = if k == 0 then a elsif k == 1 then b elsif k == 2 then c elsif k == 3 then d
      elsif k == 4 then e elsif k == 5 then f elsif k == 6 then g elsif k == 7 then h
      elsif k == 8 then i elsif k == 9 then j elsif k == 10 then l else m end
  t << LONG
  p [a, b, c, d, e, f, g, h, i, j, l, m].map { |s| s.size }
end
12.times { |k| chain(k) }

# arms that run a statement first, a `case` in a `case`, a `||` of five
def mixed(k)
  n = 0
  a = +"a"; b = +"b"; c = +"c"; d = +"d"; e = +"e"
  t = (n += 1; k == 0 ? a : (n += 1; k == 1 ? b : (n += 1; k == 2 ? c : (n += 1; k == 3 ? d : e))))
  t << LONG
  u = case k when 0 then a else case k when 1 then b else case k when 2 then c else case k when 3 then d else e end end end end
  v = (k == 0 ? a : nil) || (k == 1 ? b : nil) || (k == 2 ? c : nil) || (k == 3 ? d : nil) || e
  grow(v)
  p n, [a, b, c, d, e].map { |s| s.size }, t.equal?(u), u.equal?(v)
end
5.times { |k| mixed(k) }

# an `elsif` chain and a `||` of eighteen: the last arms are past the
# eighth level and past the sixteenth arm both
def eighteen(k)
  s0 = +"0"; s1 = +"1"; s2 = +"2"; s3 = +"3"; s4 = +"4"; s5 = +"5"
  s6 = +"6"; s7 = +"7"; s8 = +"8"; s9 = +"9"; s10 = +"a"; s11 = +"b"
  s12 = +"c"; s13 = +"d"; s14 = +"e"; s15 = +"f"; s16 = +"g"; s17 = +"h"
  t = if k == 0 then s0 elsif k == 1 then s1 elsif k == 2 then s2 elsif k == 3 then s3
      elsif k == 4 then s4 elsif k == 5 then s5 elsif k == 6 then s6 elsif k == 7 then s7
      elsif k == 8 then s8 elsif k == 9 then s9 elsif k == 10 then s10 elsif k == 11 then s11
      elsif k == 12 then s12 elsif k == 13 then s13 elsif k == 14 then s14 elsif k == 15 then s15
      elsif k == 16 then s16 else s17 end
  grow(t)
  all = [s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17]
  i = all.index { |s| s.size > 1 }
  u = (k == 0 ? s0 : nil) || (k == 1 ? s1 : nil) || (k == 2 ? s2 : nil) || (k == 3 ? s3 : nil) ||
      (k == 4 ? s4 : nil) || (k == 5 ? s5 : nil) || (k == 6 ? s6 : nil) || (k == 7 ? s7 : nil) ||
      (k == 8 ? s8 : nil) || (k == 9 ? s9 : nil) || (k == 10 ? s10 : nil) || (k == 11 ? s11 : nil) ||
      (k == 12 ? s12 : nil) || (k == 13 ? s13 : nil) || (k == 14 ? s14 : nil) || (k == 15 ? s15 : nil) ||
      (k == 16 ? s16 : nil) || s17
  u.replace("R")
  p i, all.index("R")
end
18.times { |k| eighteen(k) }

# the other in-place methods, and a deep arm that is no local
def others(k)
  a = +"a"; b = +"b"; c = +"c"; d = +"d"
  t = k == 0 ? a : k == 1 ? b : k == 2 ? c : k == 3 ? d : +"z"
  t.replace("R")
  u = k == 0 ? b : k == 1 ? c : k == 2 ? d : k == 3 ? a : +"y"
  u.gsub!(/[a-d]/, "G")
  p [a, b, c, d], t, u
end
5.times { |k| others(k) }

# at the top level, with nothing appended the value is still the arm's
k = ARGV.size + 4
a = +"a"; b = +"b"; c = +"c"; d = +"d"; e = +"e"
t = k == 0 ? a : k == 1 ? b : k == 2 ? c : k == 3 ? d : e
p t, t.equal?(e)
t << LONG
p seen(t), seen(e)
w = +"w"
x = k == 0 ? a : k == 1 ? b : k == 2 ? c : k == 3 ? d : w
p x

# the bytes survive, and a frozen String still raises
g = +"t\0u"
h = k == 0 ? a : k == 1 ? b : k == 2 ? c : k == 3 ? d : g
h << LONG
p g.bytesize
z = "v".freeze
begin
  y = k == 0 ? a : k == 1 ? b : k == 2 ? c : k == 3 ? d : z
  y << LONG
rescue FrozenError => err
  p err.class
end
