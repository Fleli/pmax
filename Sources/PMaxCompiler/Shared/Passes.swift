extension Compiler {
    
    
    func lex(_ sourceCode: String, _ asLibrary: Bool) throws {
        
        let rawTokens = try Lexer().lex(sourceCode)
        let tokens = filterTokens(rawTokens)
        
        let tokensFileContent = tokens.map {$0.description}.reduce("", {$0 + $1 + "\n"})
        write(.tokens, tokensFileContent)
        profiler.register(.tokens)
        
        try parse(tokens, asLibrary)
        
    }
    
    
    func parse(_ tokens: [Token], _ asLibrary: Bool) throws {
        
        let slrNodeTree = try SLRParser().parse(tokens)
        
        guard let slrNodeTree else {
            return
        }
        
        let slrNodeTreeFileContent = slrNodeTree.treeDescription(0)
        write(.parseTree, slrNodeTreeFileContent)
        
        let converted = slrNodeTree.convertToTopLevelStatements()
        profiler.register(.parseTree)
        
        lowerToPIL(converted, asLibrary)
        
    }
    
    
    func lowerToPIL(_ converted: TopLevelStatements, _ asLibrary: Bool) {
        
        let pilLowerer = PILLowerer(converted, preprocessor)
        pilLowerer.lower()
        
        encounteredErrors += pilLowerer.errors
        
        guard pilLowerer.noIssues else {
            return
        }
        
        write(.pmaxIntermediateLanguage, pilLowerer.readableDescription)
        profiler.register(.pmaxIntermediateLanguage)
        
        lowerToTAC(pilLowerer, asLibrary)
        
    }
    
    
    func lowerToTAC(_ pilLowerer: PILLowerer, _ asLibrary: Bool) {
        
        let tacLowerer = TACLowerer(pilLowerer)
        tacLowerer.lower(asLibrary)
        
        encounteredErrors += tacLowerer.errors
        
        guard tacLowerer.noIssues else {
            return
        }
        
        write(.threeAddressCode, tacLowerer.description)
        profiler.register(.threeAddressCode)
        
        generateAssembly(tacLowerer, asLibrary)
        
    }
    
    
    func generateAssembly(_ tacLowerer: TACLowerer, _ asLibrary: Bool) {
        
        let labels = tacLowerer.labels
        let asmLowerer = AssemblyLowerer(labels)
        
        let libCode = tacLowerer.libraryAssembly.reduce("") { $0 + $1 + "\n" }
        
        let code = libCode + asmLowerer.lower(asLibrary)
        
        write(.assemblyCode, code)
        profiler.register(.assemblyCode)
        
    }
    
    
}
