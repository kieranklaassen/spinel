# A method that matches and yields: what its block raises, breaks and returns
# the method rescues what its block raises, and goes on with its own match
def guard(s)
  s =~ /(\d+)/
  begin
    yield $1
  rescue ArgumentError => e
    p [:rescued, e.message, $1]
  end
  p [:after, $1, $~ && $~[0]]
  $1
end
"k9" =~ /k(\d)/
p guard("a12") { |w| "zz" =~ /(z)/; raise ArgumentError, w + $1 }
p $1, $~[0]
p guard("b34") { |w| w }
p $1
def ens(s)
  s =~ /(\d+)/
  yield $1
ensure
  p [:ensure, $1]
end
begin
  ens("c56") { |w| "yy" =~ /(y)/; raise "boom#{$1}" }
rescue => e
  p [e.message, $1]
end
p $1

# break, next and return out of the block
def each_num(s)
  r = []
  while s =~ /(\d)/
    s = $'
    r << yield($1)
  end
  r
end
"k9" =~ /k(\d)/
p each_num("a1b2c3") { |d| next d * 2 if d == "2"; "x" =~ /(x)/; d + $1 }
p $1
p each_num("a1b2c3") { |d| break d if d == "2"; "y" =~ /(y)/; d }
p $1
def first_even(s)
  each_num(s) { |d| "q" =~ /(q)/; return [d, $1] if d.to_i.even? }
  nil
end
p first_even("1325")
p $1
def outer(s)
  s =~ /(\w)/
  a = $1
  r = each_num(s) { |d| d =~ /(.)/; $1 }
  [a, $1, r]
end
p outer("z1z2")
p $1
x = each_num("7") { |d| d }.size
p x, $1
p(each_num("4a5") { |d| "m" =~ /(m)/; d.to_i }.sum)
p $1

# the method's block inside a built-in's block, retry, and a method that
# yields from a rescue
def words(s)
  s.scan(/(\w)(\w*)/) { yield $1, $2 }
  s =~ /\w+\z/
  $~[0]
end
"k9" =~ /k(\d)/
p words("ab cde") { |a, b| "x" =~ /(x)/; p [a, b, $1] }
p $1
def gs(s)
  s.gsub(/(\d)/) { yield($1).to_s + $1 }
end
p gs("a1b2") { |d| "zz" =~ /(z)/; d.to_i * 2 }
p $1
def tries(s)
  n = 0
  begin
    n += 1
    s =~ /(\d)/
    raise "again" if n < 3
    yield $1, n
  rescue
    retry
  end
end
p tries("u7") { |d, n| "w" =~ /(w)/; [d, n, $1] }
p $1
def resc(s)
  Integer(s)
rescue ArgumentError
  s =~ /(\d+)/
  yield $1
end
p resc("ab42") { |d| "v" =~ /(v)/; d + $1 }
p $1
