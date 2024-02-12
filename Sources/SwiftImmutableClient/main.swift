import SwiftImmutable


@Clone
struct Person {
    let id: Int
    let name: String?
    let age: Int
    let active: Bool
    let open: Bool? = false
    let count: Int? = 0

    func calc() -> Int {
        return age + 10
    }
    
}

var s = Person(id: 1, name: "Rayed", age: 20, active: false)


s = s.clone(inc: .age(s.age))
print("inc Age: \(s)")


s = s.clone(dec: .age(s.age))
print("dec Age: \(s)")


s = s.clone(inc: .count(1))

s = s.clone(prefix: .name("Mr. "))
print("s \(s)")
s = s.clone(suffix: .name(" With Respect"))
print("s \(s)")


s = s.clone(toggle: .active)
print("s \(s) calc:\(s.calc())")

