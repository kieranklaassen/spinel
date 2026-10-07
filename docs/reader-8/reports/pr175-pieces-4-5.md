# Second reading: fork pull request 175, pieces 4 and 5

Reader 8, 2026-10-07. Two pieces of fork pull request 175, each read as its own piece:

- PIECE 4, "A class's own object_id is the one its instances answer", commit 0c8fbf02a944cf5d5b4d132ae12145f2d1ccbd71
  (`origin/claude/own-object-id-on-06064727`).
- PIECE 5, "A class's own ivar reflection methods are the ones its instances answer", commit ffa53e10ee4c8d3310736e8e20381ed440dba17c
  (`origin/claude/own-ivar-reflection-on-06064727`).

Three masters appear below, and every number says which one it is from:

- **26d456ec** (26d456ec103513fd8d7d9367dbbc9060854f3116): the master of record. Trees of record
  /home/claude/r8/p175b/p4-on-26d456ec-tree (tree 924748a58ee2a4e88ee683f530d55feb5b90dd95) and
  /home/claude/r8/p175b/p5-on-26d456ec-tree (tree 51e1e2d66cad8d4d997d2009215e0d97cbde3590), the two tree ids the coordinator gave.
  Master itself is the coordinator's build, /home/claude/r8/master-26d456ec-tree, read only.
- **8684d54c** (8684d54ce75ffe60dba47b754acd2104e502aaa7): where the reading began (/home/claude/r8/m and two full builds of the pieces).
  What was measured there stays, labelled.
- **5390d300** (5390d3002886d785ea1c74f77380f96e9096ebf0, `upstream/master-5390`): nothing built. `git merge-tree --write-tree
  upstream/master-5390 <commit>` exits 0 for both: piece 4 gives tree 86fe39b3876a7db90e92b18113b93b4ee0be2cd8, piece 5 gives
  2a4481d1e23119e6f9d8d043777afa9666c04b74. Both still merge clean. The one source file of the pieces that master changed between 26d456ec
  and 5390d300 is src/codegen_call_object.c, in `emit_call_safe_nav_arms` only (ae7bbb34), a function neither piece touches. The
  template's first line is the same on all three masters.

Nothing was pushed, posted or opened anywhere; no call was made on the upstream's API. CRuby here is 3.3.6
(`ruby --enable-frozen-string-literal`), not 4.0. Everything is under /home/claude/r8/p175b/ .

A row is one program, one C compiler, one SPINEL_GC_STRESS setting (unset, 1, 2). R right (CRuby's bytes and exit), W silent wrong
(exit 0, other bytes), L loud (a raise or non-zero exit where CRuby has none; "S" a signal, "T" no end in 10 s), X not built or refused.

## VERDICTS

**PIECE 4: NOT READY.** Rule (a) is broken by programs that are right on master in every use: an own `object_id` that falls back to
`super` raises, and with a rescue around it answers wrong silently (finding 4.1). Rule (b) is broken in both halves on a receiver
that is nil at run time (finding 4.2: a build failure becomes a segmentation fault with gcc and a silent wrong answer with clang, and
the twin shows the piece makes it). Three more families that master runs right now raise, never end or stop building (findings 4.3
to 4.5). 88 programs and 264 rows of rule (a) on 26d456ec. The builder's table says "0 lost"; its families hold no `super`, no alias
of the builtin and no nil receiver.

**PIECE 5: NOT READY.** Rule (a) is broken cleanly and widely: an own method that hands the call on (to `super`, to another object, to
an alias of the builtin) is right on master and on the piece raises, is refused, never ends, or (with a rescue around the `super`)
answers wrong silently (findings 5.1 to 5.3). A receiver that is nil at run time is a segmentation fault where master answered
(finding 5.4). One inference site is not covered, so a typed receiver that came out of an Array is refused, or its C does not build
(finding 5.5). 89 programs and 267 rows of rule (a) on 26d456ec.

Both pieces have text findings as well (section "The texts"). Both pass their own tests, the refusal record, reject-test,
share-strings-test and `gate.rb check` on 26d456ec. cident on 26d456ec: outside each piece's own test no corpus program's C changes
(6346 identical; the 4 others differ only in the compiler revision my local merge commit prints; section "Checks").

The shape of the fault is the same in both pieces and it is worth one sentence here: on master the own method was never called, so
nothing ever compiled its body against the call. The natural body of such a method hands the call on (`super`, a wrapped object, the
builtin under an alias), and that is exactly what master cannot compile today (side finds 1 to 4). The piece routes the call to the
method and the program walks into those faults. By the rulings of 10-05 that is ruling (3) (the fault beneath is cured first, as its own
piece) or ruling (5) (carry the program for nothing if a route exists). For `super`, the alias and the nil receiver a route exists and
is the inverted test: where the own method's body holds a `super`, or the class aliases the builtin name, or the receiver may be nil,
keep master's C byte for byte. For a body that hands its parameter on as the name (5.2), a bare `__id__` (4.4) and
`method(:__id__)` (4.5) I see no such cheap test: there the fault beneath is cured first, or the cost is stated first in the body.
None of this was built; it is the reader's inference.

## PIECE 4: findings

The change is two lines: `== SP_MEMBER_ATTR` becomes `!= SP_MEMBER_NONE` in `infer_universal_call` (src/analyze_infer.c 5335 on
26d456ec) and in `emit_call_identity_arms` (src/codegen_call_object.c 216). Every program below was run. The programs under find4/
were run on both masters (gcc and clang, three levels) and their outputs are byte for byte the same on 8684d54c and 26d456ec; the
programs under find4b/ and find4c/ and the families were run on 26d456ec.

### 4.1 (rule (a), clean) An own method that falls back to `super` raises

Smallest program (find4b/g1_super_guard.rb):

```ruby
class Tk
  def initialize(n) = @n = n
  def object_id = @n > 100 ? -1 : super
end
t = Tk.new(4)
u = Tk.new(5)
p t.object_id == u.object_id
p t.object_id.class
```

| | prints |
|---|---|
| CRuby 3.3.6 | `false`, `Integer` |
| master 26d456ec | `false`, `Integer` (gcc and clang, stress unset, 1, 2) |
| piece on 26d456ec | nothing, then `super: no superclass method 'object_id' for an instance of Tk (NoMethodError)`, exit 1 (gcc and clang, all three) |

Master is right here in every use tried, not by accident: the own method's other arm types the call Integer and master emits the
builtin identity. Family `W_superguard` of s4 (26d456ec, gcc, three stress levels): 9 programs of 9 go from right to a raise (same
object `==`, two objects `==`, `.class`, `is_a?(Integer)`, Hash key, `object_id == __id__`, two locals, a statement, both names).

**The same method with a rescue is right on master and silently wrong on the piece** (find4c/g2_super_guard_rescue.rb, 26d456ec):

```ruby
class Tk
  def initialize(n) = @n = n
  def object_id
    @n > 100 ? -1 : super
  rescue NameError
    -2
  end
end
t = Tk.new(4)
u = Tk.new(5)
p t.object_id == u.object_id
p t.object_id.class
```

CRuby `false`, `Integer`; master `false`, `Integer`; piece `true`, `Integer`, exit 0 (gcc and clang, stress unset, 1, 2). The false
NoMethodError is a NameError and the method's own rescue takes it, so every object answers `-2`.

The plain forms raise as well, and for them master is right only through the use (ruling (5)'s kind): `def object_id = super`,
`super()`, `super` as the last line of a body, behind a counter, `super + 0`, `super * 2`, in a subclass whose parent has none, in an
included module, and `def object_id(...) = super(...)`. On master the call's value there is nil (master's C is
`(((sp_int)(uintptr_t)(lv_t)), sp_box_nil())`), so `t.object_id == t.object_id`, a Hash filled by `h[t.object_id] = 1`, two locals and
a bare statement come out right, `t.object_id == u.object_id` comes out `true` (wrong) and `.class` raises. Smallest (find4/f1_super.rb):

```ruby
class Tk
  def object_id = super
end
t = Tk.new
p t.object_id == t.object_id
```

CRuby `true`; master `true`; piece raises NoMethodError (gcc and clang, three levels). With `h = {}; h[t.object_id] = 1; p h.size`
(find4/f1b_super_key.rb): CRuby `1`, master `1`, the piece's C does not build (gcc "void value not ignored as it ought to be", clang
"initializing 'sp_int' with an expression of incompatible type 'void'").

