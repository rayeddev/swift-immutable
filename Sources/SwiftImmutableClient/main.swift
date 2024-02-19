import SwiftImmutable


@Clone
struct Person {
    let id: Int, name: String?
    let age: Int
    let active: Bool
    let open: Bool?


    func calc() -> Int {
        return age + 10
    }
    
}

struct Human {
    let id: Int
    let name: String
    var nationalty: String = "Saudi"
    
    init(id: Int, name: String, nationalty: String? = "Saudi") {
        self.id = id
        self.name = name
        if let nationalty {
            self.nationalty = nationalty
        }
    }
}

var h = Human(id: 1, name: "rayed", nationalty: "yemmen")
print("human \(h)")

var s = Person(id: 1, name: "Rayed", age: 40, active: false, open: false)


s = s.clone(inc: .age(s.age))
print("inc Age: \(s)")


s = s.clone(dec: .age(s.age))
print("dec Age: \(s)")


s = s.clone(id: 1)

s = s.clone(prefix: .name("Mr. "))
print("s \(s)")
s = s.clone(suffix: .name(" With Respect"))
print("s \(s)")


s = s.clone(toggle: .active)
print("s \(s) calc:\(s.calc())")

