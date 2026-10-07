class Tk
  def initialize = @calls = 0
  def calls = @calls
  def __id__
    @calls += 1
    super
  end
end
t = Tk.new
p t.__id__ == t.__id__
