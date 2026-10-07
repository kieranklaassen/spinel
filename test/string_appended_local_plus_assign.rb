# `t += v` on a String local that is also appended to with `<<`: String#+
# answers a new String, so t leaves the String its other names hold.

# a local of its own, appended to before and after
out = +""
out << "a"
out += "b"
out << "c"
p out

def join_all(xs)
  r = +""
  xs.each do |x|
    r << "," unless r.empty?
    r += x
  end
  r
end
p join_all(%w[a b c])

# two names for one String, through a chain and through a plain write
def chain_alias
  s = +""
  t = s << "a" << "b"
  t += "x"
  s << "!"
  t << "?"
  [s, t]
end
p chain_alias

def plain_alias
  s = +"ab"
  t = s
  t << "c"
  s += "x"
  t << "!"
  s << "?"
  [s, t]
end
p plain_alias

# a third name keeps the String the second one left
def third_name
  s = +""
  t = s << "a" << "b"
  u = t
  u += "x"
  s << "!"
  [s, t, u]
end
p third_name

# on a parameter's String
def tail(s)
  t = s << "a" << "b"
  t += "x"
  t << "?"
  [s, t]
end
x = +""
p tail(x), x

# under a condition, in a loop, in a block and in a proc
def maybe(flag)
  s = +""
  t = s << "a" << "b"
  t += "x" if flag
  t << "y"
  [s, t]
end
p maybe(true), maybe(false)

def loops
  s = +""
  t = s << "a" << "b"
  i = 0
  while i < 3
    t += i.to_s
    i += 1
  end
  3.times { |j| t += "#{j}," }
  [s, t]
end
p loops

def in_proc
  s = +""
  t = s << "a" << "b"
  pr = proc { t += "!" }
  pr.call
  pr.call
  s << "?"
  [s, t]
end
p in_proc

# the operand: the String itself, an operand that appends to it, one that
# rebinds the local, an interpolation, a call, a boxed String
def self_operand
  s = +""
  t = s << "a" << "b"
  t += s
  s << "!"
  t += t
  [s, t]
end
p self_operand

def appending_operand
  s = +""
  t = s << "a" << "b"
  t += (s << "z"; "q")
  [s, t]
end
p appending_operand

def rebinding_operand
  s = +""
  t = s << "a" << "b"
  t += (t = +"Q"; "x")
  [s, t]
end
p rebinding_operand

def dashes(n) = "-" * n
def other_operands
  s = +"ab"
  t = s
  s << "c"
  t += "#{t}/#{s}"
  t += dashes(2)
  t += [1, "x", nil][1]
  [s, t]
end
p other_operands

# a frozen String: the sum is a new one
def frozen_receiver
  s = +""
  t = s << "a" << "b"
  t.freeze
  t += "x"
  t << "y"
  [s.frozen?, t.frozen?, t]
end
p frozen_receiver

# nil on either side raises as String#+ does
def nil_receiver(n)
  s = +"ab"
  t = nil
  t = s if n > 5
  s << "c"
  t += "x"
  [s, t]
rescue NoMethodError
  "NoMethodError"
end
p nil_receiver(0), nil_receiver(9)

def not_a_string(i)
  a = [1, "x", nil]
  s = +"ab"
  t = s
  s << "c"
  t += a[i]
  [s, t]
rescue TypeError
  "TypeError"
end
p not_a_string(0), not_a_string(1), not_a_string(2)

# the operand converts as String#+ converts it
class Suffix
  def to_str = "w"
end
def converted_operand
  s = +"ab"
  t = s
  s << "c"
  t += Suffix.new
  [s, t]
end
p converted_operand

def integer_operand
  s = +"ab"
  t = s
  s << "c"
  t += 5
  [s, t]
rescue TypeError
  "TypeError"
end
p integer_operand

def nil_operand
  s = +"ab"
  t = s
  s << "c"
  t += nil
  [s, t]
rescue TypeError
  "TypeError"
end
p nil_operand
