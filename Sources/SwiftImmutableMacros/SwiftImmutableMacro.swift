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
    let isPrivate: Bool
    let isLet: Bool

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
            
            let members = extractStructMemebers(node: declaration)
            let mutateArgs = mutateArgumentsSyx(members: members)
            let initArgs = initArgumentsSyx(members: members)
            let boolKeys = boolKeysSyx(members: members)
            let boolSwitchs = boolKeysSyx(members: members, switchCase: true)
            
            
            
            var syx: [DeclSyntax] =  ["""
        public func clone(
        \(raw: mutateArgs.joined(separator: ", "))
        ) -> \(raw: name)
        {
            print(\"copy\")
            return \(raw: name)(\(raw: initArgs.joined(separator: ", ")) )
        }
        """
            ]
            
            if boolKeys.count > 0 {
                syx.append(
    """
    public enum BoolKeys {
        \(raw: boolKeys.joined(separator: ", "))
    }
    """
                )
                
                
                syx.append(
                """
              public func clone(toggle __toggle: \(raw: name).BoolKeys) -> \(raw: name)
              {
                 \(raw: boolSwitchs.joined())
              
                 return self
              }
              """
                )
            }
            
            
        
            
        return syx
                     
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
        
            
            
    
            let isPrivate = decl.modifiers.contains { $0.name.text == "private" }

            
            if let binding = decl.bindings.first,
                   let _ = binding.initializer  {
                 continue
             }
            
            
            for binding in decl.bindings {
                // Extract the identifier (variable name) and its type annotation
                var memberName: String?
                var memberType: String?
                var isOptional: Bool = false
                var isLet: Bool = true
                
                
                
                if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    memberName = identifierPattern.identifier.text
                }
                else
                {
                    continue
                }
                
                
                
                
                if let typeAnnotation = binding.typeAnnotation {
                    memberType = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    isOptional =  memberType?.hasSuffix("?") ?? false
                                        
                }
                
                
                
                
                // Print the member name and type if available
                if let name = memberName, let type =  memberType {
                
                    result.append(StructMember(name: name, type: type, isOptional: isOptional, isPrivate: isPrivate, isLet: isLet))
                    
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

fileprivate func mutateArgumentsSyx(members: [StructMember]) -> [String]
{
    var result: [String] = []
    for member in members {
        if !member.isLet
        {
            continue
        }
        result.append("\(member.name): \(member.type)? = nil")
    }
    
    return result
}

fileprivate func initArgumentsSyx(members: [StructMember]) -> [String]
{
    var result: [String] = []
    for member in members {
        if member.isLet {
            result.append("\(member.name): \(member.name) ??  self.\(member.name)")
        }
        else {
            result.append("\(member.name): self.\(member.name)")
        }
    }
    
    return result
}


private func boolKeysSyx(members: [StructMember], switchCase: Bool = false) -> [String]
{
    var result: [String] = []
    for member in members {
        
        
    let name = member.name
    let type = member.type
        
        if type == "Bool", member.isLet {
        if switchCase {
            result.append(
            """
            if case .\(name) = __toggle {
                return self.clone(\(name): !self.\(name))
            }
        """
            )
        }
        else
        {
            if result.count == 0 {
                result.append("case \(name)")
            }
            else
            {
                result.append("\(name)")
            }
        }
        
    }
        
    }
    
    return result
}


@main
struct SwiftImmutablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CloneMacro.self,
    ]
}
