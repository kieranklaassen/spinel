row = ["ab", [1, 2]]
n = [2.5, :k][0]
begin
  p row[0] * n
rescue => e
  puts "#{e.class}: #{e.message}"
end
begin
  p row[1] * n
rescue => e
  puts "#{e.class}: #{e.message}"
end
width = { cols: 7, fill: "-" }
begin
  puts width[:fill] * (width[:cols] / 2.0)
rescue => e
  puts "#{e.class}: #{e.message}"
end
