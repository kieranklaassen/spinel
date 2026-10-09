# An instance variable assigned from another through a call that answers
# its receiver holds a copy. The script body only prints @s, and only ahead
# of the assignment, so nothing reads the change through it: the copy
# cannot be told from the String, and the program compiles.
@s = +" ab "
p @s
puts @s
@t = @s.to_s
@t << "!"
p @t

@c = +"cd"
print @c, "\n"
@u = @c.itself
@u.upcase!
p @u
