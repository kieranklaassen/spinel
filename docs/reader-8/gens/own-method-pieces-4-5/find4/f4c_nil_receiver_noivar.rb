class Tk
  def object_id = 7
end
t = ARGV.size > 5 ? Tk.new : nil
p t.object_id
