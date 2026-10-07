# A retry goes back to its begin. Written inside another begin in the rescue
# clause, it leaves that begin's frame as well. Each method is called 200
# times: a frame left behind on every retry would run the handler stack out.

def in_begin(log)
  tries = 0
  begin
    raise IOError, "again" if tries < 3
    log << tries
  rescue IOError
    tries += 1
    begin
      retry if tries < 3
      log << :gave_up
    rescue ArgumentError
      log << :no
    end
  end
  tries
end

def in_two_begins(log)
  tries = 0
  begin
    raise IOError, "again" if tries < 2
    log << tries
  rescue IOError
    tries += 1
    begin
      begin
        retry if tries < 3
      rescue KeyError
        log << :no
      end
    rescue ArgumentError
      log << :no
    end
  end
  tries
end

def value_position(log)
  tries = 0
  v = begin
    raise IOError, "again" if tries < 2
    7
  rescue IOError
    tries += 1
    begin
      (log << :x; retry) if tries < 3
      -1
    rescue ArgumentError
      -2
    end
  end
  log << v
  tries
end

def with_ensure(log)
  tries = 0
  begin
    raise IOError, "again" if tries < 2
    log << tries
  rescue IOError
    tries += 1
    begin
      retry if tries < 3
    rescue ArgumentError
      log << :no
    end
  ensure
    log << :ensure
  end
  tries
end

def then_raise(log)
  tries = 0
  begin
    raise IOError, "again" if tries < 2
    log << tries
  rescue IOError
    tries += 1
    begin
      retry if tries < 2
      raise ArgumentError, "inner"
    rescue ArgumentError => e
      log << e.message
    end
    retry
  end
  tries
end

def in_loop(log)
  tries = 0
  begin
    raise IOError, "again" if tries < 3
    log << tries
  rescue IOError
    tries += 1
    i = 0
    while i < 2
      i += 1
      begin
        retry if tries < 3
        log << i
      rescue ArgumentError
        log << :no
      end
    end
  end
  tries
end

def check(name)
  log = []
  n = yield log
  puts "#{name}: #{n} #{log.inspect}"
end

check("in_begin") { |log| in_begin(log) }
check("in_two_begins") { |log| in_two_begins(log) }
check("value_position") { |log| value_position(log) }
check("with_ensure") { |log| with_ensure(log) }
check("then_raise") { |log| then_raise(log) }
check("in_loop") { |log| in_loop(log) }

total = 0
log = []
200.times do
  total += in_begin(log) + in_two_begins(log) + value_position(log)
  total += with_ensure(log) + then_raise(log) + in_loop(log)
end
puts total
puts log.size
p $!

begin
  Integer("oops")
rescue ArgumentError => e
  puts e.message
end
