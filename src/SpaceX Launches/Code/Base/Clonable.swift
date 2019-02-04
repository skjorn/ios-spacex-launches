//

protocol Clonable {
    
    associatedtype Value: Clonable where Value == Self
    
    init(value: Value)
}
