class Tk
  def object_id = super
end
t = Tk.new
h = {}
h[t.object_id] = 1
p h.size
