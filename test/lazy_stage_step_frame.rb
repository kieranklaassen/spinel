# A stage of a lazy pipeline runs its block as a block: a `next` answers
# for the element, the block's locals are fresh for every element and a
# `redo` re-runs the body. The pipeline is one C loop, and the block's
# leading statements went straight into it: a `next` was the loop's
# `continue` and dropped the element.

p [1, 5, 2, 8, 3].lazy.map { |x| next 0 if x > 3; x * 2 }.to_a
p [1, 5, 2, 8, 3].lazy.select { |x| next true if x > 3; x.odd? }.first(3)
p [1, 5, 2, 8, 3].lazy.reject { |x| next false if x > 3; x.odd? }.to_a
p %w[a bbbbb cc].lazy.filter_map { |s| next s.upcase if s.size > 3; s.size > 1 && s }.to_a
p [1, 5, 2].lazy.flat_map { |x| next [0] if x > 3; [x, x] }.to_a
p [1, 2, 5, 3].lazy.take_while { |x| next true if x == 2; x < 2 }.to_a
p [1, 2, 5, 3].lazy.drop_while { |x| next true if x == 2; x < 2 }.to_a

# a bare next is nil, and a next at the tail
p [1, 5, 2].lazy.map { |x| next if x > 3; x * 2 }.to_a
p [1, 5, 2].lazy.map { |x| if x > 3 then next 0 else x * 2 end }.to_a

# a next under the block's own ensure
p [1, 2, 3, 4].lazy.select { |x| begin; next if x.odd?; ensure; x; end; x > 2 }.to_a

# in the middle of a chain, and over a Range and a Hash
p [1, 5, 2, 8, 3].lazy.select { |z| z }.map { |x| next 0 if x > 3; x * 2 }.reject { |z| z == 4 }.to_a
p (1..6).lazy.map { |x| next 0 if x > 3; x * 2 }.first(5)
p({ a: 1, b: 5 }.lazy.map { |k, v| next k if v > 3; v * 2 }.to_a)

# the block's locals are fresh for every element
p [1, 2, 3].lazy.map { |x| y ||= x; y }.to_a
p %w[a bb c].lazy.map { |s| t ||= +""; t << s; t }.to_a
p [1, 2, 3].lazy.select { |x| c = (c || 0) + x; c < 3 }.to_a
p [1, 2, 3].lazy.map { |x| y = x if x.odd?; y }.to_a
procs = []
[1, 2, 3].lazy.map { |x| y = x * 2; procs << -> { y }; y }.to_a
p procs.map(&:call)

# redo re-runs the body without binding the parameters again
done = false
p([1, 2].lazy.map { |x| unless done; done = true; x = 9; redo; end; x * 2 }.to_a)
done = false
p([1, 2, 3].lazy.select { |x| unless done; done = true; x = 4; redo; end; x.odd? }.to_a)
done = false
p([1, 2, 3].lazy.drop_while { |x| unless done; done = true; x = 5; redo; end; x < 2 }.to_a)

# a block that holds a break is read as it was (test/lazy_stage_break_beside_next.rb)
p [1, 2, 3].lazy.map { |x| break if x > 100; x * 2 }.to_a
p [1, 2, 3].lazy.drop_while { |x| break 7 if x > 100; x < 2 }.to_a
p [1, 2, 3].lazy.map { |x| (break if x > 100; [x]).each { |q| }; x * 2 }.to_a

# a next leaves the rescue around the pipeline in place
begin
  p [1, 2, 3, 4].lazy.map { |x| next 0 if x > 2; x }.first(3)
  p [1, 2, 3, 4].lazy.select { |x| next true if x > 2; x.odd? }.to_a
  p [1, 2, 3, 4].lazy.drop_while { |x| next true if x < 2; false }.to_a
  p [1, 2, 3, 4].lazy.select { |x| next if x > 2; x.odd? }.to_a
  raise "late"
rescue => e
  puts "rescued #{e.message}"
end

# what these already did stays
p [1, 5, 2, 8, 3].lazy.map { |x| x * 2 }.select { |x| x > 4 }.first(2)
p [1, 2, 3].lazy.drop_while { |x| x < 2 }.to_a
p [1, 2, 3].lazy.map { |x| y = x + 1; y * 2 }.to_a
p [1, 2, 3].lazy.map { |x| a, b = x, x + 1; a * b }.to_a

# and a next that only drops the element, which the loop's `continue` does
p [1, 2, 3, 4].lazy.select { |x| next if x.odd?; x > 2 }.to_a
p [1, 2, 3, 4].lazy.reject { |x| next true if x.odd?; x > 2 }.to_a
p [1, 2, 3, 4].lazy.filter_map { |x| next if x.odd?; x * 2 }.to_a
