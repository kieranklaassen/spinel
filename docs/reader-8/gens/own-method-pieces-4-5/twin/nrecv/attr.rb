class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
class Holder
  attr_accessor :t
end
h = Holder.new
h.t = Tk.new(4) if ARGV.size > 5
p h.t.ident
