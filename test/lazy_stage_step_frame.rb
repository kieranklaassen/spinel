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

# in the middle of a chain, and over a Range and a Hash
p [1, 5, 2, 8, 3].lazy.select { |z| z }.map { |x| next 0 if x > 3; x * 2 }.reject { |z| z == 4 }.to_a
p (1..6).lazy.map { |x| next 0 if x > 3; x * 2 }.first(5)
p({ a: 1, b: 5 }.lazy.map { |k, v| next k if v > 3; v * 2 }.to_a)

# the block's locals are fresh for every element
p [1, 2, 3].lazy.map { |x| y ||= x; y }.to_a
p %w[a bb c].lazy.map { |s| t ||= +""; t << s; t }.to_a
p [1, 2, 3].lazy.select { |x| c = (c || 0) + x; c < 3 }.to_a

# redo re-runs the body without binding the parameters again
done = false
p([1, 2].lazy.map { |x| unless done; done = true; x = 9; redo; end; x * 2 }.to_a)

# what these already did stays
p [1, 5, 2, 8, 3].lazy.map { |x| x * 2 }.select { |x| x > 4 }.first(2)
p [1, 2, 3].lazy.drop_while { |x| x < 2 }.to_a
p [1, 2, 3].lazy.map { |x| y = x + 1; y * 2 }.to_a
