class Object
  def relay(m, *a) = "Object#relay #{m} #{a.size}"
end
class Door
end
m = [:open, :size][ARGV.size]
puts Door.new.relay(m)
