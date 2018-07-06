import Fluent
import Foundation
import Vapor

    final class Store: Content {
        
        typealias ID = idType
        public static var idKey: IDKey { return \.id }
        var id: ID?
        var name: String
        var description: String?
        var url: String?
        var email: String?
        var phone: String?
        //Address
        var street: String?
        var number: String?
        var city: String?
        var postalCode: String?
        var country: String?
        
        //Timestampable
        var createdAt: Date?
        var updatedAt: Date?
        public static var createdAtKey: TimestampKey { return \.createdAt }
        public static var updatedAtKey: TimestampKey { return \.updatedAt }
        

        var items: Children<Store, Item> {
            return children(\Item.storeId)
        }

        init(name: String) throws {
            self.name = name
            self.id = try self.requireID()
        }
    }
    
extension Store: DatabaseModel {}
extension Store: Migration {}
extension Store: Parameter {}
