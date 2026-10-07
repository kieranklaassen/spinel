# A method that matches and yields is spliced where it is called: its match
# is its own, the block's is the block writer's, and each survives the other
def each_b(s)
  s =~ /(b+)/
  yield $1
  $1
end

"k9" =~ /k(\d)/
r = each_b("abbc") { |w| p [w, $1] }
p r, $1

# what the block matches is its writer's; the method's own survives the yield
r = each_b("abbc") { |w| w =~ /(.)\z/ }
p r, $1

# a method that matches in a loop and reads $' after the yield
def tokens(s)
  while s =~ /\A\s*(\w+)/
    yield $1
    s = $'
  end
  $~
end

"k9" =~ /k(\d)/
out = []
r = tokens("ab cd ef") { |t| t =~ /(.)\z/; out << $1 }
p out, r, $1

# the block of scan yields on
def words(s)
  s.scan(/(\w)\w*/) { yield $~[0], $1 }
end

"k9" =~ /k(\d)/
out = []
words("ab cd") { |w, i| out << [w, i, $1] }
p out, $1

# the value of the yield, and a block that touches no match
def first_b(s)
  s =~ /(b+)/
  x = yield($1)
  [x, $1]
end

"k9" =~ /k(\d)/
p first_b("abbc") { |w| w.size }, $1
p first_b("abbc") { |w| "q7" =~ /q(\d)/ ? $1 : nil }, $1

# jumps out of the block and out of the method
def guarded(s)
  s =~ /(b+)/
  begin
    yield $1
  rescue ArgumentError
    return [:rescued, $1]
  end
  [:done, $1]
end

"k9" =~ /k(\d)/
begin
  each_b("abbc") { |w| w =~ /(.)\z/; raise ArgumentError, "x" }
rescue ArgumentError
  p [:top, $1]
end

"k9" =~ /k(\d)/
p guarded("abbc") { |w| w =~ /(.)\z/; raise ArgumentError, "x" }, $1
p guarded("abbc") { |w| w =~ /(.)\z/ }, $1

"k9" =~ /k(\d)/
r = each_b("abbc") { |w| w =~ /(.)\z/; break 5 }
p r, $1

def finder(s)
  each_b(s) { |w| return $1 if w =~ /(.)\z/ }
  :none
end
"k9" =~ /k(\d)/
p finder("abbc"), $1

"k9" =~ /k(\d)/
r = catch(:out) { each_b("abbc") { |w| w =~ /(.)\z/; throw :out, 7 } }
p r, $1

r = each_b("abbc") { |w| next 3 if w =~ /(.)\z/; 4 }
p r, $1

# one spliced method inside another's block
def outer(s)
  s =~ /(a+)/
  each_b(s) { |w| yield w, $1 }
  $1
end
"k9" =~ /k(\d)/
p outer("aabbc") { |w, a| p [w, a, $1]; "z3" =~ /z(\d)/ }, $1

class Tok
  def initialize(s) = @s = s
  def each
    @s.scan(/(\w)(\w*)/) { yield $1, $2 }
    self
  end
  def first_word
    return nil unless @s =~ /(\w+)/
    yield $1
    $1
  end
end
"k9" =~ /k(\d)/
t = Tok.new("ab cd")
t.each { |a, b| p [a, b, $1] }
p t.first_word { |w| w =~ /(.)\z/ }, $1
