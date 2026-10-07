# An exception that leaves a synchronize block or a select! block inside a
# begin goes to that begin's rescue first; the ensure around the begin runs
# once, after it.
$m = Mutex.new

def sync_rescued(i, log)
  begin
    begin
      $m.synchronize { log << "s"; raise IOError, "in" if i >= 0 }
    rescue IOError => e
      log << "r:" << e.message
    end
    log << "ab"
  ensure
    log << "oe"
  end
  log << "z"
end

def select_rescued(i, log)
  begin
    begin
      [1, 2, 3].select! { |q| raise IOError, "in" if q == 2 && i >= 0; q > 0 }
    rescue IOError => e
      log << "r:" << e.message
    end
    log << "ab"
  ensure
    log << "oe"
  end
  log << "z"
end

# no clause of the begin between matches: the ensure runs once and the
# exception leaves the method
def sync_passed(i, log)
  begin
    begin
      $m.synchronize { log << "s"; raise IOError, "in" if i >= 0 }
    rescue KeyError
      log << "nm"
    end
    log << "ab"
  ensure
    log << "oe"
  end
  log << "z"
end

# the same, and the outer begin has a clause that does not match either
def sync_passed_twice(i, log)
  begin
    begin
      $m.synchronize { log << "s"; raise IOError, "in" if i >= 0 }
    rescue KeyError
      log << "nm"
    end
    log << "ab"
  rescue KeyError
    log << "onm"
  ensure
    log << "oe"
  end
  log << "z"
end

# two begins between
def sync_second_rescue(i, log)
  begin
    begin
      begin
        $m.synchronize { log << "s"; raise IOError, "in" if i >= 0 }
      rescue KeyError
        log << "nm"
      end
    rescue IOError
      log << "r2"
    end
  ensure
    log << "oe"
  end
  log << "z"
end

# the ensure of a method body
def sync_def_ensure(i, log)
  begin
    $m.synchronize { log << "s"; raise IOError, "in" if i >= 0 }
  rescue IOError
    log << "r"
  end
  log << "ab"
ensure
  log << "oe"
end

# a synchronize around the begin: its unlock is the ensure
def sync_in_sync(i, log)
  n = Mutex.new
  n.synchronize do
    begin
      $m.synchronize { log << "s"; raise IOError, "in" if i >= 0 }
    rescue IOError
      log << "r"
    end
    log << "ab"
  end
  log << (n.locked? ? "L" : "u")
end

# nothing raised: as before
def sync_quiet(log)
  begin
    begin
      $m.synchronize { log << "s" }
    rescue IOError
      log << "r"
    end
  ensure
    log << "oe"
  end
  log << "z"
end

def run(name, log)
  yield
rescue IOError => e
  log << " out:" << e.message
ensure
  puts "#{name}: #{log} #{$m.locked?}"
end

log = +""; run("sync_rescued", log) { sync_rescued(1, log) }
log = +""; run("select_rescued", log) { select_rescued(1, log) }
log = +""; run("sync_passed", log) { sync_passed(1, log) }
log = +""; run("sync_passed_twice", log) { sync_passed_twice(1, log) }
log = +""; run("sync_second_rescue", log) { sync_second_rescue(1, log) }
log = +""; run("sync_def_ensure", log) { sync_def_ensure(1, log) }
log = +""; run("sync_in_sync", log) { sync_in_sync(1, log) }
log = +""; run("sync_quiet", log) { sync_quiet(log) }

# the frames balance: 300 turns of each, then a raise is rescued where it is written
t = 0
300.times do |i|
  l = +""
  begin
    sync_rescued(i, l); select_rescued(i, l); sync_second_rescue(i, l); sync_def_ensure(i, l); sync_in_sync(i, l)
    sync_passed(i, l)
  rescue IOError
    t += 1
  end
  begin
    sync_passed_twice(i, l)
  rescue IOError
    t += 1
  end
  t += l.size
end
puts t
begin
  raise "late"
rescue => e
  puts e.message
end
