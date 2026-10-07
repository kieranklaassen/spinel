class Tk
  def initialize(n) = @n = n
  def object_id = @n * 10
end
t = ARGV.size > 5 ? Tk.new(4) : nil
p t.object_id
