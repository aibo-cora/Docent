import Foundation
import SwiftSyntax
import SwiftParser

public struct KnowledgeContext: Codable {
    public let topic: String
    public let constants: [String: String]
    public let variables: [String]
    public let comments: [String]
    public let methods: [String]
    
    public init(topic: String, constants: [String: String], variables: [String], comments: [String], methods: [String]) {
        self.topic = topic
        self.constants = constants
        self.variables = variables
        self.comments = comments
        self.methods = methods
    }
}

public class KnowledgeScraper: SyntaxVisitor {
    public var contexts: [KnowledgeContext] = []
    
    public static func scrape(source: String) -> [KnowledgeContext] {
        let scraper = KnowledgeScraper(viewMode: .sourceAccurate)
        let sourceFile = Parser.parse(source: source)
        scraper.walk(sourceFile)
        return scraper.contexts
    }
    
    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if let context = processDeclaration(node, name: node.name.text, modifiers: node.modifiers, attributes: node.attributes) {
            contexts.append(context)
        }
        return .visitChildren
    }
    
    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if let context = processDeclaration(node, name: node.name.text, modifiers: node.modifiers, attributes: node.attributes) {
            contexts.append(context)
        }
        return .visitChildren
    }

    private func processDeclaration(_ node: DeclSyntaxProtocol, name: String, modifiers: DeclModifierListSyntax, attributes: AttributeListSyntax) -> KnowledgeContext? {
        // Look for the specific marker in comments
        let leadingTrivia = node.leadingTrivia
        let comments = leadingTrivia.compactMap { piece -> String? in
            if case .docLineComment(let text) = piece {
                return text.replacingOccurrences(of: "///", with: "").trimmingCharacters(in: .whitespaces)
            }
            return nil
        }
        
        guard let docentTag = comments.first(where: { $0.contains("@docent") }) else {
            return nil
        }
        
        print("    [Scraper] Found marker in \(name): \(docentTag)")
        
        // Extract topic from @docent(topic: "Name")
        var topic = name
        if let range = docentTag.range(of: #"(?<=topic: ")[^"]+"#, options: .regularExpression) {
            topic = String(docentTag[range])
        }

        var constants: [String: String] = [:]
        var variables: [String] = []
        var methods: [String] = []

        // Scan members
        if let members = node.as(StructDeclSyntax.self)?.memberBlock.members ?? node.as(ClassDeclSyntax.self)?.memberBlock.members {
            for member in members {
                if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                    let isConstant = varDecl.bindingSpecifier.text == "let"
                    for binding in varDecl.bindings {
                        if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                            let propertyName = pattern.identifier.text
                            if isConstant {
                                if let initializer = binding.initializer {
                                    constants[propertyName] = initializer.value.description
                                } else {
                                    constants[propertyName] = "unknown"
                                }
                            } else {
                                variables.append(propertyName)
                            }
                        }
                    }
                } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                    methods.append(funcDecl.name.text)
                }
            }
        }

        return KnowledgeContext(
            topic: topic,
            constants: constants,
            variables: variables,
            comments: comments.filter { !$0.contains("@docent") },
            methods: methods
        )
    }
}
