class Tk
  def initialize(n) = @n = n
end
t = ARGV.size > 5 ? Tk.new(4) : nil
p t.object_id
p t.__id__
