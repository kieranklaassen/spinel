# s[/re/, n] = v with a value that runs code, and a group number that is not
# a literal from 0 to 9: a negative number counts back from the last group and
# the tenth group and beyond are replaced, as with any other value. The value
# runs first; then a group that took no part raises.
def k(n)
  s = +"hello world!"
  s[/(h)(e)(l)(l)(o)( )(w)(x)?(o)(r)(l)(d)(!)/, n] = [1, "Q"].last
  p [n, s]
rescue IndexError => e
  p [n, e.class, e.message]
end
k(-1); k(-2); k(-6); k(-13); k(-14); k(0); k(8); k(9); k(10); k(13); k(14); k(16)

def noisy(tag)
  puts "value #{tag}"
  raise ArgumentError, "boom" if tag == :boom
  "V"
end

def pick(tag) = tag == :int ? 5 : noisy(tag)

def w(n, tag)
  s = +"hello world!"
  s[/(h)(e)(l)(l)(o)( )(w)(x)?(o)(r)(l)(d)(!)/, n] = pick(tag)
  p [n, s]
rescue IndexError, ArgumentError, TypeError => e
  p [n, e.class, e.message]
end
w(-1, :ok); w(-6, :ok); w(10, :ok); w(-6, :boom); w(12, :boom); w(-2, :int)

# an instance variable, and a number that is computed
class Line
  def initialize = @s = +"hello world!"
  def put(n)
    @s[/(h)(e)(l)(l)(o)( )(w)(x)?(o)(r)(l)(d)(!)/, n - 1] = [1, "Q"].last
    @s
  end
end
p Line.new.put(0), Line.new.put(11), Line.new.put(-12)
