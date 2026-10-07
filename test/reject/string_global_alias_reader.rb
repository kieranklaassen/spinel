# attr_reader reads the instance variable as `def body = @body` does: the
# String copied into the global is read through it after the append.
class Doc
  attr_reader :body
  def initialize = @body = +"az"
  def publish
    $last = @body
    $last << "!"
  end
end
doc = Doc.new
doc.publish
p doc.body
