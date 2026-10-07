class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
t = ARGV.size > 5 ? Tk.new(4) : nil
p t.ident
