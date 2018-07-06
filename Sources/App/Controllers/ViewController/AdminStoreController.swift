import Leaf
import Vapor
import Fluent
import Foundation
import Authentication
import Crypto
final class AdminStoreViewController: RouteCollection {
    
    
    func boot(router: Router) throws {
        
        let sessionMiddleware = router.grouped(User.authSessionsMiddleware(), StoreAdminMiddleware())
        
        sessionMiddleware.group("admin") { admin in
            admin.get("stores", use: self.adminStores)
            admin.get("stores", Int.parameter, use: self.adminStore)
            admin.post("stores", Int.parameter, "product", "del", Product.parameter, use: self.deleteProduct)
            admin.post("stores", Int.parameter, "item", "del", Item.parameter, use: self.deleteItem)
            admin.get("stores", Int.parameter, "item", "new", use: self.getNewItem)
            admin.post("stores", Int.parameter, "item", "new", use: self.postNewItem)
            admin.get("item", Int.parameter, "product", "new", use: self.getNewProduct)
            admin.post("item", Int.parameter, "product", "new", use: self.postNewProduct)
        }
    }
    
    
    //##################################################################################################
    //GET: /store
    struct StoresView: Codable {
        var stores: [StoreResponse]
        var activePage: String
        var user: UserResponse
    }
    func adminStores(req: Request) throws -> Future<View> {
        
        return try StoreController().storeResponse(req).flatMap(to: View.self) { storeResponse in
            
            return try UserController().userStructResponse(req).flatMap(to: View.self) { userResponse in
                var stores = storeResponse.filter { (userResponse.stores?.contains($0.id)) ?? false }
                stores.sort() { $0.id < $1.id }
                
                let context = StoresView(stores: stores, activePage: "storeAdmin", user: userResponse)
                return try req.view().render("admin/stores", context)
            }
        }
    }
    
    
    //    ##################################################################################################
    //GET: /admin/store/:id
    func adminStore(req: Request) throws -> Future<View> {
        
        let parameter = try req.parameters.next(Int.self)
        return try StoreController().storeResponse(req).flatMap(to: View.self) { storeResponse in
            let storeResponseArray = storeResponse
            
            return try UserController().userStructResponse(req).flatMap(to: View.self) { userResponse in
                let stores = storeResponseArray.filter { (userResponse.stores?.contains($0.id)) ?? false }
                _ = stores.filter { ($0.id == 1)}
                
                let context = StoresView(stores: stores.filter { ($0.id == parameter)}, activePage: "storeAdmin", user: userResponse)
                return try req.view().render("admin/store", context)
            }
        }
    }
    
    
    //    ##################################################################################################
    // TODO: - work with backend (int parameter problem)
    func deleteProduct(req: Request)throws ->  Future<Response>{
        let i = try req.parameters.next(Int.self)
        return try req.parameters.next(Product.self).map(to: Void.self) { product in
            _ = product.delete(on: req)
            }.flatMap(to: Response.self) { any in
                let redirect = req.redirect(to: "/admin/stores/\(i)")
                return try AnyResponse(redirect).encode(for: req)
        }
    }
    
    //    ##################################################################################################
    // TODO: - work with backend (int parameter problem)
    func deleteItem(req: Request)throws ->  Future<Response>{
        let i = try req.parameters.next(Int.self)
        return try req.parameters.next(Item.self).map(to: Void.self) { item in
            _ = item.delete(on: req)
            }.flatMap(to: Response.self) { any in
                let redirect = req.redirect(to: "/admin/stores/\(i)")
                return try AnyResponse(redirect).encode(for: req)
        }
    }
    
    //    ##################################################################################################
    //renders newItem view
    func getNewItem(_ req: Request) throws -> Future<View> {
        let parameter = try req.parameters.next(Int.self)
        return try StoreController().storeResponse(req).flatMap(to: View.self) { storeResponse in
            let storeResponseArray = storeResponse
            
            return try UserController().userStructResponse(req).flatMap(to: View.self) { userResponse in
                let stores = storeResponseArray.filter { (userResponse.stores?.contains($0.id)) ?? false }
                
                let context = StoresView(stores: stores.filter { ($0.id == parameter)}, activePage: "storeAdmin", user: userResponse)
                return try req.view().render("admin/newItem", context)
            }
        }
    }
    
    
    //    ##################################################################################################
    //stores new item
    func postNewItem(_ req: Request) throws -> Future<Response> {
        
        struct ItemStruct: Codable {
            var storeId: Int?
            var name: String
            var description: String?
            var url: String?
            var startDate: String?
            var endDate: String?
        }
        
        let parameter = try req.parameters.next(Int.self)
        
        return Store.find(parameter, on: req).flatMap(to: Item.self) { store in
            return try req.content.decode(ItemStruct.self).flatMap(to: Item.self) { itemStruct in
                
                print(itemStruct.name)
                
                
                let item = try Item(store: store!, name: itemStruct.name, description: itemStruct.description, url: itemStruct.url, startDate: itemStruct.startDate, endDate: itemStruct.endDate)
                
                return item.save(on: req).map(to: Item.self) { item in
                    return item
                }
            }
            }.flatMap(to: Response.self) { any in
                let redirect = req.redirect(to: "/admin/stores/\(parameter)")
                return try AnyResponse(redirect).encode(for: req)
        }
    }
    
    
    //    ##################################################################################################
    // productView Struct
    struct ProductView: Codable {
        var itemId: Int
        var activePage: String
        var user: UserResponse
    }
    
    //    ##################################################################################################
    //renders newProduct view
    
    func getNewProduct(_ req: Request) throws -> Future<View> {
        let parameter = try req.parameters.next(Int.self)
        
        return try UserController().userStructResponse(req).flatMap(to: View.self) { userResponse in
            
            let context = ProductView(itemId: parameter, activePage: "storeAdmin", user: userResponse)
            return try req.view().render("admin/newProduct", context)
        }
    }
    
    
    //    ##################################################################################################
    //stores new product
    func postNewProduct(_ req: Request) throws -> Future<Response> {
        
        struct ProductStruct: Codable {
            var name: String?
            var description: String?
            var price: Int
            var quantity: Int?
        }
        
        let parameter = try req.parameters.next(Int.self)
        
        return Item.find(parameter, on: req).flatMap(to: Response.self) { item in
            guard let item = item else {
                throw Abort(.badRequest, reason: "no item")
            }
            
            return try req.content.decode(ProductStruct.self).flatMap(to: Product.self) { productStruct in
                
                
                let product = try Product(item: item, price: productStruct.price, name: productStruct.name, description: productStruct.description, quantity: productStruct.quantity!)
                
                return product.save(on: req).map(to: Product.self) { product in
                    return product
                }
                }
                .flatMap(to: Response.self) { any in
                    let redirect = req.redirect(to: "/admin/stores/\(item.storeId)")
                    return try AnyResponse(redirect).encode(for: req)
            }
        }
        
    }
    
}
