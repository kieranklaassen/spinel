# An exception keeps a value made after the exception itself: the message
# its `initialize` builds and hands to `super`, the parameter a bare `super`
# hands on after it was assigned, and the key and the receiver given to
# KeyError.new or NameError.new. Making the value can collect, and the
# collection promotes the exception, so the store has to be recorded.
# gc-stress-test runs this under SPINEL_GC_STRESS=2.
class ParseError < StandardError
  def initialize(line, what) = super("line #{line}: #{what}")
end

class Tagged < StandardError
  def initialize(msg)
    msg = msg + "!"
    super
  end
end

class Fixed < StandardError
  def initialize = super("fixed")
end

errs = []
600.times { |i| errs << ParseError.new(i, "unexpected token") }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.message != "line #{i}: unexpected token" }
p [errs.size, bad, errs[599].message]

errs = []
600.times { |i| errs << Tagged.new("m#{i}") }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.message != "m#{i}!" }
p [errs.size, bad, errs[599].message]

errs = []
600.times do |i|
  begin
    raise ParseError.new(i, "eof")
  rescue ParseError => e
    errs << e
  end
end
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.to_s != "line #{i}: eof" }
p [errs.size, bad, errs[0].to_s]

# the receiver is large enough to collect again after the key is stored
errs = []
600.times { |i| errs << KeyError.new("missing", key: "k#{i}", receiver: "r#{i}" * 800) }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.key != "k#{i}" || e.receiver != "r#{i}" * 800 }
p [errs.size, bad, errs[599].key, errs[599].receiver.size]

errs = []
600.times { |i| errs << NameError.new("undef", receiver: "r#{i}") }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.receiver != "r#{i}" }
p [errs.size, bad, errs[599].receiver]

# a literal message is no young value
p Fixed.new.message
