# spinel: not-cruby -- ffi_func is Spinel's own; the answers are libc's.
# A String held as an sp_String * handle is handed to a :str argument as a
# copy when another argument of the call runs code. That copy, like a
# String a call just answered, is held by nothing but the C call's argument
# list, so the argument beside it must not collect it while it is made:
# two handles, a handle beside a call that builds a String, a handle beside
# an Integer argument that allocates on its way, and the same among the
# arguments of a variadic function.
module LibC
  ffi_func :strncmp, [:str, :str, :int], :int
  ffi_func :printf, [:str, :varargs], :int
end

def joined(a, b) = a + b
def width(v) = [v, v, v].size + 2

s = +"12"
t = s
t << "345"
x = "12"

p LibC.strncmp(s, t, s.size + 0)
p LibC.strncmp(s, joined(x, "345"), 5)
p LibC.strncmp(joined(x, "345"), s, 5)
p LibC.strncmp(joined(x, "345"), joined(x, "346"), 5)
p LibC.strncmp(s, "12345", width(1))
p LibC.strncmp("12345", s, width(1))
LibC.printf("%s %s\n", s, joined(x, "345"))
LibC.printf("%s %s\n", joined(x, "345"), s)
