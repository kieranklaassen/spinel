# A String variable on this route must not silently lose its append.
# A yielding method that keeps its block as a value is compiled as a
# function, and its String parameter is a copy.
class Report
  def initialize
    @seen = []
  end
  def line(out, text, &fmt)
    @seen << fmt
    out << yield(text)
    @seen.size
  end
end
buf = +"> "
n = Report.new.line(buf, "ok") { |t| t.upcase }
p n, buf
