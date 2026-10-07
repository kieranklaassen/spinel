# A local written once with an Array of new Strings and read once: the read
# runs three times, and a `bytesplice` raises for what its last run left.
a = [+"qr", +"t"]
begin
  3.times { a.slice(0).bytesplice(-1, 1, "") }
  puts "no raise"
rescue IndexError
  puts "IndexError"
end
