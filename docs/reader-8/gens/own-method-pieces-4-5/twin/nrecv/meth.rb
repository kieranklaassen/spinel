class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
def mk(f) = f ? Tk.new(4) : nil
t = mk(false)
p t.ident
