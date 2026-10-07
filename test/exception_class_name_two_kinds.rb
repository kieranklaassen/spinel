# e.class.name in a rescue that meets more than one error class. The name of
# an exception's class is a fresh heap copy on each read; Module#name's cache
# was keyed by its address, which the collector hands to the next copy, of
# another class's name.
class AppError < StandardError; end
class AppErrorMore < StandardError; end

def fail_with(i)
  k = i % 4
  raise ArgumentError, "bad #{i}" if k == 0
  raise KeyError, "missing #{i}" if k == 1
  raise AppError, "app #{i}" if k == 2
  raise AppErrorMore, "more #{i}"
end

want = ["ArgumentError", "KeyError", "AppError", "AppErrorMore"]
lines = []
tally = Hash.new(0)
wrong_name = 0
wrong_line = 0
not_same = 0
not_frozen = 0
4000.times do |i|
  begin
    fail_with(i)
  rescue => e
    name = e.class.name
    wrong_name += 1 unless name == want[i % 4]
    line = "#{e.class.name}: #{e.message}"
    wrong_line += 1 unless line.start_with?(want[i % 4] + ": ")
    not_same += 1 unless e.class.name.equal?(e.class.name)
    not_frozen += 1 unless e.class.name.frozen?
    tally[e.class.name] += 1
    lines << line if i < 4 || i >= 3996
  end
end
puts lines
p wrong_name, wrong_line, not_same, not_frozen
p tally["ArgumentError"], tally["KeyError"], tally["AppError"], tally["AppErrorMore"], tally.size

# the name of a class the program names is the same frozen String
begin
  raise AppError, "x"
rescue => e
  p e.class.name.equal?(AppError.name), e.class.name == e.class.to_s
end
begin
  Integer("zz")
rescue => e
  p e.class.name, e.class.name.equal?(ArgumentError.name)
end
p AppError.name, AppErrorMore.name.equal?(AppErrorMore.name), AppError.name.frozen?
