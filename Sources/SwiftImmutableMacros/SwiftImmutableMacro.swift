import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


enum CopyMacroError: Error {
    case msessge(String)
}
public struct CopyMacro: MemberMacro
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
            
            let  arguments = generateMemebrs(node: declaration)
            let constructorArgs = generateConstructor(node: declaration)
            let boolKeys = generateBoolKeys(node: declaration)
            let boolSwitchs = generateBoolKeys(node: declaration, switchCase: true)
            
            
            
            var syx: [DeclSyntax] =  ["""
        public func copy(
        \(raw: arguments.joined(separator: ", "))
        ) -> \(raw: name)
        {
            print(\"copy\")
            return \(raw: name)(\(raw: constructorArgs.joined(separator: ", ")) )
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
              public func copy(toggle __toggle: \(raw: name).BoolKeys) -> \(raw: name)
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

private func generateMemebrs(node: DeclGroupSyntax) -> [String]
{
    var result: [String] = []
    for member in node.memberBlock.members {
        
        if let decl = member.decl.as(VariableDeclSyntax.self) {        
            for binding in decl.bindings {                
                // Extract the identifier (variable name) and its type annotation
                var memberName: String?
                var memberType: String?
                
                if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    memberName = identifierPattern.identifier.text
                }
                
                if let typeAnnotation = binding.typeAnnotation {
                    memberType = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Print the member name and type if available
                if let name = memberName, let type = memberType {
                    result.append("\(name): \(type)? = nil")
                }
            }
        }
    }
    
    return result
}


private func generateConstructor(node: DeclGroupSyntax) -> [String]
{
    var result: [String] = []
    for member in node.memberBlock.members {
        
        if let decl = member.decl.as(VariableDeclSyntax.self) {
            for binding in decl.bindings {
                // Extract the identifier (variable name) and its type annotation
                var memberName: String?
                        
                if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    memberName = identifierPattern.identifier.text
                }
 
                // Print the member name and type if available
                if let name = memberName {
                    result.append("\(name): \(name) ??  self.\(name)")
                }
            }
        }
    }
    
    return result
}

private func generateBoolKeys(node: DeclGroupSyntax, switchCase: Bool = false) -> [String]
{
    var result: [String] = []
    for member in node.memberBlock.members {
        
        if let decl = member.decl.as(VariableDeclSyntax.self) {
            for binding in decl.bindings {
                // Extract the identifier (variable name) and its type annotation
                var memberName: String?
                var memberType: String?
                
                if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    memberName = identifierPattern.identifier.text
                }
                
                if let typeAnnotation = binding.typeAnnotation {
                    memberType = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Print the member name and type if available
                if let name = memberName, let type = memberType {
                    if type == "Bool" {
                        if switchCase {
                            result.append(
                            """
                            if case .\(name) = __toggle {
                                return self.copy(\(name): !self.\(name))
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
            }
        }
    }
    
    return result
}


@main
struct SwiftImmutablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyMacro.self,
    ]
}
