# A top-level method called from inside a class. A global yielded on to a
# proc that appends goes over as a copy, as it does from top level, so the
# call is refused: only the class's own methods were asked for the method
# called, the top-level one was never found, and the append was lost.
def app(s, &b) = b.call(s)
$g = +"g"
class Holder
  def go
    pr = proc { |k| k << "!" }
    app($g, &pr)
    p $g
  end
end
Holder.new.go
