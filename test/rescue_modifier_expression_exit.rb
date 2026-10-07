# A return, next or break written inside the expression of a rescue modifier
# leaves the expression, and the modifier's frame with it. Each shape runs
# 200 times: a frame left behind stops the program at the 65th.

def show(e)
  e ? "#{e.class}: #{e.message}" : "nil"
end

# return from a block, the modifier written after the block's `end`
def first_number(words)
  words.each do |w|
    return Integer(w) if w =~ /\A\d+\z/
  end rescue nil
  0
end

# return from a begin whose value the modifier guards
def parse(line)
  n = begin
    return 80 if line.empty?
    Integer(line)
  end rescue 0
  n + 1
end

# next and break in a while loop
def sum_skipping(list)
  total = 0
  i = 0
  while i < list.size
    v = list[i]
    i += 1
    total += ((next if v.empty?; Integer(v)) rescue 100)
  end
  total
end

def sum_until_stop(list)
  total = 0
  i = 0
  while i < list.size
    v = list[i]
    i += 1
    (break if v == "stop"; total += Integer(v)) rescue total += 100
  end
  total
end

# next and break in a block
def each_skipping(list)
  total = 0
  list.each do |v|
    total += ((next if v.empty?; Integer(v)) rescue 100)
  end
  total
end

def each_until_stop(list)
  total = 0
  list.each do |v|
    (break if v == "stop"; total += Integer(v)) rescue total += 100
  end
  total
end

# break out of a modifier that stands in a rescue clause
def stop_in_clause(list)
  total = 0
  list.each do |v|
    begin
      total += Integer(v)
    rescue ArgumentError
      total += ((break if v == "stop"; 100) rescue 0)
    end
  end
  total
end

# return through two modifiers, and through one inside an ensure
def nested(v)
  n = (((return -1 if v.empty?; Integer(v)) rescue raise(IOError, "inner")) rescue -2)
  n + 1
end

def with_ensure(v, log)
  begin
    n = ((return -1 if v.empty?; Integer(v)) rescue -2)
    n + 1
  ensure
    log << "e"
  end
end

# the modifier rescues what an ensure inside its expression lets through
def ensure_inside(v, log)
  begin
    n = (begin
      Integer(v)
    ensure
      log << "i"
    end rescue -2)
    n + 1
  ensure
    log << "o"
  end
end

LIST = ["1", "", "x", "stop", "5"]

def check(label)
  log = []
  puts "#{label} first_number: #{first_number(["a", "42", "b"])} #{first_number(["a", "b"])}"
  puts "#{label} parse: #{parse("")} #{parse("7")} #{parse("x")}"
  puts "#{label} sum_skipping: #{sum_skipping(LIST)}"
  puts "#{label} sum_until_stop: #{sum_until_stop(LIST)}"
  puts "#{label} each_skipping: #{each_skipping(LIST)}"
  puts "#{label} each_until_stop: #{each_until_stop(LIST)}"
  puts "#{label} stop_in_clause: #{stop_in_clause(LIST)}"
  puts "#{label} nested: #{nested("")} #{nested("7")} #{nested("x")}"
  puts "#{label} with_ensure: #{with_ensure("", log)} #{with_ensure("7", log)} #{with_ensure("x", log)} #{log.join}"
  log.clear
  puts "#{label} ensure_inside: #{ensure_inside("7", log)} #{ensure_inside("x", log)} #{log.join}"
  puts "#{label} $!: #{show($!)}"
end

check("top")
begin
  raise ArgumentError, "outer"
rescue ArgumentError
  check("in a clause")
end

log = []
n = 0
200.times do
  n += first_number(["a", "42", "b"]) + parse("") + sum_skipping(LIST) + sum_until_stop(LIST)
  n += each_skipping(LIST) + each_until_stop(LIST) + stop_in_clause(LIST)
  n += nested("") + with_ensure("", log) + ensure_inside("x", log)
end
puts n
puts log.size
begin
  Integer("later")
rescue ArgumentError => e
  puts "later: #{show(e)} cause #{show(e.cause)}"
end
puts show($!)
