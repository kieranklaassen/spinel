class Tk
  def initialize(n) = @n = n
  def object_id
    @n > 100 ? -1 : super
  rescue NameError
    -2
  end
end
t = Tk.new(4)
u = Tk.new(5)
p t.object_id == u.object_id
p t.object_id.class
