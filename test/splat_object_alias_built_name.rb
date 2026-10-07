# `alias` under a name built at run time gives a class a to_a the compiler
# does not see. A splatted object of such a program is not handed over as
# itself (test/splat_object_into_method.rb): it keeps the form it had, and
# the call raises. CRuby raises for the two values the to_a answers; spinel,
# which does not know the alias, for the Array the object is wrapped in.
class A
  def initialize(n) = @n = n
  def n = @n
  def items = [n, :s]
  alias :"to_#{:a}" items
end
class B
  def initialize(n) = @n = n
  def n = @n
  def items = [n, :s]
  s = "a"
  alias :"to_#{s}" items
end
class C
  def initialize(n) = @n = n
  def n = @n
  def items = [n, :s]
  alias :"to_#{:a}" :"it#{:ems}"
end
class D
  def initialize(n) = @n = n
  def n = @n
  def items = [n, :s]
end
class E
  def initialize(n) = @n = n
  def n = @n
  def items = [n, :s]
  alias :"to_#{:a}" :items
end

def num(a) = a.n

class D
  alias :"to_#{:a}" items
end

def try
  p yield
rescue ArgumentError, NoMethodError
  puts "raised"
end

a = A.new(1)
b = B.new(2)
c = C.new(3)
d = D.new(4)
e = E.new(5)
try { num(*a) }
try { num(*b) }
try { num(*c) }
try { num(*d) }
try { num(*e) }
