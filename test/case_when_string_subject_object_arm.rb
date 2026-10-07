# A String case subject asks an object arm its own === (or ==, which
# Object#=== calls), as an Array or a Hash subject does: the String arm of
# `when` answered false before the method ran.
class Prefix
  attr_accessor :s
  def initialize(s) = @s = s
  def ===(o) = o.start_with?(@s)
end
class Named
  attr_accessor :name
  def initialize(name) = @name = name
  def ==(o) = o == @name
end
class Loose < Prefix; end
class Any
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o.to_s.size == @n
end

ab = Prefix.new("ab")
case "abc"
when ab then puts "prefix"
else puts "none"
end
p(case "xbc" when ab then :prefix else :none end)
p(case "abd" when "abc", ab then :listed else :none end)

%w[ruby rust go].each do |w|
  case w
  when Prefix.new("ru") then puts "ru: #{w}"
  when Named.new("go") then puts "named"
  else puts "other"
  end
end

def kind(s, pat)
  case s + "!"
  when pat then :hit
  when "zz!" then :plain
  else :miss
  end
end
p kind("ab", Loose.new("a"))
p kind("zz", Loose.new("a"))
p kind("q", Loose.new("a"))

three = Any.new(3)
p(three === 100)
p(three === "abcd")
[1, "abc"].each { |v| p(case v when three then :three else :other end) }
p(case "xyz" when three then :three else :other end)
p(case "xy" when three then :three else :other end)
