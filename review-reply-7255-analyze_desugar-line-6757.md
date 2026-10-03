Checked, and fixed in 8c0fd5dc and 83143a96.

A `define_method` whose name is only known at run time registers no method, on master and on this branch, so its block is never emitted. Seven programs of that shape (the name from a local or a parameter; in a class body, in a class method, in an `each` over a parameter and at top level) behave on this branch as on master.

The finding holds in the analysis, though: the `return` left in such a block was read as the enclosing method's and widened its inferred type (`sp_sym sp_Maker_s_make` became `sp_RbVal`). 8c0fd5dc retypes only where the block is registered as a method's body (`walk_scope`, `collect_dm_each_unroll`, `desugar_define_method_keywords`), and `test/infer/define_method_runtime_name_next.rb` pins the types in `infer-test`. 83143a96 keeps two things that move would have lost: a program that defines a `define_method` of its own is left alone (`test/define_method_user_defined_block_next.rb`), and an `each` that stops naming methods part way leaves the `next` as it is. Neither commit changes the generated C of the corpus as it stood (`make cident`: 5685 identical each time).

The branch is also rebased onto ba6317b6: c517d9ca added `test/collect/refusals.expected`, which needed the new refusal's message, so the first commit is now aa9697da.
