# A file required inside a method is inlined ahead of the statement the
# require sits in, so what it assigns at its top level looks like a write
# the program makes once, before any call. CRuby runs the file when the
# method is called: here that is while `emit` waits for its second
# argument, after `$g` was read, so the append goes to the String `$g`
# held and `$g` holds the file's. Such a program is not lent the
# variable's own slot (byref_arg_read_before_later_arg.rb).
def emit(buf, s) = buf << s

def swap
  require_relative "byref_arg_required_file/swap"
  "x" * 40
end

$g = +"g"
emit($g, swap)
puts $g
