import Fluent
import Foundation
import Vapor

final class Image: Content {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var itemId: Item.ID
    var url: String
    var createdAt: Date?
    var updatedAt: Date?
    
    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }
    
    var item: Parent<Image, Item> {
        return parent(\Image.itemId)
    }
    
    
    init(item: Item, url: String) throws {
        self.itemId = try item.requireID()
        self.url = url
    }
}

extension Image: DatabaseModel {
    
    static func prepare(on connection: Image.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \.itemId, to: \Item.id, onDelete: ._setNull)
            }
    }
    
}


extension Image: Migration {}
extension Image: Parameter { }
