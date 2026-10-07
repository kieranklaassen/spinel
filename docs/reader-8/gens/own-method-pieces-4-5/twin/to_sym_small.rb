class Tk
  def initialize(n) = @n = n
  def ident = "id#{@n}"
end
a = Tk.new(1)
p a.ident.to_sym
