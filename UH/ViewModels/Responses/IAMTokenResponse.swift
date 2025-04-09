struct IAMTokenResponse: Codable {
    let iamToken: String
    
    enum CodingKeys: String, CodingKey {
        case iamToken = "iamToken"
    }
}
