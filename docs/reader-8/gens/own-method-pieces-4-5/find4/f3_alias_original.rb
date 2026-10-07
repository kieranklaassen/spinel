class Tk
  alias_method :orig_id, :object_id
  def object_id = orig_id
end
t = Tk.new
p t.object_id == t.object_id
