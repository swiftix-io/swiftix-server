import Async
import Fluent
import Foundation
import Fluent

final class CheckoutProductPivot: ModifiablePivot {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var checkoutId: Checkout.ID
    var productId: Product.ID
    
    typealias Left = Checkout
    typealias Right = Product
    

    
    init(_ checkout: Checkout, _ product: Product) throws {
        checkoutId = try checkout.requireID()
        productId = try product.requireID()
    }
    
    public static var leftIDKey: LeftIDKey { return \.checkoutId }
    public static var rightIDKey: RightIDKey { return \.productId }
}

extension CheckoutProductPivot: DatabaseModel {
    
    static func prepare(on connection: CheckoutProductPivot.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \CheckoutProductPivot.checkoutId, to: \Checkout.id, onDelete: ._setNull)
                builder.reference(from: \CheckoutProductPivot.productId, to: \Product.id, onDelete: ._setNull)
            }
    }
}
extension CheckoutProductPivot: Migration {}
