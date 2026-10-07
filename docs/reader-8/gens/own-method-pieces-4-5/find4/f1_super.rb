class Tk
  def object_id = super
end
t = Tk.new
p t.object_id == t.object_id
