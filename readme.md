# swift-immutable

`swift-immutable` is a Swift macro package that extends pure structs with a `clone` method, copy swift struct that inspired by Kotlin's data class `copy` function. This package aims to facilitate immutable programming in Swift, particularly beneficial when working with SwiftUI.

## Features

- Extend pure structs with a `clone` method, allowing for easy modification of immutable structures.
- Syntactic sugar for numeric types, `String`, and `Bool`, enabling convenient operations like increment/decrement and string manipulation.

## Getting Started

To start using `swift-immutable` in your Swift projects, follow these steps:

### Installation

`swift-immutable` is available through Swift Package Manager (SPM). To include it in your project, you need to add the package dependency to your `Package.swift` file.

1. Open your Swift project in Xcode.
2. Navigate to `File` > `Swift Packages` > `Add Package Dependency...`.
3. Paste the following package URL into the search bar:

```swift
    dependencies: [
      .package(url: "https://github.com/rayeddev/swift-immutable.git", from: "<#latest swift-immutable tag#>"),
    ],
```
4. Follow the prompts to add the package to your project.


## Examples

### Basic Cloning


```swift
import SwiftImmutable


// Pure struct
@Clone
struct Person {
    let name: String
    let age: Int
    let active: Bool
    let status: String
}

var person = Person(name: "Tom", age: 20, active: false, status: "free to hire")

// Modify properties with clone
person = person.clone(active: true, status: "not available")
```
## Numeric, String, and Bool Modifiers
```swift
// age increment
person = person.clone(inc: .age(1))

// Toggle active status
person = person.clone(toggle: .active)

// Add prefix to name
person = person.clone(prefix: .name("Mr. "))

// Append suffix to name
person = person.clone(suffix: .name(" legend"))
```

## Working with Collections

```swift
var persons = [Person]()

// Deactivate all
persons = persons.map { $0.clone(toggle: .active) }

// Update status and toggle active
persons = persons.map { $0.clone(status: "hire", toggle: .active) }
```

Limitations
swift-immutable is designed for pure structs that have public or internal let members without initializers.
This constraint ensures that your data structures are truly immutable and encourages best practices in immutable programming.


--

## Benefits of Immutable Programming

Immutable programming involves working with data that cannot be changed after it's created. This approach offers several advantages, especially in UI development with SwiftUI:

- **Predictability**: Immutable data structures help ensure that your UI behaves as expected, as data cannot be altered unexpectedly.
- **Thread-Safety**: Immutability naturally avoids issues related to concurrent data access, making your app safer and more reliable.
- **Easier Debugging**: With immutable data, each state change is explicit, simplifying the debugging process.
- **Optimized Performance with SwiftUI**: SwiftUI optimizes views that depend on immutable data, improving app performance.






