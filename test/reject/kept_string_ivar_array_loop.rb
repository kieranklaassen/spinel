# A String a method pushes onto its instance variable's Array, mutated on the
# next round of the loop that hands it over: CRuby holds the one String three
# times. Refused.
class Log
  def initialize; @lines = []; end
  def add(v); @lines << v; end
  def lines = @lines
end
log = Log.new
s = +""
3.times do |i|
  s << i.to_s
  log.add(s)
end
p log.lines
