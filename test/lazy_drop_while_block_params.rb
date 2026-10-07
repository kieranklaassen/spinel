# drop_while in a lazy pipeline binds its block's parameters as the other
# stages do: a second parameter, a default, a rest, a post. It bound the
# first alone, to the whole element.

p [[1, 2], [3, 9], [5, 1]].lazy.drop_while { |x, y| y < 4 }.to_a
p [[1, 2], [3, 9], [5, 1]].lazy.drop_while { |x, y| x < 3 }.to_a
p [1, [3, 4], 5].lazy.drop_while { |x, y = 9| y == 9 }.to_a
p [[1, 2], [3]].lazy.drop_while { |*r| r.first.size > 1 }.to_a
p [[1, 2], [3, 4]].lazy.drop_while { |x, *r| r == [2] }.to_a
p [[1, 2, 3], [4, 5, 6]].lazy.drop_while { |*r, z| z == 3 }.to_a
p [[1, [2, 3]], [4, [5, 6]]].lazy.drop_while { |x, (y, z)| z < 5 }.to_a
p({ a: 1, b: 5 }.lazy.drop_while { |k, v| v < 3 }.to_a)
p [4, 7, 1].each_with_index.lazy.drop_while { |x, i| i < 1 }.to_a
p (1..6).each_slice(2).lazy.drop_while { |a, b| b < 3 }.first(1)
p [[1, 2], [3, 9]].lazy.map { |x, y| [y, x] }.drop_while { |x, y| y < 2 }.to_a

# what it already did stays
p [1, 2, 3].lazy.drop_while { |x| x < 2 }.to_a
p [1, 2, 3].lazy.drop_while { _1 < 3 }.map { |x| x * 2 }.to_a
p [[1, 2], [3, 4]].lazy.drop_while { |x| x.first < 3 }.to_a
