import Leaf
import Vapor
import Fluent
import Foundation
import Authentication
final class StoreViewController: RouteCollection {
    
    
    func boot(router: Router) throws {
        router.get(use: self.index)

        let sessionMiddleware = router.grouped(User.authSessionsMiddleware())
        
        sessionMiddleware.group("") { g in
            
            //stores
            //GET: /stores
            g.get("stores", use: self.stores)
            //GET: /stores/id
            g.get("stores", Int.parameter, use: self.store)
        }
        
    }
    
    //##################################################################################################
    //GET: /
    
    struct indexView: Codable {
        var activePage: String?
        var user: UserResponse?
    }
    
    func index(_ req: Request) throws ->Future<View> {
        
        guard let user = try getUser(req) else {
            return try req.view().render("index")
        }
        return user.flatMap(to: View.self) { user in
            
            let context = indexView(activePage: "index", user: user)
            
            return try req.view().render("index", context)
        }
    }
    
    
    
    //##################################################################################################
    
    //GET: stores
    struct StoresView: Codable {
        var stores: [StoreResponse]
        var activePage: String
        var user: UserResponse
    }
    
    func stores(req: Request) throws -> Future<View> {
        
        
        return try StoreController().storeResponse(req).flatMap(to: View.self) { storeResponse in
            var storeResponseArray = storeResponse
            storeResponseArray.sort() { $0.id < $1.id }
            
            return try UserController().userStructResponse(req).flatMap(to: View.self) { userResponse in

                let context = StoresView(stores: storeResponseArray, activePage: "stores", user: userResponse)
                return try req.view().render("stores", context)
            }
            
            
        }
        
    }
    
    
    //##################################################################################################
        
    
    //GET: /store
        func store(req: Request) throws -> Future<View> {
    
            let parameter = try req.parameters.next(Int.self)
                return try StoreController().storeResponse(req).flatMap(to: View.self) { storeResponse in
                    
                    return try UserController().userStructResponse(req).flatMap(to: View.self) { userResponse in
                   let store = storeResponse.filter { ($0.id == parameter)}
                        let context = StoresView(stores: store, activePage: "store", user: userResponse)
                        return try req.view().render("store", context)
                    }
                }
        }
    
    
    
    
}

