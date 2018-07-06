import Vapor

final class ItemController: RouteCollection {
    
    
    
    func boot(router: Router) throws {
        router.group("api") { api in
            api.group("v1") { v1 in
                    v1.group("items") { items in
                        items.get(use: self.index)
                        items.post(use: self.create)
                        items.get(Item.parameter, use: self.show)
                        items.patch(Item.parameter, use: self.update)
                        items.delete(Item.parameter, use: self.delete)
                    }
                }
            }
        }
    
        /// Returns a list of all `Item`s
        func index(_ req: Request) throws -> Future<[Item]> {
            return Item.query(on: req).all()
        }
        
        
        
        /// create item
        func create(_ req: Request) throws -> Future<Item> {
            return try req.content.decode(Item.self).flatMap(to: Item.self) { item in
                return item.save(on: req)
            }
        }
        
        /// Show a parameterized `Item`
        func show(_ req: Request) throws -> Future<Item> {
            return try req.parameters.next(Item.self)
        }
        
        /// Update a parameterized `Item`
        func update(_ req: Request) throws -> Future<HTTPStatus> {
            return try req.parameters.next(Item.self).flatMap(to: Item.self) { item in
                return try req.content.decode(Item.self).flatMap(to: Item.self) { reqitem in
                    reqitem.id = item.id
                    return reqitem.update(on: req)
                }
                }.transform(to: .ok)
        }
        
        /// Deletes a parameterized `Item`
        func delete(_ req: Request) throws -> Future<HTTPStatus> {
            return try req.parameters.next(Item.self).map(to: Void.self) { item in
                _ = item.delete(on: req)
                }.transform(to: .ok)
        }
}


