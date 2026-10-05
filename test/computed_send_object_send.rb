# A send the program defines on Object is every object's: a computed send
# reaches it whatever the receiver, as it does in CRuby. The two names the
# program leaves alone are still Object's own and name their method.

class Object
  def send(m, *a) = "Object#send #{m} #{a.size}"
end

class Door
  def open = "open"
  def size = 1
  def knock(m) = send(m)
  def ring(m) = self.send(m, 1)
end

Pt = Struct.new(:a) do
  def open = "s-open"
  def size = 3
end

def open = "main open"
def size = 7

m = [:open, :size][ARGV.size]
puts Door.new.send(m)
puts Door.new.send(m, 1, 2)
puts Door.new.knock(m)
puts Door.new.ring(m)
puts Pt.new(1).send(m)
puts send(m)
k = [:size, :first][ARGV.size]
puts [3, 1, 2].send(k)
puts "abc".send(k)

puts Door.new.public_send(m)
puts Door.new.__send__(m)
puts Pt.new(1).__send__(m)
puts [3, 1, 2].public_send(k)
