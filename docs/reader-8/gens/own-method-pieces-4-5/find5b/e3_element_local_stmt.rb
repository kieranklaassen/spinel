class Tk
  def initialize(n) = @n = n
  def instance_variable_get(name) = "own #{@n}"
end
a = [Tk.new(1)]
t = a.first
x = t.instance_variable_get(:@n)
puts "done"
