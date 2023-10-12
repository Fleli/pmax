class PILIfStatement {
    
    let condition: PILExpression
    
    let body: [PILStatement]
    
    let `else`: PILIfStatement?
    
    init(_ condition: PILExpression, _ body: [PILStatement], _ `else`: PILIfStatement? = nil) {
        self.condition = condition
        self.body = body
        self.`else` = `else`
    }
    
    func _print(_ indent: Int) {
        
        let prefix = String(repeating: "|   ", count: indent)
        
        print(prefix + "if \(condition.description) {")
        
        for stmt in body {
            stmt._print(indent + 1)
        }
        
        print(prefix + "}")
        
        `else`?._print(indent)
        
    }
    
}
