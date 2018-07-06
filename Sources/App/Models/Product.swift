import Fluent
import Foundation
import Vapor

final class Product: Content {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var itemId: Item.ID
    var name: String?
    var description: String?
    var price: Int
    var quantity: Int?
    
    var createdAt: Date?
    var updatedAt: Date?
    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }
    
    var tickets: Children<Product, Ticket> {
        return children(\Ticket.productId)
    }
    
    var item: Parent<Product, Item> {
        return parent(\Product.itemId)
    }
    init(item: Item, price: Int, name: String?, description: String?, quantity: Int) throws {
        self.itemId = try item.requireID()
        self.name = name
        self.description = description
        self.quantity = quantity
        self.price = price
    }
}

extension Product: DatabaseModel {
    
    static func prepare(on connection: Product.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \Product.itemId, to: \Item.id, onDelete: ._setNull)
            }
    }
    
}
extension Product: Migration {}
extension Product: Parameter { }
