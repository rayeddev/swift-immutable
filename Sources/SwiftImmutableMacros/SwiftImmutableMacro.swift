import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


enum CopyMacroError: Error {
    case msessge(String)
}

fileprivate struct StructMember
{
    let name: String
    let type: String
    let isOptional: Bool
    let isLet: Bool 
    let hasInitialValue: Bool


}

public struct CloneMacro: MemberMacro
{
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext) throws -> [DeclSyntax] {
            
            guard declaration.is(StructDeclSyntax.self) else {
                throw CopyMacroError.msessge("Copy macro only con be applied to struct type")
            }
            
            
            guard let name = declaration.asProtocol(NamedDeclSyntax.self)?.name else
            {
                throw CopyMacroError.msessge("No struct identfier")
            }

            // continue if decalration has syntactic error
            guard !declaration.hasError else {
                return []
            }
            
            let members = extractStructMemebers(node: declaration)
            
            guard members.count > 0 else {
                return []
            }
            

            
            
            
            let result: [DeclSyntax] = initCloneSyntax(name: name.text, members: members)
            + numnaricMembersSyntax(name: name.text, members: members)
            + stringMembersSyx(name: name.text, members: members)
            + booleanMembersSyx(name: name.text, members: members)

            // diagnosing result before return 

            
            
            
            
        
            
        return result
                     
    }
}


private func extractStructMemebers(node: DeclGroupSyntax) -> [StructMember]
{
    var result: [StructMember] = []
    
    for member in node.memberBlock.members {
        
        if let decl = member.decl.as(VariableDeclSyntax.self) {
            if decl.hasError
            {
                continue
            }
         
            let isLet =   decl.modifiers.contains(where: { $0.name.text == "let"})
        
            
            
            // ignore if it is private
            let isPrivate = decl.modifiers.contains  {["private", "fileprivate"].contains( $0.name.text) }
            if isPrivate
            {
                continue
            }

            var hasInitialValue = false
            // ignore if it have initializers
            if let binding = decl.bindings.first,
                   let _ = binding.initializer  {
                hasInitialValue = true                                   
             }
               
            
            // loop through inline identifiers e.g: let name: string, game: Int
            for binding in decl.bindings {
                // Extract the identifier (variable name) and its type annotation
                var memberName: String?
                var memberType: String?
                var isOptional: Bool = false
                
                
                
                
                if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    memberName = identifierPattern.identifier.text
                }
                else
                {
                    continue
                }
                

                if let initializerClause = binding.initializer {
                    continue
                }
                
                // continue if accessor block is not only didSet or willSet
                if let accessors = binding.accessorBlock {
                    continue
                }
                
                
                
                if let typeAnnotation = binding.typeAnnotation {
                    memberType = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // ignore if double optional
                    if memberType?.hasSuffix("??") ?? false {
                        continue
                    }

                    isOptional =  memberType?.hasSuffix("?") ?? false
                }
                
                
                
                
                // Print the member name and type if available
                if let name = memberName, let type =  memberType {
                
                    result.append(StructMember(name: name, type: type, isOptional: isOptional, isLet: isLet, hasInitialValue: hasInitialValue))
                    
                }
                else
                {
                    continue
                }
            }
        }
    }

    
    
    return result
}



fileprivate func initCloneSyntax(name: String, members: [StructMember]) -> [DeclSyntax]
{
    let args = members.map { "\($0.name): \($0.type.filter{ $0.isLetter })? = nil" }.joined(separator: ", ")
    let invokeArgsNoIntitializers = members
    .filter { !$0.hasInitialValue }
    .map { "\($0.name): \($0.name) ??  self.\($0.name)" }.joined(separator: ", ")

    let invokeArgs = members.map { "\($0.name): \($0.name) ??  self.\($0.name)" }.joined(separator: ", ")
    
    return [
        """
        public func clone(\(raw: args)) -> \(raw: name)
        {
            return \(raw: name)(\(raw: invokeArgsNoIntitializers))
        }
        """
    ]
}


