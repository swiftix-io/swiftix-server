import Vapor

final class ProductController: RouteCollection {
    
    let storeAdminMiddleware = StoreAdminMiddleware()
    
    func boot(router: Router) throws {
        router.group("api") { api in
            api.group("v1") { v1 in
                v1.group("products") { products in
                    products.get(use: self.index)
                    products.get(Product.parameter, use: self.show)
                    
                    let adminGroup = products.grouped(storeAdminMiddleware)
                    adminGroup.post(use: self.create)
                    adminGroup.patch(Product.parameter, use: self.update)
                    adminGroup.delete(Product.parameter, use: self.delete)
                }
            }
        }
    }
    /// Returns a list of all `Product`s
    func index(_ req: Request) throws -> Future<[Product]> {
        return Product.query(on: req).all()
    }
    
    
    /// create product
    func create(_ req: Request) throws -> Future<Product> {
        return try req.content.decode(Product.self).flatMap(to: Product.self) { product in
            return product.save(on: req)
        }
    }
    
    /// Show a parameterized `Product`
    func show(_ req: Request) throws -> Future<Product> {
        return try req.parameters.next(Product.self)
    }
    
    /// Update a parameterized `Product`
    func update(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Product.self).flatMap(to: Product.self) { product in
            return try req.content.decode(Product.self).flatMap(to: Product.self) { reqproduct in
                reqproduct.id = product.id
                return reqproduct.update(on: req)
            }
            }.transform(to: .ok)
    }
    
    /// Deletes a parameterized `Product`
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Product.self).map(to: Void.self) { product in
            _ = product.delete(on: req)
            }.transform(to: .ok)
    }
}



