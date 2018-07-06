import Foundation
import FluentPostgreSQL

enum constants {
    static let APP_URL = "0.0.0.0"
    static let APP_PORT = 8080
    
    static let DATABASE_URL = "0.0.0.0"
    static let DATABASE_PORT = 5432
    static let DATABASE_USER = "swiftix"
    static let DATABASE_PASSWORD: String? = nil

    static let BACKEND_HOST = "http://0.0.0.0:8080/api/v1/"
    
    static let TOKEN_STRING = UUID().uuidString
    
    static let STRIPE_SK = ProcessInfo.processInfo.environment["STRIPE_SK"] ?? "sk_test_your_secret_key"
    static let STRIPE_CHARGES_URL = "https://api.stripe.com/v1/charges"

}

public typealias DatabaseModel = PostgreSQLModel

public typealias checkoutIdType = Int
public typealias idType = Int
