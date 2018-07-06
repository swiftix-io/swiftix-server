import Fluent
import Foundation
import Vapor

final class Item: Content {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var storeId: Store.ID
    var name: String?
    var description: String?
    var url: String?
    var startDate: String?
    var endDate: String?
    
    var createdAt: Date?
    var updatedAt: Date?
    
    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }
    

    
    var images: Children<Item, Image> {
        return children(\Image.itemId)
    }
    
    var products: Children<Item, Product> {
        return children(\Product.itemId)
    }
    
    var store: Parent<Item, Store> {
        return parent(\Item.storeId)
    }
    init(store: Store, name: String?, description: String?, url: String?, startDate: String?, endDate: String?) throws {
        self.storeId = try store.requireID()
        self.name = name
        self.description = description
        self.url = url
        self.startDate = startDate
        self.endDate = endDate
    }
}

extension Item: DatabaseModel {
    
    static func prepare(on connection: Item.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \Item.storeId, to: \Store.id, onDelete: ._setNull)
            }
    }
    
}
extension Item: Migration {}
extension Item: Parameter { }

