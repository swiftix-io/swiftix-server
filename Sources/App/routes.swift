import Routing
import Vapor

final class Routes: RouteCollection {
    
    func boot(router: Router) throws {
        
        try router.register(collection: UserController())
        try router.register(collection: StoreController())
        try router.register(collection: ItemController())
        try router.register(collection: ProductController())
        try router.register(collection: CartController())
        try router.register(collection: StripeController())

        //views
        
        try router.register(collection: StoreViewController())
        try router.register(collection: AdminStoreViewController())
        try router.register(collection: LoginViewController())
    }
}
