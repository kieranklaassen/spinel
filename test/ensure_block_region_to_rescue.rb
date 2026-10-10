# A Mutex#synchronize block and the loop of select! each run under a region
# that undoes their work when the block raises. The exception that leaves
# such a region goes where one leaving a begin's ensure goes: to the rescue
# between it and the enclosing ensure, or to the rescue clauses of the
# enclosing begin, and to the enclosing ensure only after them.

class AppError < StandardError; end
class DeepError < AppError; end
class Coded < StandardError
  def initialize(code); super("coded"); @code = code; end
  def code; @code; end
end
LIST = [KeyError, IndexError]
$log = []
$m = Mutex.new

# the rescue and the ensure are clauses of one begin
def locked(m)
  m.synchronize { raise TypeError, "held" }
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end
m = Mutex.new
locked(m)
p m.locked?

def filtered(xs)
  xs.select! { |x| raise TypeError, "at " + x.to_s if x == 3; x > 1 }
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end
xs = [1, 2, 3, 4]
filtered(xs)
p xs

# a begin stands between the block and the ensure: its clause takes it
def between(m, log)
  begin
    begin
      m.synchronize { raise IOError, "in" }
    rescue IOError
      log << "rescued "
    end
  ensure
    log << "ensure "
  end
end
log = String.new
begin
  between(m, log)
rescue IOError
  log << "escaped "
end
puts log

# its clause misses it: the ensure body runs once and the exception goes on
def missed(m, log)
  begin
    begin
      m.synchronize { log << "s"; raise IOError, "in" }
    rescue TypeError
      log << "r"
    end
  rescue ArgumentError
    log << "R"
  ensure
    log << "e"
  end
end
log = String.new
begin
  missed(m, log)
rescue IOError => e
  log << " out:" + e.message
end
puts log, m.locked?

def missed_loop(xs, log)
  begin
    begin
      xs.select! { |x| log << "f"; raise IOError, "in" if x == 2; true }
    rescue TypeError
      log << "r"
    end
  ensure
    log << "e"
  end
end
log = String.new
xs = [1, 2, 3]
begin
  missed_loop(xs, log)
rescue IOError => e
  log << " out:" + e.message
end
puts log
p xs

# each kind of clause of the enclosing begin, taking the exception and
# missing it
def run(tag)
  yield
  $log << "#{tag}: returned"
rescue Exception => e
  $log << "#{tag}: out #{e.class}"
end

run("sync miss") do
  begin
    $m.synchronize { raise TypeError, "t" }
  rescue ArgumentError
    $log << "wrong clause"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
run("sync second") do
  begin
    $m.synchronize { raise DeepError, "d" }
  rescue ArgumentError
    $log << "wrong clause"
  rescue AppError => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
run("sync bare") do
  begin
    $m.synchronize { raise IOError, "io" }
  rescue => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
run("sync bare miss") do
  begin
    $m.synchronize { raise NotImplementedError, "ni" }
  rescue => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
run("sync splat") do
  begin
    $m.synchronize { raise IndexError, "i" }
  rescue *LIST => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
run("sync all") do
  begin
    $m.synchronize { raise NotImplementedError, "ni" }
  rescue Exception => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
run("select miss") do
  a = [1, 2, 3]
  begin
    a.select! { |x| raise TypeError, "t" if x == 2; true }
  rescue ArgumentError
    $log << "wrong clause"
  ensure
    $log << "outer #{a.size}"
  end
end
run("select") do
  a = [1, 2, 3]
  begin
    a.select! { |x| raise KeyError, "k" if x == 2; true }
  rescue KeyError => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{a.size}"
  end
end
run("select bare") do
  a = [1, 2, 3]
  begin
    a.select! { |x| raise "plain" if x == 3; x > 1 }
  rescue => e
    $log << "took #{e.class} #{e.message}"
  ensure
    $log << "outer #{a.inspect}"
  end
end

# the object raised in the block is the one the clause binds
run("object") do
  begin
    $m.synchronize { raise Coded.new(7) }
  rescue ArgumentError
    $log << "wrong clause"
  rescue Coded => e
    $log << "took #{e.class} #{e.code} #{e.message}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end

# an ensure inside the block hands its exception to the block's region,
# which passes it on to the clause
run("ensure in the block") do
  begin
    $m.synchronize do
      begin
        raise Coded.new(8)
      ensure
        $log << "inner " + "x" * 3
      end
    end
  rescue Coded => e
    $log << "took #{e.code} #{e.message}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
puts $log

# many times: no frame is left armed and none is popped twice
def quiet(m, out, i)
  begin
    m.synchronize { raise TypeError, "s" if i.odd? }
    [1, 2].select! { |x| raise TypeError, "f" if i % 4 == 0; true }
    raise TypeError, "q"
  ensure
    out << "i"
  end
rescue TypeError => e
  out << e.message
ensure
  out << "o"
end
out = String.new
2000.times { |i| quiet(m, out, i) }
puts out.size, out[0, 12], m.locked?
begin
  raise "late"
rescue => e
  puts e.message
end
