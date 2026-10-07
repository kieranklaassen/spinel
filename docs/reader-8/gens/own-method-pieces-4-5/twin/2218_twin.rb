class Tk
  def initialize(n) = @n = n
  def ident = "id#{@n}"
end
a = Tk.new(1)
p a.ident.upcase
p a.ident.size
p a.ident + "!"
p a.ident.start_with?("id")
p a.ident.to_sym
p a.ident * 2
p a.ident.chars
