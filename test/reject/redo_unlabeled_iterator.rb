# `redo` re-runs a block's body without binding its parameters again. The
# block of `chunk_while` is walked by an emitter that places no label for
# it, and a redo there would be a `continue`, which leaves the block as
# `next` does: CRuby answers [[1], [2], [4]]. It is refused at this line
# instead (test/redo_block_keeps_writes.rb, test/builtin_iter_step_frame.rb,
# test/builtin_iter_step_frame_more.rb and test/lazy_stage_step_frame.rb
# have the iterators that run it).
done = false
p([1, 2, 4].chunk_while { |a, b| unless done; done = true; a = 9; redo; end; b == a + 1 }.to_a)
