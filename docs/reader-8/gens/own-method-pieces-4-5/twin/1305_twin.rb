class Tk
  def initialize(n) = @n = n
  def n = @n
  def zz_remove(name) = "own #{@n}"
end
a = [Tk.new(1)]
t = a[5]
x = t.zz_remove(:@n)
p x.class
