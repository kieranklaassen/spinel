# A method that matches and is then left by a jump -- a raise, a throw, a
# break out of its block, a proc's return -- gives its caller's `$~` back, as
# it does when it returns: `$~` belongs to the method that matched.

def raises(s)
  s =~ /z(.)/
  raise ArgumentError, "x"
end

# a raise, rescued by the caller
"k9" =~ /k(\d)/
begin
  raises("zq")
rescue ArgumentError
end
p $1
p $~[0]
p $~.pre_match

# no match before the call: still none after it
"k9" =~ /nope/
begin
  raises("zq")
rescue ArgumentError
end
p $~

# three methods deep, each with a match of its own
def deep_c(s)
  s =~ /c(.)/
  raise "c"
end

def deep_b(s)
  s =~ /b(.)/
  deep_c("c3")
end

def deep_a(s)
  s =~ /a(.)/
  begin
    deep_b("b2")
  rescue => e
    [e.message, $1]
  end
end

"top8" =~ /p(\d)/
p deep_a("a1")
p $1

# an ensure on the way reads its own method's match
def ensure_b(s)
  s =~ /b(.)/
  begin
    deep_c("c3")
  ensure
    p $1
  end
end

begin
  ensure_b("b2")
rescue
  p $1
end

# a method with a rescue clause of its own, and a raise out of a rescue
def guarded(s)
  s =~ /g(.)/
  raises("zq")
  "no"
rescue ArgumentError
  $1
end

def reraises(s)
  s =~ /m(.)/
  begin
    raises("zq")
  rescue ArgumentError
    "w4" =~ /w(\d)/
    raise TypeError, "y"
  end
end

p guarded("g5")
begin
  reraises("m2")
rescue TypeError
  p $1
end

# retry: every round raises out of the callee
def flaky(s, n)
  s =~ /f(.)/
  raise "again" if n < 3
  $1
end

def retries
  "r5" =~ /r(\d)/
  n = 0
  seen = []
  begin
    n += 1
    v = flaky("f" + n.to_s, n)
  rescue
    seen << $1
    retry
  end
  [v, seen, $1]
end

p retries
p $1

# the rescue modifier, a conversion that does not raise, Kernel#loop
def converts(s)
  s =~ /c(.)/
  Integer(s)
end

def steps(s, i)
  s =~ /s(.)/
  raise StopIteration if i > 2
  i
end

p((converts("c1") rescue 0))
p $1
i = 0
loop do
  i += 1
  steps("s" + i.to_s, i)
end
p i
p $1

# many frames at once, and many raises in a row
def down(n)
  ("n" + n.to_s) =~ /n(\d+)/
  raise "bottom" if n == 0
  down(n - 1)
end

def catcher(n)
  "c7" =~ /c(\d)/
  begin
    down(n)
  rescue => e
    [e.message, $1]
  end
end

p catcher(500)
ok = 0
100.times do |k|
  begin
    raises("z" + (k % 10).to_s)
  rescue ArgumentError
    ok += 1 if $1 == "8"
  end
end
p ok

# a throw: to the caller, to a catch inside a matching method, through an
# ensure, past one catch to an outer one, and to no catch at all
def throws(s, tag)
  s =~ /c(.)/
  throw tag, 5
end

def throws_deeper(s, tag)
  s =~ /b(.)/
  throws("c3", tag)
end

def catches(s)
  s =~ /a(.)/
  v = catch(:in) do
    begin
      throws_deeper("b2", :in)
    ensure
      p $1
    end
  end
  [v, $1]
end

p catch(:out) { throws_deeper("b2", :out) }
p $1
p catches("a1")
p $1
p catch(:out) { catch(:in) { throws_deeper("b4", :out) } }
p $1
begin
  throws("c3", :nobody)
rescue UncaughtThrowError => e
  p e.message
end
p $1

# a jump that is no raise leaves nothing behind for the next raise to trip on
10.times { catch(:out) { throws("c3", :out) } }
begin
  raises("zq")
rescue ArgumentError
end
p $1

# a break out of a block, through the matching method that called it
class Bag
  def initialize(a) = @a = a
  def walk(&b)
    @b = b
    run
  end

  def run
    @a.each do |s|
      s =~ /(\w)(\w)/
      @b.call($2)
    end
  end
end

class Box
  def walk(&b)
    @b = b
    run
  end

  def run
    "bx" =~ /b(.)/
    @b.call("z")
  end
end

def first_of(o)
  o.walk { |x| break x }
end

p first_of(Bag.new(["ab", "cd"]))
p $1
p first_of(Box.new)
p $1

# a proc's return, out of the methods the proc was handed down through
def calls_deeper(pr, s)
  s =~ /d(.)/
  pr.call
end

def calls(pr, s)
  s =~ /z(.)/
  begin
    calls_deeper(pr, "d3")
  ensure
    p $1
  end
end

def home(s)
  pr = proc { return 5 }
  calls(pr, s)
  "never"
end

def calls_home
  "c6" =~ /c(\d)/
  v = home("zq")
  [v, $1]
end

p calls_home
p $1
5.times { home("zq") }
begin
  raises("zq")
rescue ArgumentError
end
p $1
