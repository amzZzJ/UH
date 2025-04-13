import SwiftUI

struct AnyIdentifiable: Identifiable {
    let id = UUID()
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
}
