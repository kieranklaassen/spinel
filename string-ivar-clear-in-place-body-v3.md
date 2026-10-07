<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Buffer
  def initialize(out)
    @out = out
  end

  def line(text)
    @out.clear
    @out << text
  end
end
shown = +"loading"
b = Buffer.new(shown)
b.line("ready")
puts shown
```

master prints `loadingready`, with gcc, with clang and with `--share-strings`; CRuby prints `ready`. `spinel diff` on master:

```
spinel diff: output-diff
  program: clear.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-ready
+loadingready
```

With this commit `spinel diff` says `same`.

A String that an instance variable and its caller both hold lives in a handle. A statement that changes such a String by position goes through a shim (`str_mutate_shared_arms`): the String is read out to a shadow, the value arm runs against the shadow, and the shadow is written back. `clear` has no value arm for a handle: its arm empties the handle in place (`str_mutate_reassign_arms`). Under the shim it still did that, and the shadow, read out before, was then written back over the emptied String. Nothing was cleared, in a method, a block, a loop or a `rescue` body, for an instance's variable, a class method's or a top-level one.

The shim now leaves `clear` to that arm. It emits one `sp_String_set_bin` on the handle, which raises for a frozen String as the shim did. The call in expression position (`@out.clear.size`, or as a method's last line) took that arm already and was right.

No cost: where the String was empty already, and master right, a call goes from 453 instructions to 49 (callgrind, gcc; 428 to 87 with clang), the copy to the shadow being gone. No program of the corpus changes (`tools/cident.sh`: 6470 identical; the one file that differs is the new test); optcarrot's generated C is byte-identical.

Not here: `@out.clear << "x"` still appends to a copy, on master and here.

Test: `test/string_ivar_clear_in_place.rb`; on master 15 of its 18 lines differ. Also run: 464 generated programs (`clear` and four other mutators by position; who else holds the String; where the call stands; what follows it; an instance's variable, a class method's and a top-level one) with gcc, with clang and with `--share-strings`, `SPINEL_GC_STRESS` unset, 1 and 2. Right in all nine: 160 on master, 400 here. None right on master is wrong here, and none that failed loudly on master is silently wrong here. The 64 still wrong have an Array element as the other holder: wrong on master and here for all five mutators without `--share-strings`, right with it. A global as the other holder (`$g = +"loading"`, `Buffer.new($g)`) is the same case: `$g` and `@out` are two Strings in a plain run, on master and here, and with `--share-strings` master prints `loadingready` and this commit `ready`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
