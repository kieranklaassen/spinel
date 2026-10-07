# `case x when Klass` asks a class that defines === itself, as `Klass === x`
# written out does: Module#=== (is_a?) is only the default.

class Even
  def self.===(o) = o.is_a?(Integer) && o.even?
end
class Plain; end

def kind(x)
  case x
  when Even then :even
  when Plain then :plain
  else :other
  end
end
p kind(4)
p kind(3)
p kind("s")
p kind(nil)
p kind(Even.new)
p kind(Plain.new)

# the value form, and a boxed subject
p([4, 3, "s", nil, Even.new].map { |v| case v when Even then :e else :o end })

# a subject of one type handed to the boxed parameter
class Big
  def self.===(o) = o > 100
end
[4, 500].each do |i|
  case i
  when Big then puts "big"
  else puts "small"
  end
end

class AWord
  def self.===(o) = o.to_s.start_with?("a")
end
["apple", "fig"].each { |s| puts(case s when AWord then "a-word" else "other" end) }

# inherited, and one that asks its parent's
class Kid < Big; end
case 700
when Kid then puts "kid: big"
else puts "kid: small"
end
class Small < Big
  def self.===(o) = !super
end
case 5
when Small then puts "small: yes"
else puts "small: no"
end

# the class that was named is `self` in the method
class Base
  def self.===(o) = o.is_a?(self) && o.ok
  def ok = true
end
class Leaf < Base
  def ok = false
end
[Base.new, Leaf.new, 3].each do |v|
  case v
  when Leaf then puts "leaf"
  when Base then puts "base"
  else puts "neither"
  end
end

# a method that allocates, beside a subject no variable holds
class Twice
  def self.===(o) = [o, o].join == "xx"
end
def fresh = "x" + ""
case fresh
when AWord then puts "a-word"
when Twice then puts "twice"
else puts "no"
end

# two classes in one arm, and a module's own
module Tiny
  def self.===(o) = o.is_a?(Integer) && o < 3
end
[1, 4, 7, "s"].each do |v|
  r = case v
      when Tiny, Even then "tiny or even"
      else "no"
      end
  puts r
end

# a === that only calls super is Module#===
class Sup
  def self.===(o) = super
end
p(case Sup.new when Sup then 1 else 2 end)
p(case 3 when Sup then 1 else 2 end)
