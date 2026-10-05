# A block that assigns its parameter and then appends to it: the parameter
# is a plain value there, so the append would grow a copy of the caller's
# String. Refused rather than compiled with the append lost (#6179).
def run(s) = yield(s)
s = +"a"
run(s) { |k| k ||= +"z"; k << "x" }
p s
