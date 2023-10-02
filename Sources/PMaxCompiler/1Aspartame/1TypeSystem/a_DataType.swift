indirect enum DataType {
    
    case void
    case __word
    case pointer(DataType)
    case `struct`(StructType)
    
    /// Convert a grammatical `struct` to a semantic `DataType`.
    init?(_ type: `Type`, _ aspartame: Aspartame) {
        
        switch type {
        case .basic(Builtin.void):
            self = .void
        case .basic(Builtin.native):
            self = .__word
        case .basic(let type):
            
            guard let structType = aspartame.structTypes[type] else {
                aspartame.submitError(.typeDoesNotExist(typeName: type))
                return nil
            }
            
            self = .struct(structType)
            
        case .pointer(let pointee, _):
            
            guard let wrapped = DataType(pointee, aspartame) else {
                // If the wrapped type (pointee) does not exist, an error has already been submitted.
                return nil
            }
            
            self = .pointer(wrapped)
            
        }
        
    }
    
    func size(_ aspartame: Aspartame, _ dependances: Set<StructType>) -> Int {
        
        switch self {
        case .void:
            return 0
        case .__word:
            return 1
        case .pointer(_):
            return 1
        case .struct(let structType):
            // We assume that the result we get is meaningful. Otherwise, the `structType` will submit an error itself.
            structType.generateMemoryLayoutIfMissing(aspartame, dependances)
            return structType.sizeInMemory
        }
        
    }
    
}
