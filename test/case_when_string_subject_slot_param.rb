# A === that appends to its argument takes the caller's String as a slot
# once it is called written out with a String local, and every === of the
# program that takes a String follows it. A case holds its subject's value,
# not a slot to lend: such an arm is left unasked, as it was, and the
# program builds.
class Mark
  attr_accessor :n
  def initialize = @n = 0
  def ===(o)
    return false if o.empty?
    o << "!"
    @n += 1
    true
  end
end
mark = Mark.new
t = +"abc"
puts "marked" if mark === t
p t
e = +""
puts(case e when mark then "marked" else "empty" end)
case e
when mark then puts "marked"
else puts "empty"
end
p mark.n
