class Tk
  def object_id = __id__
end
t = Tk.new
p t.object_id == t.object_id
