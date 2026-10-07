class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = method(:__id__).call
end
t = Tk.new(4)
u = Tk.new(5)
p t.ident == t.ident
