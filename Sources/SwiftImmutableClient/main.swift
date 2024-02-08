import SwiftImmutable


@Clone
struct Rayed {
    let x: Int = 1
    var m: String
    var d: Int
}

var s = Rayed(m: "fs", d: 1)
let d = s.clone()