fileprivate func numnaricMembersSyntax(name: String, members: [StructMember]) -> [DeclSyntax]
{
    let nMembers = members.filter { member in
        ["Int", "Int8", "Int16", "Int32", "Int64",
         "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
         "Float", "Double"].contains(member.type.filter { $0.isLetter })
        }   


    guard nMembers.count > 0 else {
        return []
    }

    return [
        // members as enum with type associated value
        """
        public enum NumKeys {
            \(raw: nMembers.map { "case \($0.name)(\($0.type.filter { $0.isLetter } ))" }.joined(separator: "\n"))
        }
        """,

        // clone with inc prameter
        """
        public func clone(inc __inc: \(raw: name).NumKeys) -> \(raw: name)
        {
            switch __inc {
                \(raw: nMembers.map { 
                    if $0.isOptional {
                        return "case .\($0.name)(let value): return self.clone(\($0.name): self.\($0.name) != nil ? self.\($0.name)! + value : value)" 
                    }
                    return "case .\($0.name)(let value): return self.clone(\($0.name): self.\($0.name) + value)"
                 }.joined(separator: "\n"))
            }
        }
        """,

        // clone with dec  prameter
        """
        public func clone(dec __dec: \(raw: name).NumKeys) -> \(raw: name)
        {
            switch __dec {
                \(raw: nMembers.map { 
                    if $0.isOptional {
                        return "case .\($0.name)(let value): return self.clone(\($0.name): self.\($0.name) != nil ? self.\($0.name)! - value : -value)" 
                    }
                    return "case .\($0.name)(let value): return self.clone(\($0.name): self.\($0.name) - value)"
                 }.joined(separator: "\n"))
            }
        }
        """
    ]    
}


fileprivate func stringMembersSyx(name: String, members: [StructMember]) -> [DeclSyntax]
{
    let sMembers = members.filter { member in
        member.type.starts(with:"String")
    }

    guard sMembers.count > 0 else {
        return []
    }

    return [
        // members as enum with type associated value
        """
        public enum StringKeys {
            \(raw: sMembers.map { "case \($0.name)(\($0.type.filter{ $0.isLetter } ))" }.joined(separator: "\n"))
        }
        """,

        // clone with prefix prameter
        """
        public func clone(prefix __prefix: \(raw: name).StringKeys) -> \(raw: name)
        {
            switch __prefix {
                \(raw: sMembers.map {
                    if $0.isOptional {
                        return "case .\($0.name)(let value): return self.clone(\($0.name): self.\($0.name) != nil ?  value + self.\($0.name)! : value)"
                    }
                    return "case .\($0.name)(let value): return self.clone(\($0.name): value + self.\($0.name))"
                }.joined(separator: "\n"))                
            }
        }
        """,

        // clone with suffix  prameter
        """
        public func clone(suffix __suffix: \(raw: name).StringKeys) -> \(raw: name)
        {
            switch __suffix {
                \(raw: sMembers.map {
                    if $0.isOptional {
                        return "case .\($0.name)(let value): return self.clone(\($0.name): self.\($0.name) != nil ?  self.\($0.name)! + value : value)"
                    }
                    return "case .\($0.name)(let value): return self.clone(\($0.name): self.\($0.name) + value)"
                }.joined(separator: "\n"))
            }
        }
        """
    ]
}

fileprivate func booleanMembersSyx(name: String, members: [StructMember]) -> [DeclSyntax]
{
    let bMembers =  members.filter { member in
        member.type.starts(with:"Bool")
    }

    guard bMembers.count > 0 else {
        return []
    }

    return [
        // members as enum with type associated value
        """
        public enum BoolKeys {
            \(raw: bMembers.map { "case \($0.name)" }.joined(separator: "\n"))
        }
        """,

        // clone with toggle prameter
        """
        public func clone(toggle __toggle: \(raw: name).BoolKeys) -> \(raw: name)
        {
            switch __toggle {
                \(raw: bMembers.map { 
                    if $0.isOptional {
                        return "case .\($0.name): return self.clone(\($0.name): self.\($0.name) == nil ? true : !(self.\($0.name)!))"
                    }
                    return "case .\($0.name): return self.clone(\($0.name): !self.\($0.name))"
                 }.joined(separator: "\n"))
            }
        }
        """
    ]
}



@main
struct SwiftImmutablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CloneMacro.self,
    ]
}
