# `redo` re-runs a block's body without binding its parameters again. A
# stage of a lazy pipeline runs one (test/lazy_stage_step_frame.rb), but not
# in a block that also holds a `break`: that block is read without the
# step's frame, where the redo has no label and would be a `continue`,
# leaving the block as `next` does. It is refused at this line instead
# (test/redo_block_keeps_writes.rb, test/builtin_iter_step_frame.rb and
# test/builtin_iter_step_frame_more.rb have the iterators that run it).
done = false
p([1, 2, 3].lazy.map { |x| unless done; done = true; redo; end; break if x == 2; x }.to_a)
