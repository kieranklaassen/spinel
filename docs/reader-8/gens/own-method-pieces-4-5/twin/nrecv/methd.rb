class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
def mk(f) = f ? Tk.new(4) : nil
p mk(false).ident
