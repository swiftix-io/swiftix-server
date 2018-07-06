import Vapor
import Fluent
import Foundation
import Authentication
import Crypto

final class UserController: RouteCollection {
    
    func boot(router: Router) throws {
        
        //middlewares
        let basicMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let tokenMiddleware = User.tokenAuthMiddleware()
        let adminMiddleware = AdminMiddleware()
        
        router.group("api") { api in
            api.group("v1") { v1 in
                v1.group("users") { users in
                    //create user
                    users.post(User.self, use: self.create)
                    // api/v1/users/login
                    let basicGroup = users.grouped(basicMiddleware)
                    basicGroup.get("login", use: self.login)
                    
                    //group api/v1/users/self
                    let tokenGroup = users.grouped(tokenMiddleware)
                    //GET:api/v1/users/struct
                    tokenGroup.get("struct", use: self.userStructResponse)
                    
                    tokenGroup.group("self") { selfGroup in
                        
                        // get:api/v1/users/self
                        selfGroup.get(use: self.show)
                        // update:api/v1/users/self
                        selfGroup.patch(use: self.update)
                        // delete:api/v1/users/self
                        selfGroup.delete(use: self.delete)
                        
                    }
                    
                    // admin:api/v1/users
                    let adminGroup = users.grouped(adminMiddleware)
                    adminGroup.get(use: self.index)
                }
            }
        }
    }
    
    
    //##################################################################################################
    // register a user
    func create(_ req: Request, user: User) throws -> Future<User> {
        try user.validate()
        user.password = try BCrypt.hash(user.password, cost: 12)
        return user.save(on: req)
        
    }
    
    
    
    //##################################################################################################
    func login(req: Request) throws -> Future<Token> {
        
        
        let username = req.http.headers.basicAuthorization?.username
        let password = req.http.headers.basicAuthorization?.password
        
        guard let pw = password else {
            throw Abort(.badRequest, reason: "no password")
        }
        guard let email = username else {
            throw Abort(.badRequest, reason: "no username")
        }
        let authenticationPassword = BasicAuthorization(username: email, password: pw)
        
        return User.authenticate(using: authenticationPassword, verifier: BCryptDigest(), on: req).flatMap(to: Token.self)
        { user in
            
            guard let user = user else {
                throw Abort(.badRequest, reason: "no user")
            }
            
            let newToken = try Token(user: user)
            
            return newToken.save(on: req).map(to: Token.self) { token in
                _ = Token.query(on: req).filter(\.expiry < Date()).delete()
                
                return token
            }
            
        }
    }
    
    
    
    
    //##################################################################################################
    /// get:api/v1/users/self
    func show(_ req: Request) throws -> Future<User> {
        
        return try tokenUser(req: req).map(to: User.self) { user in
            return user
        }
    }
    
    //##################################################################################################
    /// Update:api/v1/users/self
    func update(_ req: Request) throws -> Future<HTTPStatus> {
        
        return try tokenUser(req: req).flatMap(to: User.self) { user in
            return try req.content.decode(User.self).flatMap(to: User.self) { requser in
                requser.id = user.id
                requser.password = try BCrypt.hash(user.password, cost: 12)
                return requser.update(on: req)
            }
            }.transform(to: .ok)
    }
    
    
    
    //##################################################################################################
    /// delete:api/v1/users/self
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try tokenUser(req: req)
            .map(to: Void.self) { user in
            _ = user.delete(on: req)
            }.transform(to: .ok)
    }
    
    
    //##################################################################################################
    /// ADMIN :api/v1/users
    func index(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
        
    }
    
    //##################################################################################################
    /// get userresponse
    func userStructResponse(_ req: Request) throws -> Future<UserResponse> {
        
        guard let userId = try req.authenticatedSession(User.self) else {

            return Token.query(on: req).filter(\Token.token == "0").first().map(to: UserResponse.self) { _ in
                return UserResponse(id: nil, name: nil, lastName: nil, email: nil, stores: nil, admin: nil)
            }

        }
        return Token.query(on: req).filter(\Token.userId == userId).first().flatMap(to: UserResponse.self) { token in
            
            guard let userId = token?.userId else {
                throw Abort(.badRequest, reason: "no user")
            }
           return User.find(userId, on: req).flatMap(to: UserResponse.self) { user in
                guard let user = user else {
                    throw Abort(.badRequest, reason: "")
                }
                return try user.siblings(related: Store.self, through: UserStorePivot.self).query(on: req).all().map(to: Array<Int>.self) { stores in
                    return stores.map { store in
                        store.id!
                    }
                    }.flatMap(to: UserResponse.self) { storeIdArray in
                        return try user.admins.query(on: req).first().map(to: UserResponse.self) { admin in
                            guard let _ = admin else {
                                return UserResponse(id: userId, name: user.name, lastName: user.lastName, email: user.email, stores: storeIdArray, admin: false)
                            }
                            return UserResponse(id: userId, name: user.name, lastName: user.lastName, email: user.email, stores: storeIdArray, admin: true)
                        }
                }
            }
        }
    }
}
