# `@t = @s.replace(x)` in the script body, after the appends before it: the
# call is the last mutation the program runs, so nothing changes either
# name once the write has made its copy and the two read the same: it
# builds.
@s = +"ab"
@s << "c"
p @s
@t = @s.replace("xy")
p @s, @t
