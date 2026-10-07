class Tk
  def initialize(n) = @n = n
  def instance_variables = "own #{@n}"
end
a = [Tk.new(1)]
t = a[0]
x = t.instance_variables
p x
