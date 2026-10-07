# An instance variable is the object's: the subclass's method reads the
# String the superclass's method copied into a global. The append through
# the global never reaches it: refused, not compiled with "az".
class Doc
  def initialize = @body = +"az"
  def publish
    $last = @body
    $last << "!"
  end
end
class Page < Doc
  def body = @body
end
page = Page.new
page.publish
p page.body
