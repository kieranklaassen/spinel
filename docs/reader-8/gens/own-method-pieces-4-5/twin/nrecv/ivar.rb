class Tk
  def initialize(n) = @n = n
  def n = @n
  def ident = "id-#{@n}"
end
class Holder
  def initialize = @t = nil
  def set(t) = @t = t
  def run
    p @t.ident
  end
end
h = Holder.new
h.run
h.set(Tk.new(4))
