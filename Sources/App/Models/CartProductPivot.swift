import Async
import Fluent
import Foundation
import Fluent

final class CartProductPivot: ModifiablePivot {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var cartId: Cart.ID
    var productId: Product.ID
    
    typealias Left = Cart
    typealias Right = Product
    
    public static var leftIDKey: LeftIDKey { return \.cartId }
    public static var rightIDKey: RightIDKey { return \.productId }
    
    init(_ cart: Cart, _ product: Product) throws {
        cartId = try cart.requireID()
        productId = try product.requireID()
    }
}

extension CartProductPivot: DatabaseModel {
    
    static func prepare(on connection: CartProductPivot.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \CartProductPivot.cartId, to: \Cart.id, onDelete: ._setNull)
                builder.reference(from: \CartProductPivot.productId, to: \Product.id)
            }
    }
    
    
}
extension CartProductPivot: Migration {}
