class Tk
  def initialize(n) = @n = n
  def __id__ = "id-#{@n}"
end
t = ARGV.size > 5 ? Tk.new(4) : nil
p t.__id__
