class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
t = nil
t = Tk.new(4) if ARGV.size > 5
p t.ident
