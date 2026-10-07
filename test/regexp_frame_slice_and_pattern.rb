# A method that matches through slice!, an index assignment that names a
# group or a pattern of `in` keeps its caller's $~, as one that matches
# with =~ does: the match is the method's own. The caller's registers
# were overwritten.
def cut(s) = s.slice!(/(b)/)
def cut_group(s) = s.slice!(/(b)(c)/, 2)
def put_group(s)
  s[/(b)(c)/, 2] = "v"
  s
end
def kind(s)
  case s
  in /a(b)/ then :ab
  in /x/ then :x
  else :other
  end
end
def has?(s) = (s in /(c)/) ? true : false
def pair(a)
  case a
  in [/k(\d)/, Integer => n] then n
  else 0
  end
end
def own(s)
  s.slice!(/(b)/)
  $1
end
def own_in(s)
  case s
  in /(c)/ then $1
  else $~
  end
end

p $~
"q1" =~ /q(\d)/
p cut(+"abc"), $1, $~[0]
p cut_group(+"abc"), $1
p put_group(+"abc"), $1
p kind("ab"), kind("xy"), kind("zz"), $1
p has?("abc"), has?("zz"), $1
p pair(["k7", 3]), pair(["zz", 3]), $1
p own(+"abc"), $1
p own_in("abc"), own_in("zz"), $1

# a miss leaves the caller's too
p cut(+"zzz"), $1
p put_group(+"abc"), $~.pre_match, $~.post_match
