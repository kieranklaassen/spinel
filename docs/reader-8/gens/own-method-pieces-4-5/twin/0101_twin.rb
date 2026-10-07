class Tk
  def initialize(n) = @n = n
  def n = @n
  def fetch_own(name) = :own
end
def mk(f) = f ? Tk.new(4) : nil
t = mk(false)
p t.fetch_own(:@n)
