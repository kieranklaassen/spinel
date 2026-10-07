class Door
  def relay(m, *a) = "Door#relay #{m} #{a.size}"
end
m = [:open, :size][ARGV.size]
puts Door.new.relay(m)
