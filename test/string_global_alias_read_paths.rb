# The global route's refusal asks whether the String's other name is read.
# These are no reads of it, and the programs build: an instance variable
# of the same name in a class that is neither above nor below, a writer,
# and an operator write of another variable.
class Doc
  attr_writer :body
  def initialize
    @body = +"az"
    @count = 0
  end
  def publish
    $last = @body
    $last << "!"
    @count += 1
    $last
  end
end
class Note
  attr_reader :body
  def initialize = @body = +"note"
  def shown = @body
end
doc = Doc.new
p doc.publish
doc.body = +"new"
p doc.publish
note = Note.new
p note.body, note.shown

def tag
  s = +"az"
  n = 0
  $last = s
  $last << "!"
  n += 1
  [$last, n]
end
p tag
