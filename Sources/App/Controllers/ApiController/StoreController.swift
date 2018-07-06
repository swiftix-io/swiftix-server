import Vapor
import Foundation
import Fluent

final class StoreController: RouteCollection {
    
    let adminMiddleware = AdminMiddleware()

    func boot(router: Router) throws {
        router.group("api") { api in
            api.group("v1") { v1 in
                v1.group("stores") { stores in
                    stores.get(use: self.storeResponse)
                    stores.get(Store.parameter, use: self.show)

                    let adminGroup = stores.grouped(adminMiddleware)

                    adminGroup.post(use: self.create)
                    adminGroup.patch(Store.parameter, use: self.update)
                    adminGroup.delete(Store.parameter, use: self.delete)
                }
            }
        }
    }
    
    /// Returns a list of all `store`s
    func index(_ req: Request) throws -> Future<[Store]> {
        return Store.query(on: req).all()
    }
    
    /// Saves a decoded `store` to the database
    func create(_ req: Request) throws -> Future<Store> {
        return try req.content.decode(Store.self).flatMap(to: Store.self) { store in
            return store.save(on: req)
        }
    }
    
    /// Show a parameterized `store`
    func show(_ req: Request) throws -> Future<Store> {
        return try req.parameters.next(Store.self)
    }
    
    /// Update a parameterized `store`
    func update(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Store.self).flatMap(to: Store.self) { store in
            return try req.content.decode(Store.self).flatMap(to: Store.self) { reqStore in
                reqStore.id = store.id
                return reqStore.update(on: req)
            }
            }.transform(to: .ok)
    }
    
    /// Deletes a parameterized `store`
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Store.self).map(to: Void.self) { store in
            _ = store.delete(on: req)
            }.transform(to: .ok)
    }
    
    
    // returns array of stores with array of items with array of products
    func storeResponse(_ req: Request) throws -> Future<[StoreResponse]> {
        //###################################################################
        
        
        // inner function
        func products (_ req: Request, itemId: Int) throws -> Future<[ProductResponse]> {
            return Product.query(on: req).group(.and) { and in
                and.filter(\Product.itemId == itemId)
                }.all()
                .map(to: Array<ProductResponse>.self) { products in
                return products.map { product in
                    return ProductResponse(id: product.id ?? 0, itemId: product.itemId ,name: product.name, description: product.description, price: product.price, quantity: product.quantity)
                }
            }
        }
        // inner function
        func items (_ req: Request, storeId: Int) throws -> Future<[ItemResponse]> {
            
            return Item.query(on: req).group(.and) { and in
                and.filter(\Item.storeId == storeId)
                }.all()
                .flatMap(to: Array<ItemResponse>.self) { items -> Future<[ItemResponse]> in
                
                return try items.map { item in
                    try products(req,itemId: item.id!).map(to: ItemResponse.self) { productResponseArray in
                        
                        return ItemResponse(id: item.id ?? 0,
                                            storeId: item.storeId,
                                            name: item.name,
                                            description: item.description,
                                            url: item.url,
                                            startDate: item.startDate,
                                            endDate: item.endDate,
                                            products: productResponseArray)
                    }
                    }.flatten(on: req)
            }
        }
        
        // inner function
        func stores (_ req: Request) throws -> Future<[StoreResponse]> {
            return Store.query(on: req).all().flatMap(to: Array<StoreResponse>.self) { stores -> Future<[StoreResponse]> in
                return try stores.map { store in
                    try items(req,storeId: store.id!).map(to: StoreResponse.self) { itemResponseArray in
                        
                        return StoreResponse(id: store.id ?? 0,
                                             name: store.name,
                                             description: store.description,
                                             url: store.url,
                                             email: store.email,
                                             phone: store.phone,
                                             street: store.street,
                                             number: store.number,
                                             city: store.city,
                                             postalCode: store.postalCode,
                                             country: store.country,
                                             items: itemResponseArray)
                    }
                    }.flatten(on: req)
            }
        }
        return try stores(req)
    }
}


