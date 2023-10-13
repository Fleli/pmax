extension FunctionBodyStatement {
    
    func lowerToPIL(_ lowerer: PILLowerer) -> [PILStatement] {
        
        // Declarations notify the lowerer's local scope of the new variable.
        // As expressions are lowered, we check (via reference lowering) that the variables they refer to exist.
        // Thus, no statements _here_ need to verify that the variables they use actually exist.
        
        // TODO: På et eller annet tidspunkt må assignments endres til å ha expressions som lhs siden vi må kunne skrive på dereferenced adresser osv.
        // Ordne det senere ...
        
        switch self {
        case .declaration(let declaration):
            
            let type = PILType(declaration.type, lowerer)
            let pilDecl = PILStatement.declaration(type: type, name: declaration.name)
            
            let success = lowerer.local.declare(type, declaration.name)
            
            guard success else {
                // The declaration in the scope submits an error message, so we don't need to do it here.
                return []
            }
            
            guard let initValue = declaration.value else {
                return [pilDecl]
            }
            
            let lhs = [declaration.name]
            let rhs = initValue.lowerToPIL(lowerer)
            let pilAssign = PILStatement.assignment(lhs: lhs, rhs: rhs)
            
            // TODO: Should change this so that if `x` is declared, you can't use `x` in its rhs (either disallow, produce warning or try to use `x` from an outer scope). Consider adding a temporary variable that is assigned _before_ `x` is declared, and then assign that to `x`. Be wary of any cryptic error messages resulting from this, though.
            
            if type != rhs.type && type != .error && rhs.type != .error {
                lowerer.submitError(.assignmentTypeMismatch(variable: declaration.name, expected: type, actual: rhs.type))
            }
            
            return [pilDecl, pilAssign]
            
        case .assignment(let assignment):
            
            let lhs = assignment.lhs.flattenReference()
            let rhs = assignment.rhs.lowerToPIL(lowerer)
            
            let lhsType = PILExpression(.reference(lhs), lowerer).type
            let rhsType = rhs.type
            
            let description = lhs.reduce("", {$0 + $1 + "."}).dropLast()
            
            if lhsType != rhsType && lhsType != .error && rhsType != .error {
                lowerer.submitError(.assignmentTypeMismatch(variable: String(description), expected: lhsType, actual: rhsType))
            }
            
            let pilAssign = PILStatement.assignment(lhs: lhs, rhs: rhs)
            
            return [pilAssign]
            
        case .return(let `return`):
            
            let expression = `return`.expression?.lowerToPIL(lowerer)
            let pilReturn = PILStatement.`return`(expression: expression)
            
            return [pilReturn]
            
        case .if(let `if`):
            
            let wrappedIf = `if`.lowerToPIL(lowerer)
            let pilIf = PILStatement.`if`(wrappedIf)
            
            return [pilIf]
            
        case .while(let `while`):
            
            let condition = `while`.condition.lowerToPIL(lowerer)
            
            lowerer.push()
            
            let body = `while`.body.reduce([PILStatement](), { $0 + $1.lowerToPIL(lowerer) })
            
            lowerer.pop()
            
            let pilWhile = PILStatement.`while`(condition: condition, body: body)
            
            return [pilWhile]
            
        }
        
    }
    
}