Counts for these plain forms in s4 on 26d456ec (gcc, three levels; 8 kinds): 33 programs right on master raise on the piece (99 rows),
8 more stop building (24 rows); 15 that were wrong on master raise; 16 that raised on master still raise. In fw4, both
`def object_id(...) = super(...)` programs (one per name) are right on master and raise on the piece.

Root: master cannot carry `super` from an own method into Object's builtin (side find 1). On master the method was never called.

### 4.2 (rule (b) both halves, and rule (a) by rows) A receiver that is nil at run time: segmentation fault, or another silent answer

`object_id` is in master's lists of names nil answers (`nil_answers_call`, src/codegen_call.c 18736; `nil_answers_name`,
src/codegen_call_recv.c 6101), so a call of it on a receiver that may be nil gets no nil guard: on master the builtin arm needs none.
The piece sends the call to the class's method with that unguarded receiver: `sp_Tk_object_id((sp_Tk *)lv_t)` with `lv_t` NULL.

Smallest program for rule (b) (find4b/n1_nil_own_string.rb):

```ruby
class Tk
  def initialize(n) = @n = n
  def object_id = "id-#{@n}"
end
t = ARGV.size > 5 ? Tk.new(4) : nil
p t.object_id
```

| | prints |
|---|---|
| CRuby 3.3.6 | `4` (nil's own id) |
| master 26d456ec | C does not build, gcc and clang (the String/Integer mismatch the body describes) |
| piece, gcc | killed by signal 11, stress unset, 1, 2 |
| piece, clang | `"id-4"`, exit 0, stress unset, 1, 2 |

So one program goes from a build failure to a run-time crash with gcc (rule (b), second half) and from a build failure to a silent
wrong answer with clang (rule (b), first half). The two compilers disagree because the C dereferences NULL.

The twin, by script (the same program with the method named `ident`), was run on master for each of the nine ways the family makes the
receiver nil (find4b/n3_nil_twin_other_name.rb with gcc and clang, three levels; twin/nrecv/*.rb with gcc, three levels):

- a local from a conditional, a method call used directly as the receiver, a parameter (two orders of the calls), a local assigned
  nil and then maybe an object: master raises `undefined method 'ident' for nil (NoMethodError)`, as CRuby does. Master guards these
  receivers for any other own method, so on them the crash is MADE by the piece: its route skips the guard because of the name.
- a local bound to a method's result, an ivar, an attr_accessor's value, an Array element past the end: master's twin is itself killed
  by signal 11 (side find 5). On these the crash is reached, not made.

Smallest program for rule (a) (find4/f4_nil_receiver.rb): the same class with `def object_id = @n * 10` and `p t.object_id.class`:
CRuby `Integer`, master `Integer`, piece killed by signal 11 with gcc (three levels) and `Integer` with clang. Master is right there
through the use only (`p t.object_id` prints `0` on master where CRuby prints `4`; on the piece gcc is killed and clang prints `40`;
with `def object_id = 7` and no ivar read the piece prints `7` on both compilers: find4/f4b, f4c).

Family N of s4 on 26d456ec (gcc, three levels; an own method answering an Integer, a String or a constant; nine ways a receiver can be
nil: a local, a method's result two ways, an ivar, an attr_accessor, an Array element past the end, a parameter two ways, a local
assigned twice; uses `p`, `.class`, `nil?`, `==`, a rescue, a condition, a local):

| N family, 26d456ec, gcc | programs | rows |
|---|---|---|
| build failure on master, signal 11 on the piece (X to S), MADE by the piece (first group of receivers) | 17 | 51 |
| build failure on master, signal 11 on the piece (X to S), reached (second group: the twin crashes on master) | 24 | 72 |
| build failure on master, NoMethodError on the piece (X to L; `__id__` on the first group of receivers) | 10 | 30 |
| build failure on master, exit 0 with other bytes (X to W; the same NoMethodError, caught by the program's own rescue) | 5 | 15 |
| right on master, signal 11 on the piece (R to S) | 17 | 51 |
| silent wrong on master (`0`), signal 11 on the piece (W to S) | 28 | 84 |
| wrong on both (W = W; 15 with `def object_id = 7`: master `0`, piece `7`, CRuby `4`; 5 where both print the rescued NoMethodError) | 20 | 60 |
| loud on both (L = L; `__id__`, where master's own guard raises NoMethodError for nil, wrongly) | 16 | 48 |
| right on the piece, master not run (the 54 `&.` programs of Ns, and 5 of N) | 59 | |

The NoMethodError the piece newly raises for `__id__` on nil (10 + 5 programs) is one master raises falsely already (L = L line): by
ruling (4) a newly built statement that raises an error master raises falsely elsewhere is not accepted either.

`&.` is right on the piece in all 54 programs of Ns (the nil test is there).

### 4.3 (rule (a), by ruling (5)) An alias of the builtin made before the own definition: the program never ends

Smallest program (find4/f3_alias_original.rb):

```ruby
class Tk
  alias_method :orig_id, :object_id
  def object_id = orig_id
end
t = Tk.new
p t.object_id == t.object_id
```

CRuby `true`; master `true`; the piece prints nothing and does not end in 10 s (gcc and clang, three levels; run alone as well). The
piece's C: `static inline void sp_Tk_object_id(sp_Tk *self) { sp_Tk_object_id((sp_Tk *)self); }`. Master's fault beneath: the alias
names the later own definition instead of the builtin it named when it was made (side find 2). The same with `alias orig_id object_id`.
s4 on 26d456ec (gcc): 8 programs right on master never end, 2 stop building, 4 wrong on master never end, 4 loud on master never end.
On master the value of the call is nil here too, so master is right through the use (`==` on one object, a Hash key, two locals, a
statement), wrong for two objects.

### 4.4 (rule (a), by ruling (5)) `def object_id = __id__`: NameError

Smallest program (find4/f2_bare_other.rb): `class Tk; def object_id = __id__; end; t = Tk.new; p t.object_id == t.object_id`. CRuby
`true`; master `true`; piece raises `undefined local variable or method '__id__' for an instance of Tk (NameError)` (gcc and clang,
three levels). Master's fault beneath: a bare `__id__` in an instance method raises NameError (side find 3). s4 on 26d456ec: 3 programs
right on master raise, 1 stops building, 2 wrong on master raise. The other direction (`def __id__ = object_id`) and `self.__id__`
are right on the piece.

### 4.5 (ruling (4)) `def object_id = method(:__id__).call`: a build failure becomes a raise master raises falsely

s4 `W_viameth` on 26d456ec: 8 programs whose C does not build on master raise NoMethodError on the piece; 1 right on master (a bare
statement) raises. The twin by script (twin/viameth_twin.rb, the method named `ident`): master raises
`undefined method '__id__' for an instance of Object (NoMethodError)` where CRuby prints `true`. Master's fault, reached; by ruling (4)
the program stays unbuilt or the fault beneath is cured first.

### 4.6 (note) What the piece cures, and how the forwarding forms fare

The first three lines: master's side was run on 8684d54c, the piece's side on both masters. The rest is 26d456ec.

- The body's reproducer: master prints an address, the piece `40`. An own `__id__` answering a String with `puts t.__id__`: master is
  killed by signal 11, the piece prints the String.
- A wrong argument count (`def object_id(x)` called with none): master's C does not build, the piece raises ArgumentError as CRuby does.
- A private own `object_id` called from outside: NoMethodError on both, as in CRuby.
- Forwarding forms asked for on this master (fw4: a top-level method forwarding with `...`, `*args`, `**opts`, `&blk`, anonymous `*`,
  `&`, `**`, through `send`, `public_send`, `__send__`, two hops, a lambda, a holder object, forwarders inside the class, and an own
  `object_id(...)`, `(*)`, `(&b)`, `(**o)`, `(*a, **o, &b)` called eight ways): 955 programs; the piece changes the C of 216 and leaves
  729 byte-identical (10 refused on both). Of the 216, 115 were run on the piece (gcc, three levels): 113 right in every row, 2 raise
  (the `super(...)` pair of 4.1). A sample of 30 of the 113 was run on master: 24 are silently wrong there and 6 do not build.
- `[t].sum(&:object_id)`, an element handed to `each_with_object`, `max_by(&:object_id)`, a Hash's value, and a value that is one of two
  classes still print the address on the piece: all "a boxed receiver" (text finding T6).

## PIECE 5: findings

The change is seven `comp_method_in_chain(...) < 0` conditions in four files (`infer_call_inner` twice, `infer_object_call`,
`emit_call_display_ivar_arms`, `emit_object_ivar_call`, `emit_object_call` twice). Every program below was run. The programs under
find5/ were run on both masters (gcc and clang, three levels) with byte for byte the same outputs; the programs under find5b/ and
find5c/ and the families were run on 26d456ec.

### 5.1 (rule (a), clean; one form is a SILENT wrong answer) An own method that hands the call to `super`

Here master is right in every use, not by accident: the lowering does what `super` would have done. Smallest program
(find5/f1_super_get.rb):

```ruby
class Rec
  def initialize(n) = @n = n
  def instance_variable_get(name) = super
end
p Rec.new(4).instance_variable_get(:@n)
```

| | prints |
|---|---|
| CRuby 3.3.6 | `4` |
| master | `4` (gcc and clang, stress unset, 1, 2) |
| piece | nothing, then `super: no superclass method 'instance_variable_get' for an instance of Rec (NoMethodError)`, exit 1 (gcc and clang, all three) |

The same for the other four names (find5/f1_super_set, _defined, _list, _remove: CRuby and master `5 5`, `true`, `[:@n]`, `4`; the
piece raises), and for the everyday guarded form (find5/f1b_super_guard.rb: `return :hidden if name == :@secret; super`).

Three worse forms of the same program:

- **Right on master, silently wrong on the piece** (find5c/r1_super_rescue.rb; s5 `W_superrescue`, 4 programs, 12 rows, 26d456ec):

  ```ruby
  class Rec
    def initialize(n) = @n = n
    def instance_variable_get(name)
      super
    rescue NameError
      :rescued
    end
  end
  p Rec.new(4).instance_variable_get(:@n)
  ```

  CRuby `4`; master `4`; piece `:rescued`, exit 0. The false NoMethodError is a NameError, and the method's own rescue takes it.
  Run with gcc and clang, three levels. find5c/r2_super_rescue_defined.rb is the same with `instance_variable_defined?` and
  `rescue StandardError; false`: CRuby and master print `has n`, `done`; the piece prints `done` only.
- **Right on master, refused on the piece** (find5b/c1_super_in_condition.rb, 26d456ec):

  ```ruby
  class Rec
    def initialize(n) = @n = n
    def instance_variable_defined?(name) = super
  end
  r = Rec.new(4)
  if r.instance_variable_defined?(:@n) then puts "y" else puts "n" end
  ```

  CRuby `y`; master `y` (gcc and clang, three levels); piece: `unsupported condition (non-bool): ... CallNode
  `instance_variable_defined?``, 1 refusal, nothing written. In g5 on 26d456ec 20 programs go from right to refused this way (60 rows):
  the call in a condition, compared with `>`, as a ternary's test, in a multiple assignment.
- `def instance_variable_get(...) = super(...)` and `(*a) = super(*a)`: the same raise (fw5, 10 programs of 10).

Counts, 26d456ec, gcc, three levels (programs right on master in every row): s5 34 raise (kinds `super`, `super` in a body, with a
counter, guarded, `super` then a change of the value, in a subclass whose parent has none, in an included module, in a prepended
module) and 4 answer wrong silently; fw5 10 raise; g5 5 raise and 20 are refused.

Root: master cannot carry `super` from an own method into Object's builtin (side find 1).

### 5.2 (rule (a)) An own method that hands the call to another object, with its own parameter as the name

Smallest program (g5/0828_A_delegate_def_after.rb, 26d456ec):

```ruby
class Plain
  def initialize(n) = @n = n
end
class Rec
  def initialize(n)
    @n = n
    @inner = Plain.new(n + 100)
  end
  def n = @n
  def instance_variable_defined?(name) = @inner.instance_variable_defined?(name)
end
r = Rec.new(4)
p r.instance_variable_defined?(:@n)
p r.n
```

CRuby `true`, `4`; master `true`, `4`; piece raises `undefined method 'instance_variable_defined?' for an instance of Plain
(NoMethodError)` (gcc, three levels). Master is right through the layouts (both classes have `@n`), so this is ruling (5)'s kind. The
twin by script (twin/delegate_twin.rb, the method named `has?`): master raises the same NoMethodError where CRuby prints `true`, `4`.
Master's fault beneath: a reflection call whose name is not a literal raises NoMethodError on a typed object (side find 4). g5 and fw5
on 26d456ec: 3 programs right on master raise (`A_delegate_def`, `B_delegate_set_othertype`, `S_delegate_rest_none_set`), 3 wrong on
master raise.

### 5.3 (rule (a), by ruling (5)) An alias of the builtin made before the own definition: the program never ends

Smallest program (find5/f2_alias_original.rb):

```ruby
class Rec
  def initialize(n) = @n = n
  alias_method :orig_get, :instance_variable_get
  def instance_variable_get(name) = orig_get(name)
end
p Rec.new(4).instance_variable_get(:@n)
```

CRuby `4`; master `4`; the piece prints nothing and does not end in 10 s (gcc and clang, three levels). Master's fault beneath: the
alias names the later own definition (side find 2). s5 and g5 on 26d456ec: 9 programs right on master never end (27 rows), with
`alias_method` and with `alias`.

### 5.4 (rule (a) by rows; the crash is made by the piece) `instance_variables` on a receiver that is nil at run time

`instance_variables` is in master's lists of names nil answers, so the call has no nil guard, and the piece hands the NULL receiver to
the class's method. Smallest program (find5/f3_nil_receiver.rb):

```ruby
class Rec
  def initialize(n) = @n = n
  def instance_variables = [:own, @n]
end
r = ARGV.size > 5 ? Rec.new(4) : nil
p r.instance_variables.class
```

CRuby `Array`; master `Array`; piece killed by signal 11 (gcc and clang, three levels). With `p r.instance_variables`: CRuby `[]`,
master `[:@n]` (wrong), piece signal 11 (find5/f3b). The twin by script (find5b/n1_nil_twin_other_name.rb, the method named
`listing`): master raises `undefined method 'listing' for nil (NoMethodError)` as CRuby does, gcc and clang, three levels: the crash is
made by the piece. s5 family N on 26d456ec (gcc): 3 programs right on master crash, 3 silently wrong on master crash. Of the six, the
receiver is a local or a parameter in three (made by the piece, as the twin shows) and an attr_accessor's value or an Array element
past the end in three (there master's twin crashes too, as in 4.2: reached).

The other four names keep master's guard in every run: a nil local or parameter raises NoMethodError on master and on the piece
alike (L = L, 16 programs; CRuby answers nil or false there, master's fault). Two programs change class through faults master
already has, and both twins pass by script:

- s5 `N_const_get_meth_p` (`t = mk(false)`, own method reading no ivar): CRuby `nil`, master signal 11, piece `:own`, exit 0: a crash
  becomes a silent wrong answer. Twin (twin/0101_twin.rb, the method named `fetch_own`): master prints `:own`, exit 0, gcc and clang,
  three levels. Reached, not made (side find 5).
- s5 `N_ivar_rm_amiss_var` (`t = a[5]`): master refuses, the piece is killed by signal 11. Twin (twin/1305_twin.rb, the method named
  `zz_remove`): master is killed by signal 11. Reached, not made (side find 5); by ruling (1) it still wants its sentence.

### 5.5 (an inference site the piece does not cover) A typed receiver that came out of an Array: refused, or C that does not build

Smallest program (find5b/e2_element_local_get.rb, 26d456ec):

```ruby
class Tk
  def initialize(n) = @n = n
  def instance_variable_get(name) = "own #{@n}"
end
a = [Tk.new(1)]
t = a.first
x = t.instance_variable_get(:@n)
p x
```

CRuby `"own 1"`; master `1` (wrong, gcc and clang, three levels); piece refuses: `a local variable write given a String, which no
conversion keeps in its sp_int slot`. `t` is a typed `sp_Tk *` in the C, not boxed, so this is not the body's "boxed receiver". With
`t = Tk.new(1)` the same program is right on the piece.

Compile-only matrix on 26d456ec (/home/claude/r8/p175b/site10: 11 ways to get the receiver, 5 names, value written to a local or
printed; 110 programs): master compiles all 110; the piece refuses 9, exactly the receivers `a[0]`, `a.first`, `a.last` with `get`,
`defined?` and `instance_variables` written to a local. 35 of the 110 were then built and run on both (gcc, three
levels): 21 go from silent wrong to right (a receiver from `a[0]` or `a.first` printed directly, a method's result, an optional
result), 1 from unbuilt to right, 3 are the refusals above, 2 are right on both, and 8 stay wrong on both (a Hash's value, and a local
assigned inside a block: boxed).

Where it comes from (read, and consistent with every run; not proved by a patch): `infer_user_method_call` (src/analyze_infer.c 5076 to
5115 on 26d456ec) has arms for `instance_variable_get`, `instance_variable_defined?` and `instance_variables` on a receiver that is
still boxed. A receiver read out of an Array is boxed for a round of the inference before it settles as its class; in that round the
local takes the builtin's type from those arms, and the method's String then has no slot to go to. Those arms have no
`comp_method_in_chain` test and cannot have one while the class is unknown.

Three more programs of the same root:

- find5b/e3_element_local_stmt.rb (the local is never read; `puts "done"`): CRuby `done`, master `done`, piece refused. Right to
  refused, though only because nothing reads the local.
- s5 `N_ivar_list_amiss_var` (`t = a[5]`, `x = t.instance_variables`, `p x.class`): CRuby `Array`, master `Array`, piece refused.
- find5c/m1_map_block_elem.rb: `a = [Pt.new(1), Pt.new(2)]; p a.map { |q| q.instance_variable_get(:@x) }` with an own method answering
  an Array: CRuby `[[:own, 1], [:own, 2]]`, master `[1, 2]` (wrong), and the piece writes C that gcc rejects ("assignment to 'sp_int'
  from 'sp_PolyArray *'") and clang rejects too. Run with gcc and clang, three levels.

Wrong to refused is no break of the two rules. It is a finding because the body says the class's method "is the one its instances
answer" on a typed object, and here a typed object's call is refused with a message about a slot, or the C does not build.

### 5.6 (note) What the piece cures, and how the forwarding forms fare (26d456ec)

- The body's reproducer: master `3`, piece `"get @n of 3"`. A wrong argument count: master refuses ("takes exactly N argument(s)") or
  answers silently; the piece raises ArgumentError as CRuby does. A Struct's own `instance_variable_set` of a member's name: master
  refuses, the piece is right.
- 177 programs that master refuses are built by the piece (g5 134, fw5 42, s5 1). 172 are right in every row (gcc, three levels). 4
  differ from CRuby 3.3.6 only in how a Hash prints (`{k: 7}` for `{:k=>7}`; the newer inspect, so not counted as wrong; not checkable
  against 4.0 here). 1 is the crash of 5.4.
- Forwarding forms asked for on this master (fw5: the forwarders of 4.6 for the five names, a literal name with a forwarded rest or
  keywords, and an own method taking `(...)`, `(*)`, `(*a)`, `(&b)`, `(*a, **o, &b)`): 1577 programs; the piece changes the C of 420,
  leaves 1096 byte-identical, 42 go from refused to built, 19 are refused on both. 160 were run on the piece (149 of the 420, 11 of
  the 42): 147 right in every row, 13 raise (10 are 5.1, 3 are 5.2). All 42 newly built are right. On master a forwarded call (`o.instance_variable_get(...)`,
  `(*a)`) already reaches the own method, except `instance_variable_defined?(...)`, which the piece cures (scratch/w1.rb).
- An own `instance_variable_set` no longer registers a slot or widens a field through `infer_ivar_set_call` in the programs tried
  (scratch/t10a.rb: CRuby and the piece `"ignored @n"`, `4`, `"ignored @zz"`, `[:@n]`, `false`, `nil`; master `"str"`, `"str"`, `1`,
  `[:@n, :@zz]`, `true`, `1`).
- `r.instance_variable_set(:@n, +"ab") << "c"` with an own setter that stores: `"ab"` on master and on the piece where CRuby prints
  `"abc"` (g5 `D_same_set_mstr_0`; wrong on both, side find 7).

## The texts, sentence by sentence

Read: `own-send-175-p4-title.txt`, `-p4-body.md`, `-p4-commit-message.txt` and the three `-p5-` files on `origin/claude/pr-text-handoff`
(copies in /home/claude/r8/p175b/scratch/). Each commit's message equals its handoff text byte for byte. Each has exactly one
`Co-Authored-By: Claude Code <noreply@anthropic.com>` trailer and no other trailer. None of the six texts holds `#` followed by digits, a
model name or a session link; "Depends on: #" is left as the template has it, which says nothing. ee4a10a0, named in piece 4's commit
message, is on master ("A class's own display answers ahead of Kernel#display").

### T1 (both pieces): the body's first line is the template's OLD comment

Both bodies begin `<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->`. The template's first
line on master now (identical on 8684d54c, 26d456ec and 5390d300):

```
<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->
```

### T2 (both pieces): no `spinel diff` report, though the answer differs

What `bin/spinel diff` prints for each body's reproducer on master (run on 8684d54c; the reproducers' answers are the same on 26d456ec):

- piece 4: `-40` / `+2236392650404943047`. The second number is an address and changes from run to run; the body would say so.
- piece 5: `-"get @n of 3"` / `+3`.

### T3 (both pieces): the bodies state no cost and name no program that goes the other way

Each body reads as a plain fix. With findings 4.1 to 4.5 and 5.1 to 5.5 standing, either the pieces carry those programs (then nothing
needs saying) or the cost comes first in the body, with the smallest program. The builder's fold says "0 lost" for both.

### T4 (piece 5 body and commit message): "26 lines; 18 differ on master"

Line by line, 19 of the 26 differ on master (lines 1 to 19; lines 20 to 26, the `Plain` class, agree), on both masters, gcc and clang.
18 is what `diff` counts on each side after it lines the two outputs up (it pairs master's line 19, `2`, with the expected line 4). Say
19, or say how it was counted.

### T5 (piece 5 body and commit message): "and on a Struct the set is refused"

True only when the name is a member's: `s.instance_variable_set(:@a, 2)` on `Struct.new(:a)` with an own `instance_variable_set` is
refused on master (g5 `A_struct_set_*`, refused on 26d456ec, right on the piece). The piece's own test asks for `:@b`, and master answers
that one silently: lines 18 and 19 of the test print `nil` and `2` on master where CRuby prints `[:slot, :@a, 1]` and
`[:slot_set, :@b, 2]`. For the test the sentence stands beside, master is silently wrong, not refusing.

### T6 (both pieces): what is left alone is said in one word, "boxed", and a piece's two texts disagree

- Piece 4's body: "Not in this change: a boxed receiver takes the builtin whatever it holds." Its commit message adds "and a singleton
  method reached by a bare call in one of the class's methods". Piece 5's body: "a boxed receiver takes the builtin"; its commit message
  adds "and a singleton method". The body and the commit message of one piece should name the same things.
- "Boxed" is the compiler's word. What it covers in a program, measured on 26d456ec (CRuby / master / piece):
  - an element handed to a block: `[r].each { |q| p q.instance_variable_get(:@n) }` : `"own @n"` / `4` / `4` (scratch/t14.rb; `q` is
    an `sp_RbVal` in the C); `[t].each_with_object([]) { |x, a| a << x.object_id }` holds the address on both (scratch/x2.rb);
  - a Hash's value: `h = { k: r }; p h[:k].instance_variables` : `[:own, 4]` / `[:@n]` / `[:@n]`;
  - `&:name`: `[r].map(&:instance_variables)` : `[[:own, 4]]` / `[[:@n]]` / `[[:@n]]`; `[t].sum(&:object_id)` an address on both;
  - a value that is one of two classes: `def kid_or_tk(n) = n > 5 ? Kid.new(n) : Tk.new(n)`, both classes with their own
    `object_id`: `700` / an address / an address (scratch/t18.rb).
  That is the everyday way a record reaches a call. One line of example in the body would tell the maintainer how much stays.
- Left alone and named by neither text of its piece (the same on master and piece, wrong on both, C byte-identical):
  - piece 5: `attr_reader :instance_variables` (a generated reader is no method of the chain; prints `[:@n, :@instance_variables]`
    where CRuby prints the reader's value); a class as the receiver with `def self.instance_variable_get` (`nil` where CRuby prints the
    method's answer; `desugar_const_ivar_access` rewrites the call first). Run on 8684d54c only.
  - piece 4: a class that gets the name only through a reopened `Object` or `Kernel` (C byte-identical on both masters, g4 family A;
    compiled only, not run). `define_method` is cured (g4 `A_defm`, right on the piece).
  - both: a receiver typed as the parent where only a child defines the method.
- One thing changes that the texts do not say (piece 5, g5 `H_reopen_late_get_var`, 26d456ec): when the class is reopened to add the
  method AFTER a first call, the first call answers the method too. CRuby prints `4`, `Integer`, `:own`, `Symbol`; the piece prints
  `:own`, `Symbol`, `:own`, `Symbol`; master prints `4`, `Integer`, `4`, `Integer`. Wrong on both, in different halves.

### T7 (piece 4 body): "CRuby warns on stderr against redefining `object_id` and `__id__`"

CRuby 3.3.6, the one the `.expected` came from, warns for `object_id` only: two warnings, for lines 7 and 25 of the test, none for the
`def __id__` lines. Not checkable here: whether CRuby 4.0 warns for both.

### T8 (piece 5, a code comment, not a text): "#4190's rule"

The comment added in `infer_object_call` reads "(#4190's rule for a reader, here for a def)". Master's own comments name #4190 for the
member-read rule (src/analyze_infer.c 4452, 4983, 5332 on 26d456ec), so the reference is in master's style. Inferred only: that the
number is the right one (the upstream's API was not read).

### Checked and found true

- Piece 4: the reproducer prints an address on master; `puts t.__id__` with an own `__id__` answering a String is killed by signal 11 on
  master and prints the String on the piece; "The two conditions go from `== SP_MEMBER_ATTR` to `!= SP_MEMBER_NONE`" is the whole source
  diff; "a class with neither name resolves no member and keeps its C": cident below, and the kinds of g4 without the name are
  byte-identical; "`test/own_object_id.rb` prints 16 lines; on master its C does not build": true on both masters, gcc and clang.
- Piece 5: the reproducer prints 3 on master; each of the five "An own ..." clauses holds on master; the function names are the ones the
  diff touches; "Each is one `comp_method_in_chain(...) < 0` on the arm's condition": seven conditions in four files (the brief said
  nine; the diff has seven: `infer_call_inner` 2, `infer_object_call` 1, `emit_call_display_ivar_arms` 1, `emit_object_ivar_call` 1,
  `emit_object_call` 2); "prints 26 lines": true.
- Both commit messages say the expected files are from CRuby 3.3.6 with `--enable-frozen-string-literal`; CRuby 3.3.6's stdout equals
  both `.expected` files here. The template's box says 4.0; there is no Ruby 4.0 in this container, so the box cannot be ticked from here.

## Counts

Rows are gcc rows at three stress levels unless clang is named. clang was run on the finding programs (find4, find4b, find4c, find5,
find5b, find5c) and on the pieces' own tests, not on the family batches.

### How the families were run (26d456ec)

Each family was first compiled to C by master and by the piece, with no C compiler (every program of every family). A program whose C
is byte-identical cannot change and was not built. Of the programs whose C changes, a list (by hash, each kind kept) was built and run
on the PIECE; every program not right there in every row was then built and run on MASTER; and every program refused on one side only
was run on both. So a rule (a) or rule (b) row cannot hide among the programs run. What the lists leave out is said under "Not run".

| family, 26d456ec | programs | C changed | byte-identical | refused on both | refused on master only | refused on the piece only |
|---|---|---|---|---|---|---|
| piece 4: g4 (definition kinds, uses, receivers, identity operations, argument counts, placement, hierarchies, GC loops) | 2237 | 1106 | 1096 | 35 | 0 | 0 |
| piece 4: s4 (nil receivers, `&.`, wrappers through `super`, an alias, the other name) | 1036 | 729 | 265 | 42 | 0 | 0 |
| piece 4: fw4 (forwarding forms) | 955 | 216 | 729 | 10 | 0 | 0 |
| piece 5: g5 (the same axes for the five names, same-as-builtin typed uses, field after-effects) | 5451 | 3149 | 2111 | 37 | 134 | 20 |
| piece 5: s5 | 1558 | 1148 | 400 | 6 | 1 | 3 |
| piece 5: fw5 | 1577 | 420 | 1096 | 19 | 42 | 0 |

On 8684d54c the same compile gave the same split for g4 (1106 changed) and g5.

### Piece 4 on 26d456ec

| set | run on the piece | right in every row | not right, run on master too | rule (a) programs | rule (a) rows |
|---|---|---|---|---|---|
| s4 | 389 | 128 | 261 | 82 | 246 |
| fw4 | 115 | 113 | 2 | 2 | 6 |
| g4 | 137 | 128 | 9 | 4 | 12 |
| total | 641 | 369 | 272 | 88 | 264 |

The 88 rule (a) programs by finding: 4.1 the guarded `super` 9, the plain `super` forms 33 raise and 8 stop building in s4, 2 in fw4, 3
in g4 (2 raise, 1 stops building); 4.2 nil receiver 17; 4.3 alias 8 never end and 2 stop building in s4, 1 never ends in g4; 4.4 bare
`__id__` 3 raise and 1 stops building; 4.5 `method(:__id__).call` 1.

Transitions of the 272 (programs; a program whose rows differ is counted under each): s4: R to L 46, R to S 17, R to T 8, R to X 11,
W to L 17, W to S 37, W to T 4, W to R 9, W = W 20, L = L 33, L to T 4, X to L 18, X to S 41, X to W 5. fw4: R to L 2. g4: R to L 2,
R to T 1, R to X 1, W to L 2, W to T 1, W to X 1, and `G_strops` (below).

Rule (b) on piece 4, 26d456ec:

- a build failure to signal 11: 41 programs, 123 rows (17 programs made by the piece, 24 reached; finding 4.2);
- a build failure to a raise master raises falsely: 18 programs, 54 rows (10 of 4.2, 8 of 4.5); 5 more programs, 15 rows, where the
  program's own rescue catches that raise and the exit is 0;
- a build failure to a silent wrong answer with clang: find4b/n1_nil_own_string.rb, 3 rows (the batches ran gcc only);
- g4 `G_strops_object_id` (an own `object_id` answering a String, then `.to_sym`): master's C does not build; the piece is right at
  stress unset and 1 and prints `:` and three bytes of freed memory at stress 2 (1 row gcc; clang the same). Twin by script
  (twin/2218_twin.rb, the method named `ident`): master prints the same bytes at stress 2, gcc and clang, and is right at unset and 1.
  Reached, not made (side find 6).

Wrong or unbuilt on master, right on the piece. Master was run on a sample of 30 of the programs right on the piece in fw4 and in
g4: fw4 24 silent wrong to right (72 rows), 6 unbuilt to right (18 rows); g4 19 silent wrong to right (57 rows), 9 unbuilt to right
(27 rows), 2 right on both. In s4 the 128 right on the piece were not run on master; 9 more go from silent wrong to right in two of
three rows (`def object_id = dup.object_id == 0 ? 0 : 1`: CRuby and the piece raise SystemStackError, master prints `true`; at
stress 2 the piece's overflow is a signal 11 instead).

On 8684d54c (the reading's first master; partial): 46 programs of g4 run on both trees, in two batches that share 32 of them. With
gcc, 44 programs, 132 rows: 22 silent wrong to right (66 rows), 16 unbuilt to right (48 rows), 6 right on both. With gcc and clang, 34
programs, 198 rows: 16 silent wrong to right (96 rows), 10 unbuilt to right (60 rows), 6 right on both, 2 unbuilt on both. No rule (a)
or (b) row among them. A piece-only batch (gcc) was stopped at 535 of 771 programs: 500 right, 21 raise, 4 never end, 10 do not build, every
one of the 35 in the `super`, `super()`, other-name and alias kinds. That batch is superseded by the table above; its master side was
never run, and (see "The harness fault") a stopped run cannot tell a lost program from one not reached.

### Piece 5 on 26d456ec

| set | run on the piece | right in every row | not right, run on master too | rule (a) programs | rule (a) rows |
|---|---|---|---|---|---|
| s5 | 144 | 59 | 85 | 49 | 147 |
| fw5 | 160 | 147 | 13 | 11 | 33 |
| g5 | 169 | 156 | 13 | 8 | 24 |
| g5, refused on one side (run on both) | 154 | 130 (+4, see 5.6) | | 20 | 60 |
| fw5, refused on one side | 42 | 42 | | 0 | 0 |
| s5, refused on one side | 4 | 0 | | 1 | 3 |
| total | 673 | 534 | 111 | 89 | 267 |

(11 programs of fw5, 6 of g5 and 1 of s5 are in a refused-on-one-side list and in a run list as well; none of them is a rule (a)
program, so the 89 holds.)

The 89 by finding: 5.1 `super` 34 + 10 + 5 raise, 4 answer wrong silently, 20 refused; 5.2 delegation 3; 5.3 alias 9 never end;
5.4 nil receiver 3; 5.5 the uncovered inference site 1 (`N_ivar_list_amiss_var`, right to refused).

Transitions (programs): s5: R to L 34, R to S 3, R to T 8, R to W 4, W to L 1, W to S 3, W to X 1 (the C does not build), W = W 10,
L = L 16, S = S 4, S to W 1. fw5: R to L 11, W to L 2. g5: R to L 7, R to T 1, W to L 3, W = W 2. Refused on one side: X to R 172
(516 rows), X to W 4 (12 rows; the Hash inspect of 5.6), R to X 21 (63 rows), W to X 1, L to X 1, X to S 1.

Rule (b) on piece 5, 26d456ec: S to W 1 program, 3 rows, and X to S 1 program, 3 rows; both twins pass by script (finding 5.4). The
4 right-to-silently-wrong programs of 5.1 are rule (a).

Wrong or refused on master, right on the piece: 172 of the refused (above). Master was run on a sample of 30 of the programs right
on the piece in fw5 and in g5: fw5 25 silent wrong to right (75 rows), 4 unbuilt to right (12 rows), 1 right on both; g5 17 silent
wrong to right (51 rows), 3 loud to right (9 rows), 10 right on both.

On 8684d54c piece 5 was not run in batches: the finding programs (find5, full matrix, both compilers), the own test and the checks
only. find5's outputs are byte for byte the same on the two masters.

## Checks

| check | piece 4 | piece 5 |
|---|---|---|
| own test on 26d456ec master (gcc and clang) | C does not build (line 34: `const char *` from `long int`) | builds; 19 of 26 lines differ at stress unset, 1, 2 |
| own test on the piece, 26d456ec (gcc and clang, stress unset, 1, 2) | 16 of 16 lines | 26 of 26 lines |
| CRuby 3.3.6 stdout against `.expected` | equal | equal |
| own test on 8684d54c | the same: no build on master, 16 of 16 on the piece | the same: 19 differ on master, 26 of 26 on the piece |
| `make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116` | 6346 identical, 5 differ, 0 refusal changes, 0 refused by both, 0 not in the reference; the 5 are the piece's own test and 4 programs that print the compiler's revision (below) | 6346 identical, 4 differ, 0 refusal changes, 0 refused by both, 1 not in the reference (the piece's own test); the 4 are the same revision programs (below) |
| `make share-strings-test`, 26d456ec | pass | pass |
| `make reject-test`, 26d456ec (before the restart) and 8684d54c | pass | pass |
| `tools/refusals.sh`, 26d456ec (before the restart) and 8684d54c | pass (530 records) | pass (530 records) |
| `ruby tools/gate.rb check`, the commit staged over master, 26d456ec (before the restart) and 8684d54c | exit 0 | exit 0 |
| function sizes, 26d456ec | no function changes length | `infer_object_call` 193 to 196, `emit_call_display_ivar_arms` 50 to 51, `emit_object_call` 798 to 799, `infer_call_inner` unchanged (no line added) |
| compile time, three largest corpus programs, 8684d54c | no difference beyond noise | no difference beyond noise |

`gate.rb check` says "no Ruby 4.0 ... .expected not checked" in this container. The own tests on 26d456ec were run again after the
restart and are logged (tip.owntest.p4.log, tip.owntest.p5.log); reject-test, refusals.sh and gate.rb check on 26d456ec were run before
the restart, passed, and were not run again.

cident, one run per piece, after the restart (tip.cident.p4.log, tip.cident.p5.log; 6351 programs each). Outside each piece's own
test the corpus C is the same as master's for both pieces. The 4 programs that "differ" in both runs are
test/frozen_chilled_builtin_strings.rb, test/object_scoped_ruby_constants.rb, test/ruby_description_shape.rb and
test/symbol_id2name_ruby_desc_minmax.rb: each differs in 2 lines, the text of RUBY_DESCRIPTION, "(unreleased revision 26d456ec)"
against "(unreleased revision 981587be)" (piece 4) or "(unreleased revision ad97ecd0)" (piece 5). Those two ids are my local merge
commits of the piece onto 26d456ec; with the revision masked the four files are byte-identical (checked for piece 4 with a second
emission and `diff`; for piece 5 read in the log's diff). The script's mask covers a dated revision string and not the "unreleased"
form, so `make cident` exits non-zero on any tree whose HEAD is not the reference commit; that is the script and the merge commit,
not the pieces. Piece 4's fifth "differs" is test/own_object_id.rb, its own test, whose C must differ (master's does not build).
Piece 5's run did not build its own reference: piece 4's finished reference cache (made by the script from 26d456ec, 6350 master
programs after piece 4's own test is taken out) was copied under piece 5's cache key with the tree's name rewritten in the C; the two
trees' corpora differ only by the two own tests. So piece 5's own test is "not in the reference"; master compiles it (row 1 of the
table), so it would be a "differs", not a refusal change.

How the trees of record were built: the coordinator's finished build of 26d456ec was copied into each merged tree, the piece's changed
C files were touched and `make` recompiled exactly those and main.c (piece 4: analyze_infer.c, codegen_call_object.c; piece 5: those
two, analyze_infer_recv.c and codegen_call_recv.c). The unchanged objects are therefore master's own. cident's reference compiler is
built from scratch by the script, so its "identical" count also checks the derived build against a clean one.

### The harness fault the coordinator reported, and the restart

- The fault (a C compiler error text with a non-ASCII byte kills the worker thread and the program gets no record) was in my copy. It
  needs Ruby to start in a non-UTF-8 locale; every run on 26d456ec was started with LANG=C.UTF-8, and those files hold 79 build-failure
  records, 67 of them with gcc's curly quotes. Checked after the fix (`Encoding.default_external` set, both streams scrubbed): each of
  the 15 result files of 26d456ec has exactly as many records as its list (389, 261, 115, 2, 137, 9, 144, 85, 160, 13, 169, 13, 154,
  42, 4); no log holds "terminated with exception"; the compile-only tables have one line per program of each directory (2237, 5451,
  1036, 1558, 955, 1577). No program was lost on 26d456ec. On 8684d54c the stopped batch of 535 cannot be checked this way (above).
- The container restarted at about 06:02 UTC. Lost: the master stage of s4 at 185 of 261 records (resumed; 261, every line parses) and
  the queue behind it, which was started again. The own tests were run again. Nothing else was running.
- A safety check refused one command of mine after the restart, a removal of leftover build files under s4/_build written as a relative
  glob after a `cd`. It was not retried and not routed elsewhere; the leftover files are still there.
- One orphan: stopping a harness by pid left a never-ending test program (finding 4.3's kind) running for about 90 s; it was killed by
  pid.

## What was NOT run

- `make gate`, `make test`, optcarrot (not present), anything with Ruby 4.0, valgrind or a sanitizer.
- Nothing was built on 5390d300.
- clang on the family batches (gcc only there).
- The programs whose C changes and that are not on a run list: piece 4: g4 969 of 1106, s4 340 of 729, fw4 101 of 216; piece 5: g5 2986
  of 3149, s5 1005 of 1148, fw5 271 of 420. The lists keep every kind, but they are samples.
- Master on the programs that are right on the piece, beyond a sample (so "wrong to right" is not a total).
- The programs whose C is byte-identical were not built or run on 26d456ec (they cannot change): how wrong the shapes left alone are
  was measured by hand probes only (T6).
- The compile-only matrix of 5.5 made for piece 4 (site10b, 110 programs) compiles everywhere on the piece, but only 10 of the 110
  were built and run (gcc): 3 silent wrong to right, 3 unbuilt to right, 2 wrong on both and 2 unbuilt on both (a Hash's value and a
  local assigned inside a block: boxed).
- reject-test, refusals.sh and gate.rb check were not repeated after the restart.
- The twins run are the ones named in the findings (nine receiver twins for 4.2, and one each for 4.5, 5.2, 5.4 twice, `G_strops`,
  and the `(*a)` delegate); no twin was run for a W = W or L = L program.

## Side finds on master, for the miner (26d456ec unless a master is named; each was run)

1. `super` from an own method into one of Object's builtins. `object_id`, `__id__`, `instance_variable_get`, `_set`, `_defined?`,
   `instance_variables`, `remove_instance_variable`: "super: no superclass method" at run time (visible on master only once the method
   is called, so through these pieces; with `def object_id = super` master's `t.object_id == u.object_id` is `true` and
   `t.object_id.class` raises "undefined method 'class' for unknown"). On 8684d54c also: `display`, `hash` raise the same;
   `respond_to?`, `frozen?`, `nil?`, `is_a?`, `dup` do not build.
2. `alias_method :orig_id, :object_id` (or `alias`) ahead of an own `def object_id`: the alias names the later own definition, not the
   builtin (scratch/t11.rb, t13.rb). The same for the ivar names.
3. A bare `__id__` in an instance method raises NameError (scratch/t19.rb). With a subclass that defines `__id__`, the parent's
   `__id__.class` prints `NilClass` (t20.rb), and `self.__id__.class` there does not build (t21.rb).
4. A reflection call whose name is not a literal raises NoMethodError on a typed object: `@inner.instance_variable_defined?(name)`
   (twin/delegate_twin.rb), `@i.instance_variable_get(*a)` (twin/0310_twin.rb). CRuby answers.
5. Nil receivers of an ordinary own method. A local bound to a method's result (`t = mk(false)`), an ivar, an attr_accessor's value, an
   Array element past the end: killed by signal 11 (twin/nrecv/meth.rb, ivar.rb, attr.rb, amiss.rb, twin/1305_twin.rb), or, when the
   method reads no ivar, the method runs and answers (twin/0101_twin.rb prints `:own`). CRuby raises NoMethodError. A local from a
   conditional, a parameter, a call used directly are guarded and right.
   Nil with the builtins: `t.object_id` and `t.__id__` print `0` (CRuby `4`; find4b/n4_nil_no_own.rb); `r.instance_variables` prints
   the class's slots (CRuby `[]`; find5b/n2_nil_no_own.rb); `instance_variable_get`, `_defined?`, `_set`, `remove_instance_variable`
   and, where the class has its own Integer `__id__`, `__id__` raise NoMethodError (CRuby answers nil, false, the value, FrozenError, 4).
6. `n = ARGV.size + 1; p "id#{n}".to_sym` at SPINEL_GC_STRESS=2 prints `:` and three bytes 0xDB (twin/to_sym_smaller.rb); right at
   unset and 1.
7. `r.instance_variable_set(:@n, +"ab") << "c"` (and on 8684d54c `r.instance_variable_get(:@s) << "c"`) leaves `"ab"` where CRuby has
   `"abc"`.
8. `method(:__id__).call` raises `undefined method '__id__' for an instance of Object (NoMethodError)` (twin/viameth_twin.rb).
9. `o.object_id(*a)` with an empty `a` calls the class's own method on master while `o.object_id` does not (scratch/w1.rb).
10. A value that is one of two classes, one of them with its own `__id__` answering a String, `p z.__id__.class`: master's C does not build ("incompatible type for argument 1 of
    'sp_poly_class_val'"; scratch/t16.rb line 27).
11. A tool, not the compiler: tools/cident.sh masks a dated revision string (`NNNN.NN.NN+N revision X`) and not the form a tree
    without a release date prints, "(unreleased revision XXXXXXXX)". On any tree whose HEAD is not the reference commit the four
    corpus programs that print RUBY_DESCRIPTION are reported "DIFFERS" and `make cident` exits non-zero (section "Checks").

## What was verified by running, and what is only inferred

Verified by running: every output quoted in a finding (CRuby, master, piece; the compilers and stress levels named beside it); every
count in "Counts"; every twin; the checks in the table; the merge-tree lines for 5390d300; the text findings T1, T2, T4, T5, T7 and the
"checked and found true" list.

Inferred, not run: that the refusal of 5.5 comes from the boxed-receiver arms of `infer_user_method_call` (read in the source,
consistent with which receivers are refused; no patch was tried); that a repair by the inverted test (keep master's C where the own
method's body holds a `super`, where the class aliases the builtin name, and where the receiver may be nil) carries the rule (a)
programs (not built); that `{k: 7}` is what CRuby 4.0 prints for the four programs of 5.6; that "#4190" is the right number (T8); that
the pieces behave on 5390d300 as on 26d456ec (they merge clean; nothing was built).
