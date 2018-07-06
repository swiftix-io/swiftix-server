import Fluent
import Foundation
import Vapor


    final class Ticket: Content {

        typealias ID = idType
        public static var idKey: IDKey { return \.id }
        var id: ID?

        var productId: Product.ID
        var orderId: Order.ID
        var code: String?
        var createdAt: Date?
        var updatedAt: Date?

        public static var createdAtKey: TimestampKey { return \.createdAt }
        public static var updatedAtKey: TimestampKey { return \.updatedAt }
        
        
        var order: Parent<Ticket, Order> {
            return parent(\Ticket.orderId)
        }
        var product: Parent<Ticket, Product> {
            return parent(\Ticket.productId)
        }
        
        
        
        init(order: Order, product: Product) throws {
            self.code = UUID().uuidString
            self.orderId = try order.requireID()
            self.productId = try product.requireID()
        }
    }
    
extension Ticket: DatabaseModel  {
    
    static func prepare(on connection: Ticket.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \Ticket.productId, to: \Product.id, onDelete: ._setNull)
                builder.reference(from: \Ticket.orderId, to: \Order.id, onDelete: ._setNull)
            }
    }
    
    
}
extension Ticket: Migration {}
extension Ticket: Parameter { }
