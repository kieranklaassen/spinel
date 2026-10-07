# Methods that match and yield, one inside another's block
# three deep: blocks yielding on
def inner(s)
  s =~ /(c+)/
  yield $1
  $1
end
def mid(s)
  s =~ /(b+)/
  r = inner(s) { |w| yield w, $1 }
  [r, $1]
end
def outer(s)
  s =~ /(a+)/
  r = mid(s) { |w, b| yield w, b, $1 }
  [r, $1]
end
"k9" =~ /k(\d)/
p outer("aabbbc") { |w, b, a| p [w, b, a, $1]; "z3" =~ /z(\d)/ }, $1

# a method that does not match between two that do
def pass(s)
  inner(s) { |w| yield w }
end
"k9" =~ /k(\d)/
p pass("xcc") { |w| p [w, $1]; w =~ /(.)/ }, $1

# while loop with break and next in the block
def toks(s)
  n = 0
  while s =~ /\A(\w)/
    n += 1
    yield $1
    s = $'
  end
  [n, $~]
end
"k9" =~ /k(\d)/
p toks("abcd") { |ch| next if ch == "b"; break ch if ch =~ /(c)/ }, $1
p toks("abcd") { |ch| ch =~ /(.)/ }, $1

# jumps through two exchanges
def mid_rescue(s)
  s =~ /(b+)/
  begin
    inner(s) { |w| yield w, $1 }
  rescue ArgumentError
    [:mid, $1]
  end
end

"k9" =~ /k(\d)/
p mid("bbcc") { |w, b| "z1" =~ /z(\d)/; break [w, b, $1] }, $1

"k9" =~ /k(\d)/
r = catch(:out) { mid("bbcc") { |w, b| "z2" =~ /z(\d)/; throw :out, [w, b] } }
p r, $1

"k9" =~ /k(\d)/
begin
  mid("bbcc") { |w, b| "z3" =~ /z(\d)/; raise ArgumentError, w }
rescue ArgumentError => e
  p [e.message, $1]
end

"k9" =~ /k(\d)/
p mid_rescue("bbcc") { |w, b| "z4" =~ /z(\d)/; raise ArgumentError, w }, $1

def find_it(s)
  "m5" =~ /m(\d)/
  mid(s) { |w, b| return [w, b, $1] if w =~ /(c)/ }
  :none
end
"k9" =~ /k(\d)/
p find_it("bbcc"), $1

# a raise from deep inside the block, through a method that matches
def deep(n)
  "d#{n}" =~ /d(\d)/
  raise ArgumentError, "deep" if n == 0
  deep(n - 1)
end
"k9" =~ /k(\d)/
p mid_rescue("bbcc") { |w, b| "z6" =~ /z(\d)/; deep(3) }, $1
begin
  mid("bbcc") { |w, b| "z7" =~ /z(\d)/; deep(3) }
rescue ArgumentError
  p $1
end

# a spliced method inside its own block, and a throw across both
def tok(s)
  n = 0
  while s =~ /\A(\w+)\s*/
    s = $'
    n += 1
    yield $1
  end
  n
end
"k9" =~ /k(\d)/
r = []
c = tok("ab cd") { |w| r << w; tok(w + " " + w) { |v| r << v; v =~ /(.)\z/; r << $1 }; r << $1.inspect }
p c, r, $1
v = catch(:out) do
  tok("one two three") { |w| "t" =~ /(t)/; throw :out, [w, $1] if w == "two" }
  :none
end
p v, $1
def twice(s)
  s =~ /(.)/
  yield $1
  yield $1 + $1
  $1
end
p twice("pq") { |w| w =~ /(.)\z/; p [w, $1] }
p $1
h = twice("rs") { |w| twice(w) { |u| u =~ /(.)/ } }
p h, $1
