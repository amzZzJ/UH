struct VitaminResponse: Codable {
    let result: Result

    struct Result: Codable {
        let alternatives: [Alternative]
        
        struct Alternative: Codable {
            let message: Message
            
            struct Message: Codable {
                let text: String
            }
        }
    }
}
