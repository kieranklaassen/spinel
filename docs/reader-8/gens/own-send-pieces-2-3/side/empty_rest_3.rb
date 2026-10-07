class Object
  def relay(m, *a) = "Object#relay #{m} #{a.size}"
end
m = [:open, :size][ARGV.size]
puts 5.relay(m)
puts "x".relay(m)
