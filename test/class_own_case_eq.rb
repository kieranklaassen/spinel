# A class that defines === itself (`def self.===`) is asked it. `Klass === x`
# was folded to x.is_a?(Klass) for every class of the program, so the
# method was compiled and never called. It is asked where its parameter is
# boxed: each class here meets more than one kind of argument.
class Even
  def self.===(o) = o.is_a?(Integer) && o.even?
end
p(Even === 4)
p(Even === 3)
p(Even === "x")
p([4, 3, "x", nil].map { |v| Even === v })
p(Even === Even.new)
p(Even.===(4))
if Even === 10 then puts "even" else puts "odd" end

# defined in `class << self`, in a module, through `extend`
class Odd
  class << self
    def ===(o) = o.is_a?(Integer) && o.odd?
  end
end
p(Odd === 3)
p(Odd === 4)
p(Odd === "x")
module Small
  def self.===(o) = o.is_a?(Integer) && o < 10
end
p(Small === 3)
p(Small === 30)
p(Small === "x")
module Seven
  def ===(o) = o == 7
end
class Lucky
  extend Seven
end
p(Lucky === 7)
p(Lucky === Lucky.new)

# inherited, and a === that calls the one above it
class Sub < Even; end
p(Sub === 4)
p(Sub === Sub.new)
class Not < Even
  def self.===(o) = !super
end
p(Not === 3)
p(Not === 4)
p(Not === "x")

# an argument that is boxed, and the method's own answer type
mixed = [500, "apple", 5, "fig"]
class Big
  def self.===(o) = o > 100
end
p(Big === mixed[0])
p(Big === mixed[2])
class Starts
  def self.===(o) = o.start_with?("a")
end
p(Starts === mixed[1])
p(Starts === mixed[3])
class Any
  def self.===(o) = o
end
p(Any === 5)
p(Any === nil)
puts(Any === false ? "t" : "f")

# the method runs once a call
class Count
  @hits = 0
  def self.===(o)
    @hits += 1
    o == :yes
  end
  def self.hits = @hits
end
p(Count === :yes)
p(Count === :no)
p(Count === 3)
p Count.hits

# a class with no === of its own, and one whose === only calls super, are
# Module#=== as before
class Plain; end
p(Plain === Plain.new)
p(Plain === 4)
class Same
  def self.===(o) = super
end
p(Same === Same.new)
p(Same === 3)
