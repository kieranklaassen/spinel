class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
def use(t)
  p t.ident
end
use(nil)
use(Tk.new(4)) if ARGV.size > 5
