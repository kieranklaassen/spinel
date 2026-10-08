# A stage of a lazy pipeline runs a `redo` (test/lazy_stage_step_frame.rb),
# but not beside a keyword the block never reads: that parameter has no
# local for the step to bind, and the block does not build, with the redo
# or without it. The redo is refused at this line instead, as it was
# (test/reject/redo_unlabeled_iterator.rb).
done = false
p([1, 2, 3].lazy.map { |x, k: 1| unless done; done = true; redo; end; x * 2 }.to_a)
