import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct DocentMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. Validation: Ensure we are attached to a valid type
        if !declaration.is(StructDeclSyntax.self) && 
           !declaration.is(ClassDeclSyntax.self) && 
           !declaration.is(EnumDeclSyntax.self) {
            
            let diagnostic = Diagnostic(
                node: node,
                message: DocentMacroDiagnostic.onlyApplicableToTypes
            )
            context.diagnose(diagnostic)
        }
        
        // This macro is a "marker" macro for the build-time scraper.
        // It doesn't generate any code at compile-time.
        return []
    }
}

enum DocentMacroDiagnostic: String, DiagnosticMessage {
    case onlyApplicableToTypes
    
    var severity: DiagnosticSeverity { .error }
    
    var message: String {
        switch self {
        case .onlyApplicableToTypes:
            return "@Docent can only be applied to structs, classes, or enums."
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "DocentMacros", id: rawValue)
    }
}

@main
struct DocentMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DocentMacro.self
    ]
}
