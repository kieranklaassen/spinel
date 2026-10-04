# A String a call takes out of an Array is a copy unless the sharing
# analysis follows the read. Appended to in a statement whose value is
# dropped, the copy is all that changes: refused, not lost.
a = [+"q", +"r"]
a.find { |s| s == "q" } << "!"
p a
