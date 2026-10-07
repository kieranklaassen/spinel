# A `&.` call of a method that answers nothing (its C function is void), with
# an argument, where its value cannot stay in the call's place: under `||`,
# `&&`, a ternary, a `case`, a rescue, or beside a later operand that is made.
# The guard is a statement ahead, and holds no value.

class Logger
  attr_reader :notes
  def initialize = @notes = 0
  def info(msg) = puts("info: #{msg}")
  def note(msg)
    @notes += 1
    nil
  end
end

log = ARGV.size > 5 ? nil : Logger.new
off = ARGV.size > 5 ? Logger.new : nil
t = "x"
puts(log&.info(t + "a") ? "then" : "else")
puts(off&.info(t + "a") ? "then" : "else")
v = log&.note(t + "b") || "none"
p v
log&.info(t + "c") && puts("and")
log&.note(t + "d") or puts("or")
off&.info(t + "d") or puts("off")
v = [log&.info(t + "e"), t + "f"]
p v
puts "<#{log&.info(t + "g")}> #{t.upcase}"
p(log&.note(t + "h"), [1, 2])
case log&.info(t + "i")
when nil then puts "nil"
else puts "other"
end
v, w = off&.info(t + "k"), t + "l"
p v, w
v = nil
v ||= log&.info(t + "m")
p v
v = (log&.info(t + "n") rescue 1)
p v
v = ARGV.size == 0 ? log&.note(t + "o") : 1
p v
p log.notes
# where the value can stay in the call's place it does, after what stands
# before it in the statement
def tick = (puts "tick"; 1)
puts "#{tick} <#{log&.info(t + "p")}>"
