import SwiftImmutable


@Copy
struct Rayed {
    let x: Int
    var m: String
    var d: Int
}

var s = Rayed(x: 1, m: "fs", d: 1)
let d = s.copy(m:"check")
