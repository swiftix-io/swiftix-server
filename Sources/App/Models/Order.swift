import Fluent
import Foundation
import Vapor

final class Order: Content {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var userId: User.ID
    var invoiceNr: String?
    var total: Int
    var pending: Bool?
    var createdAt: Date?
    var updatedAt: Date?
    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }

    var cart: Parent<Order, User> {
        return parent(\Order.userId)
    }
    
    var tickets: Children<Order, Ticket> {
        return children(\Ticket.orderId)
    }

    init(user: User, total: Int, pending: Bool? = true) throws {
        self.userId = try user.requireID()
        self.invoiceNr = UUID().uuidString
        self.total = total
        self.pending = pending
    }
}

extension Order: DatabaseModel {
    static func prepare(on connection: Order.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \Order.userId, to: \User.id, onDelete: ._setNull)
            }
    }
}
extension Order: Migration {}
extension Order: Parameter { }


