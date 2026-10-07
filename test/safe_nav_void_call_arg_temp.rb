# A `&.` call of a method that answers nothing (its C function is void), on a
# receiver with a C nil of its own, with an argument: each argument runs into
# a temp ahead of the call, so the guard is a statement, and it holds no value.

class Logger
  def initialize = @lines = 0
  def info(msg) = puts("info: #{msg}")
  def note(msg)
    @lines += 1
    nil
  end
  attr_reader :lines
end

class Job
  def initialize(log) = @log = log
  def run(t)
    @log&.info("run " + t)
    @log&.note([t, t])
    :ran
  end
end

def tell(l, t) = l&.info(t.upcase)

log = ARGV.size > 5 ? nil : Logger.new
off = ARGV.size > 5 ? Logger.new : nil
t = "x"
log&.info("started")
off&.info("started")
log&.info(1)
log&.info(t + "y")
log&.info("<#{t}>")
p log&.note("z")
x = off&.note("z")
p x
p Job.new(log).run("a")
p Job.new(nil).run("b")
p tell(log, "q")
p tell(nil, "q")
puts(log&.info("w") ? "then" : "else")
p log&.lines
