import Fluent
import Foundation
import Vapor

final class Cart: Content {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
   
    var id: ID?
    var userId: User.ID
    var createdAt: Date?
    var updatedAt: Date?
    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }

 
    
    var user: Parent<Cart, User> {
        return parent(\Cart.userId)
    }
    
    init(user: User) throws {
        self.userId = try user.requireID()
    }
}
extension Cart: Model{}
extension Cart: DatabaseModel {
    static func prepare(on connection: Cart.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \Cart.userId, to: \User.id, onDelete: ._setNull)
            }
    }
    
}
extension Cart: Migration {}
extension Cart: Parameter { }
