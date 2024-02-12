import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SwiftImmutableMacros)
import SwiftImmutableMacros

let testMacros: [String: Macro.Type] = [
    "Clone": CloneMacro.self,
]
#endif

final class SwiftImmutableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(SwiftImmutableMacros)
        assertMacroExpansion(
            """
            @Clone
            struct Person {
                let id: Int
                let name: String
                let age: Int
            }
            """,
            expandedSource: """
            struct Person {
                let id: Int
                let name: String
                let age: Int

                public func clone(id: Int? = nil, name: String? = nil, age: Int? = nil) -> Person
                {
                    return Person (id: id ??  self.id, name: name ??  self.name, age: age ??  self.age)
                }

                public enum NumKeys {
                    case id(Int)
                    case age(Int)
                }

                public func clone(inc __inc: NumKeys) -> Person
                {
                    switch __inc {
                        case .id(let value):
                        return self.clone(id: self.id + value)
                    case .age(let value):
                        return self.clone(age: self.age + value)
                    }
                }

                public func clone(dec __dec: NumKeys) -> Person
                {
                    switch __dec {
                        case .id(let value):
                        return self.clone(id: self.id - value)
                    case .age(let value):
                        return self.clone(age: self.age - value)
                    }
                }

                public enum StringKeys {
                    case name(String)
                }

                public func clone(prefix __prefix: StringKeys) -> Person
                {
                    switch __prefix {
                        case .name(let value):
                        return self.clone(name: value + self.name)
                    }
                }

                public func clone(suffix __suffix: StringKeys) -> Person
                {
                    switch __suffix {
                        case .name(let value):
                        return self.clone(name: self.name + value)
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }


    func testMacroWithOptional() throws {
        #if canImport(SwiftImmutableMacros)
        assertMacroExpansion(
            """
            @Clone
            struct Person {
                let id: Int
                let name: String
                let age: Int?
            }
            """,
            expandedSource: """
            struct Person {
                let id: Int
                let name: String
                let age: Int?

                public func clone(
                    id: Int? = nil, name: String? = nil, age: Int?? = nil
                ) -> Person
                {
                    return Person (id: id ??  self.id, name: name ??  self.name, age: age ??  self.age )
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
