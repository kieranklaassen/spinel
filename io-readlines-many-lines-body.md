<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`f.readlines` on an open File answers lines that hold another line's text once the file is long enough for a collection to fall inside the call:

```ruby
require "tmpdir"
path = File.join(Dir.tmpdir, "lines.txt")
File.open(path, "w") do |f|
  5000.times { |i| f.puts "line number " + i.to_s + " of the file" }
end
lines = File.open(path) { |f| f.readlines }
bad = 0
i = 0
while i < lines.size
  bad += 1 unless lines[i] == "line number " + i.to_s + " of the file\n"
  i += 1
end
p lines.size, bad
```

```
spinel diff: output-diff
  program: readlines.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
 5000
-0
+2352
```

With 20,000 lines it is a SIGSEGV. `sp_File_readlines` makes its Array and then reads a line at a time, each a fresh String, with the Array held by a C local alone, so the first collection frees it. The handle is exposed the same way when the call is its only holder: `File.open(path).readlines` raises "closed stream (IOError)" in the middle of the file. Both are now rooted for the call, as `sp_File_readlines_sep` roots them. The compiler is not touched; a call costs 57 instructions more.

Not here: nothing found beside it. `read`, `gets(nil)`, `readline`, `each_line` with a block, and `readlines` with a separator, a limit or `chomp:` were run on such a handle the same way and are right.

Test: `test/io_readlines_many_lines.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
