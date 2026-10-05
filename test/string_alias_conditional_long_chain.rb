# A String a conditional hands over is its arm's own String in a chain of
# any length. Each arm of the write stands in a pair of braces in the C, and
# clang stops at 256 nested brackets, so a chain of 256 arms or more did not
# build with it. Arm 100's condition has setup of its own, which keeps its
# braces; k = 1000 takes it.
def pick(k, a, b, c, d)
  t = if k == 0 then a
      elsif k == 1 then b elsif k == 2 then c elsif k == 3 then d elsif k == 4 then a
      elsif k == 5 then b elsif k == 6 then c elsif k == 7 then d elsif k == 8 then a
      elsif k == 9 then b elsif k == 10 then c elsif k == 11 then d elsif k == 12 then a
      elsif k == 13 then b elsif k == 14 then c elsif k == 15 then d elsif k == 16 then a
      elsif k == 17 then b elsif k == 18 then c elsif k == 19 then d elsif k == 20 then a
      elsif k == 21 then b elsif k == 22 then c elsif k == 23 then d elsif k == 24 then a
      elsif k == 25 then b elsif k == 26 then c elsif k == 27 then d elsif k == 28 then a
      elsif k == 29 then b elsif k == 30 then c elsif k == 31 then d elsif k == 32 then a
      elsif k == 33 then b elsif k == 34 then c elsif k == 35 then d elsif k == 36 then a
      elsif k == 37 then b elsif k == 38 then c elsif k == 39 then d elsif k == 40 then a
      elsif k == 41 then b elsif k == 42 then c elsif k == 43 then d elsif k == 44 then a
      elsif k == 45 then b elsif k == 46 then c elsif k == 47 then d elsif k == 48 then a
      elsif k == 49 then b elsif k == 50 then c elsif k == 51 then d elsif k == 52 then a
      elsif k == 53 then b elsif k == 54 then c elsif k == 55 then d elsif k == 56 then a
      elsif k == 57 then b elsif k == 58 then c elsif k == 59 then d elsif k == 60 then a
      elsif k == 61 then b elsif k == 62 then c elsif k == 63 then d elsif k == 64 then a
      elsif k == 65 then b elsif k == 66 then c elsif k == 67 then d elsif k == 68 then a
      elsif k == 69 then b elsif k == 70 then c elsif k == 71 then d elsif k == 72 then a
      elsif k == 73 then b elsif k == 74 then c elsif k == 75 then d elsif k == 76 then a
      elsif k == 77 then b elsif k == 78 then c elsif k == 79 then d elsif k == 80 then a
      elsif k == 81 then b elsif k == 82 then c elsif k == 83 then d elsif k == 84 then a
      elsif k == 85 then b elsif k == 86 then c elsif k == 87 then d elsif k == 88 then a
      elsif k == 89 then b elsif k == 90 then c elsif k == 91 then d elsif k == 92 then a
      elsif k == 93 then b elsif k == 94 then c elsif k == 95 then d elsif k == 96 then a
      elsif k == 97 then b elsif k == 98 then c elsif k == 99 then d elsif [k, 1].include?(1000) then a
      elsif k == 101 then b elsif k == 102 then c elsif k == 103 then d elsif k == 104 then a
      elsif k == 105 then b elsif k == 106 then c elsif k == 107 then d elsif k == 108 then a
      elsif k == 109 then b elsif k == 110 then c elsif k == 111 then d elsif k == 112 then a
      elsif k == 113 then b elsif k == 114 then c elsif k == 115 then d elsif k == 116 then a
      elsif k == 117 then b elsif k == 118 then c elsif k == 119 then d elsif k == 120 then a
      elsif k == 121 then b elsif k == 122 then c elsif k == 123 then d elsif k == 124 then a
      elsif k == 125 then b elsif k == 126 then c elsif k == 127 then d elsif k == 128 then a
      elsif k == 129 then b elsif k == 130 then c elsif k == 131 then d elsif k == 132 then a
      elsif k == 133 then b elsif k == 134 then c elsif k == 135 then d elsif k == 136 then a
      elsif k == 137 then b elsif k == 138 then c elsif k == 139 then d elsif k == 140 then a
      elsif k == 141 then b elsif k == 142 then c elsif k == 143 then d elsif k == 144 then a
      elsif k == 145 then b elsif k == 146 then c elsif k == 147 then d elsif k == 148 then a
      elsif k == 149 then b elsif k == 150 then c elsif k == 151 then d elsif k == 152 then a
      elsif k == 153 then b elsif k == 154 then c elsif k == 155 then d elsif k == 156 then a
      elsif k == 157 then b elsif k == 158 then c elsif k == 159 then d elsif k == 160 then a
      elsif k == 161 then b elsif k == 162 then c elsif k == 163 then d elsif k == 164 then a
      elsif k == 165 then b elsif k == 166 then c elsif k == 167 then d elsif k == 168 then a
      elsif k == 169 then b elsif k == 170 then c elsif k == 171 then d elsif k == 172 then a
      elsif k == 173 then b elsif k == 174 then c elsif k == 175 then d elsif k == 176 then a
      elsif k == 177 then b elsif k == 178 then c elsif k == 179 then d elsif k == 180 then a
      elsif k == 181 then b elsif k == 182 then c elsif k == 183 then d elsif k == 184 then a
      elsif k == 185 then b elsif k == 186 then c elsif k == 187 then d elsif k == 188 then a
      elsif k == 189 then b elsif k == 190 then c elsif k == 191 then d elsif k == 192 then a
      elsif k == 193 then b elsif k == 194 then c elsif k == 195 then d elsif k == 196 then a
      elsif k == 197 then b elsif k == 198 then c elsif k == 199 then d elsif k == 200 then a
      elsif k == 201 then b elsif k == 202 then c elsif k == 203 then d elsif k == 204 then a
      elsif k == 205 then b elsif k == 206 then c elsif k == 207 then d elsif k == 208 then a
      elsif k == 209 then b elsif k == 210 then c elsif k == 211 then d elsif k == 212 then a
      elsif k == 213 then b elsif k == 214 then c elsif k == 215 then d elsif k == 216 then a
      elsif k == 217 then b elsif k == 218 then c elsif k == 219 then d elsif k == 220 then a
      elsif k == 221 then b elsif k == 222 then c elsif k == 223 then d elsif k == 224 then a
      elsif k == 225 then b elsif k == 226 then c elsif k == 227 then d elsif k == 228 then a
      elsif k == 229 then b elsif k == 230 then c elsif k == 231 then d elsif k == 232 then a
      elsif k == 233 then b elsif k == 234 then c elsif k == 235 then d elsif k == 236 then a
      elsif k == 237 then b elsif k == 238 then c elsif k == 239 then d elsif k == 240 then a
      elsif k == 241 then b elsif k == 242 then c elsif k == 243 then d elsif k == 244 then a
      elsif k == 245 then b elsif k == 246 then c elsif k == 247 then d elsif k == 248 then a
      elsif k == 249 then b elsif k == 250 then c elsif k == 251 then d elsif k == 252 then a
      elsif k == 253 then b elsif k == 254 then c elsif k == 255 then d elsif k == 256 then a
      elsif k == 257 then b elsif k == 258 then c elsif k == 259 then d elsif k == 260 then a
      elsif k == 261 then b elsif k == 262 then c elsif k == 263 then d elsif k == 264 then a
      elsif k == 265 then b elsif k == 266 then c elsif k == 267 then d elsif k == 268 then a
      elsif k == 269 then b elsif k == 270 then c elsif k == 271 then d elsif k == 272 then a
      elsif k == 273 then b elsif k == 274 then c elsif k == 275 then d elsif k == 276 then a
      elsif k == 277 then b elsif k == 278 then c elsif k == 279 then d elsif k == 280 then a
      elsif k == 281 then b elsif k == 282 then c elsif k == 283 then d elsif k == 284 then a
      elsif k == 285 then b elsif k == 286 then c elsif k == 287 then d elsif k == 288 then a
      elsif k == 289 then b elsif k == 290 then c elsif k == 291 then d elsif k == 292 then a
      elsif k == 293 then b elsif k == 294 then c elsif k == 295 then d elsif k == 296 then a
      elsif k == 297 then b elsif k == 298 then c
      else d end
  t << "x"
  puts "#{k}: #{t} #{a} #{b} #{c} #{d} #{t.equal?(a)} #{t.equal?(b)} #{t.equal?(c)} #{t.equal?(d)}"
end
[0, 1, 2, 3, 62, 63, 64, 65, 66, 99, 100, 101, 254, 255, 256, 257, 258, 297, 298, 299, 1000].each do |k|
  pick(k, +"a", +"b", +"c", +"d")
end
