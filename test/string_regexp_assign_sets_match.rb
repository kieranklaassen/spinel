# `s[re] = v` is a match: it leaves $~ at what it replaced, and nil where
# it finds nothing
s = +"hello world"
s[/o (w)/] = "0 W"
p s, $~[0], $1, $`, $'

def swap(t)
  t[/(\d+)-(\d+)/] = "x"
  [t, $1, $2, $~.pre_match, $~.post_match]
end

"k9" =~ /k(\d)/
p swap(+"a 12-34 b")
p $1

def miss(t)
  "zz" =~ /z/
  begin
    t[/q/] = "y"
  rescue IndexError => e
    [e.message, $~]
  end
end
p miss(+"abc")
p $1

def twice(t)
  t[/a(.)/] = "1"
  a = $1
  t[/c(.)/] = "2"
  [t, a, $1, $~.begin(0)]
end
p twice(+"abcd")
p $1

u = +"x-y"
seen = []
3.times { |i| u[/-|\d/] = i.to_s; seen << $~[0] }
p seen
p u, $~[0]
p((+"ab").then { |w| w[/b/] = "c"; $~ && $~[0] })
p $~[0]

# the value is read before the match is made
v = +"a1b2"
"k9" =~ /k(\d)/
v[/[a-z](\d)/] = $1 + "!"
p v, $1

# an ivar, and a match of the method's own before it
class Doc
  def initialize(s) = @s = s
  def fix
    "q7" =~ /q(\d)/
    a = $1
    @s[/(\w+)@(\w+)/] = "x"
    [@s, a, $1, $2]
  end
end
"k9" =~ /k(\d)/
p Doc.new(+"to bob@home now").fix
p $1

# a frozen receiver raises before anything is replaced
f = "abc"
begin
  f[/b/] = "x"
rescue FrozenError => e
  p e.class, f
end

# a Regexp as a Hash key is no match
h = {}
"k9" =~ /k(\d)/
h[/a/] = 1
p h.size, $1
