# A top-level method that yields its rest on, called from a class method:
# the block's parameter is a copy of the caller's String, as it is when
# the call is written at top level, so the call is refused there too.
def each_of(*r) = yield(*r)
class Report
  def self.go
    s = +"s"
    each_of(s) { |k| k << "!" }
    p s
  end
end
Report.go
