import Foundation

struct UserResponse: Codable {
    
    // TODO: - id -> uuid
    var id: idType?
    var name: String?
    var lastName: String?
    var email: String?
    var stores: [Int]?
    var admin: Bool?
}

struct StoreResponse: Codable {
    var id: Int
    var name: String
    var description: String?
    var url: String?
    var email: String?
    var phone: String?
    var street: String?
    var number: String?
    var city: String?
    var postalCode: String?
    var country: String?
    var items: [ItemResponse]?
}

struct ItemResponse: Codable {
    var id: Int
    var storeId: Int
    var name: String?
    var description: String?
    var url: String?
    var startDate: String?
    var endDate: String?
    var products: [ProductResponse]?
}


struct ProductResponse: Codable {
var id: Int
var itemId: Int
var name: String?
var description: String?
var price: Int
var quantity: Int?
}

//vapor
import Vapor

extension UserResponse: Content {}
extension StoreResponse: Content {}
extension ItemResponse: Content {}
extension ProductResponse: Content {}

