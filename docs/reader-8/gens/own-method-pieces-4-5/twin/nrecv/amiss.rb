class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
a = [Tk.new(1)]
t = a[5]
p t.ident
