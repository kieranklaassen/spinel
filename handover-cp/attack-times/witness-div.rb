row = ["ab", [1, 2], 2.5]
begin
  p row[0] / 2
rescue => e
  puts "#{e.class}: #{e.message}"
end
begin
  p row[0] % 2
rescue => e
  puts "#{e.class}: #{e.message}"
end
