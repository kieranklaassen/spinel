# A keyword given twice to a top-level method that appends to it, called
# from inside a class: the last value wins and goes over as a copy, as it
# does from top level, so the call is refused there too.
def app(k:) = k << "!"
class Holder
  def go
    s = +"s"
    o = +"o"
    app(k: o, k: s)
    p s
  end
end
Holder.new.go
