# encoding: utf-8
# prints section 5's tables from the tallies
def tally(b, p, files) = `ruby mytally.rb #{b} #{p} #{files.join(' ')}`.lines.reject { |l| l.start_with?("P:") }.join
def block(title, b, p, files)
  "**#{title}**\n\n```\n#{tally(b, p, files)}```\n"
end
n = ->(f) { File.exist?(f) ? File.readlines(f).size : 0 }
puts "Programs run: `ga` #{n.('ga.jsonl')} (piece 2: routes to an own send by receivers, name computations, arities,"
puts "callee shapes, forwarding, own sends that call super or `__send__`, rescued twins), `gc` #{n.('gc.jsonl')} (corpus tests"
puts "that use send, with a class owning `send(msg, flags)` appended), `gb` #{n.('gb.jsonl')} (piece 3: ways of boxing by what the"
puts "box holds by call forms, own-send shapes, argument and receiver expressions with ticks, blocks and rescue,"
puts "result types, forwarding and recursion, rescued twins), `gbh` #{n.('gbh.jsonl')} (the split call in value positions and"
puts "under iterators; gcc only).\n\n"
puts "### Piece 2\n\n"
puts block("ga, p1 -> p2", "p1", "p2", %w[ga.jsonl])
puts block("ga, master -> p2", "m", "p2", %w[ga.jsonl])
puts "**gc, p1 -> p2** (right and wrong read against the corpus test's own `.expected` plus the appended line)\n\n```\n#{`ruby gctally.rb p1 p2`}```\n"
puts "**gc, master -> p2**\n\n```\n#{`ruby gctally.rb m p2`}```\n"
puts "### Piece 3\n\n"
puts block("gb, p2 -> p3", "p2", "p3", %w[gb.jsonl])
puts block("gb, master -> p3", "m", "p3", %w[gb.jsonl])
puts block("gbh, p2 -> p3 (gcc only: 3 rows a program)", "p2", "p3", %w[gbh.jsonl]) if n.('gbh.jsonl') > 0
puts block("gbh, master -> p3", "m", "p3", %w[gbh.jsonl]) if n.('gbh.jsonl') > 0
