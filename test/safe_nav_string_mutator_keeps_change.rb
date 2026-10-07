# A String mutator called with `&.` changes its receiver, as it does with
# `.`: when the call is used for its value, when another call follows it,
# and on a receiver read out of a container.
def str(v) = v ? +"ab" : nil
def bstr(v) = [+"ab", nil, 5][v ? 0 : 1]

s = str(true)
p s&.concat("x")
p s
s = str(true)
p s&.concat("x")&.size
p s
s = str(true)
p s&.<<("y").size
p s
s = str(true)
p s&.upcase!
p s
s = str(true)
p s&.replace("zz")
p s
s = str(true)
p s&.insert(1, "Q")
p s
s = str(true)
p s&.slice!(0)
p s
s = str(true)
p s&.clear
p s
s = str(true)
s&.succ!
p s
s = str(true)
s << "  "
p s&.strip!
p s
y = :ab.to_s
y&.setbyte(0, 65)
p y
n = str(false)
p n&.concat("x")
p n

b = bstr(true)
p b&.concat("x")
p b
b = bstr(true)
b&.upcase!
p b

$g = str(true)
p $g&.concat("z")
p $g

class K
  def initialize = @s = str(true)
  def run
    p @s&.replace("zz")
    p @s
  end
end
K.new.run

def m(u)
  p u&.capitalize!
  u
end
p m(+"q")
t = str(true)
l = -> { t&.concat("y")&.size }
p l.call
p t
