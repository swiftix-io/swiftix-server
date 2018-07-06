import Fluent
import Foundation
import Vapor

final class Checkout: Content {
    
    typealias ID = checkoutIdType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var cartId: Cart.ID
    var total: Int
    var createdAt: Date?
    var updatedAt: Date?
    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }

    var cart: Parent<Checkout, Cart> {
        return parent(\Checkout.cartId)
    }
    
    init(cart: Cart, total: Int) throws {
        self.cartId = try cart.requireID()
        self.total = total
    }
}

extension Checkout: DatabaseModel {
    static func prepare(on connection: Checkout.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \Checkout.cartId, to: \Cart.id, onDelete: ._setNull)
            }
    }
}
extension Checkout: Migration {}
extension Checkout: Parameter { }


