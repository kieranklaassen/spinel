# A global that only ever holds nil is nil at every read, and a call on it
# keeps its value: nil's to_a, to_h, &, | and ^ answered rightly and were
# then dropped for nil, the call having been typed while the global had no
# type. What holds the call's value is typed with it.

$log = nil
p $log.to_a, $log.to_h, $log & true, $log | 1, $log ^ nil

list = $log.to_a
table = $log.to_h
p list, list.size, table, table.empty?

# never assigned at all
p $never.to_a, $never.to_h.empty?, $never | :x

p [$log.to_a, $log.to_h], "#{$log.to_a}|#{$log}|#{$log.to_h.size}"
p $log.to_s, $log.inspect, $log.nil?, $log.to_i

# a call on the answer
more = $log.to_a + [1]
p more, $log.to_a.sort, $log.to_a.join(","), $log.to_h.keys, ($log | 1) & true

def entries = $log.to_a
p entries, entries.size

# a call the program guards, which does not run
class Hook
  def call(x) = x + 1
  def [](i) = i
end

$hook = nil
p($hook ? $hook.call(1) : 0)
p($hook ? $hook[0] : "none")
p $hook&.call(1), ($hook.call(1) if $hook)

$memo ||= nil
p $memo.to_a, $memo.class
