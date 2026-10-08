# NZ (`when nil` takes a Boolean false): what the probes on master 5d762fb16716 say (01:50 UTC 10-08)

- The fault: `case b when nil` with b typed Boolean is emitted `(_t == 0)` (emit_case's last arm, emit_case_obj_eq,
  src/codegen_stmt.c): every false takes the nil arm (n1.rb, n3.rb lines 22 to 29; `nil === b` is right).
- NOT curable by "a Boolean is never nil": master keeps nil as the Boolean's zero in a Boolean-typed slot, and there
  `when nil` is right by accident (rule (a)): a local a read can reach before any write (if, loop, begin/rescue:
  n5.rb q, rv; p8_30), `aw &&= v` on a fresh local (p8_24), a masgn shortfall `a, b = [3 > 5]` (p8_01, p8_03),
  a block-local read before its write (p8_13), a proc's missing argument (p8_09), a method that returns such a
  local (n5.rb maybe(1)). In each `p q` prints false and `q.nil?` is false on master: the hidden fault.
- No inverted test today: du_read_maybe_unset is asked for Integer and Float locals (maybe_unset) and by the nil
  fact for pointer kinds; no fact says a Boolean slot may hold the zero that stands for nil, and the masgn, proc
  and block-local sources are not unset reads.
- The hidden root is wider than Boolean (n7.rb): an unset local of a kind with no nil prints its zero:
  Range 0..0, Float Range 0.0..0.0, Rational (0/0), Complex (0+0i), Time 1970-01-01, Regexp //, Boolean false;
  `.nil?` false for each. Integer, Float, String, Symbol, Array, Hash, object, Proc, Bignum, Class are nil.
- A narrow form (subject is a builtin's Boolean answer or a literal: `case xs.empty? when nil`) has no loss and
  no realistic witness. The realistic witness is a parameter (`def label(done); case done; when nil ...`).
- The root's cure would be a typing change: a Boolean local a read can reach before any write is nil-or-Boolean
  (boxed), as `x = nil` ahead of it makes it today (ty_unify(NIL, BOOL) is POLY). A cost for programs that only
  test its truth.
