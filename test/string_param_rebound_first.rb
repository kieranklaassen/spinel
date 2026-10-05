# A proc's parameter the body's first statement binds to a new String
# (`s = s.dup`): the appends after it are to that String, so nothing is
# lost when the call hands over a copy, and a global is not refused.
$g = +"a"
f = ->(s) { s = s.dup; s << "x"; s }
p f.call($g)
p $g

g = ->(s) { s = s + "y"; s << "x"; s }
p g.call($g)
p $g

h = ->(s) { s = +"q"; s << "x"; s }
p h.call($g)
p $g

class Holder
  def initialize = @s = +"i"
  def go
    f = ->(k) { k = k.clone; k << "x"; k }
    p f.call(@s)
    p @s
  end
end
Holder.new.go

# a local is still shared with a proc that appends to it as it is
l = +"l"
k = ->(s) { s << "x"; s = s.dup; s << "y"; s }
p k.call(l)
p l
