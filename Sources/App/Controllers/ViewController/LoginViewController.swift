import Leaf
import Vapor
import Fluent
import Foundation
import Authentication
import Crypto

final class LoginViewController: RouteCollection {
    
    
    func boot(router: Router) throws {
        router.get("login", use: self.login)
        router.get("register", use: self.register)
        router.group("register") { register in
        register.post(User.self, use: self.postRegister)
        }
        
        router.post("login", use: self.postLogin)
        router.get("logout", use: self.logout)
        
        let sessionMiddleware = router.grouped(User.authSessionsMiddleware())
            sessionMiddleware.group("") { session in
            session.get("profile", use: self.profile)
        }
    }
    
    //##################################################################################################
    
    struct profileView: Codable {
        var activePage: String?
        var user: UserResponse?
    }
    
    //    ##################################################################################################
    func profile(_ req: Request) throws ->Future<View> {
        
        guard let user = try getUser(req) else {
            return try req.view().render("index")
        }
        return user.flatMap(to: View.self) { user in
            
            let context = profileView(activePage: "profile", user: user)
            
            return try req.view().render("profile", context)
        }
    }
    
    
    //    ##################################################################################################
    func login(_ req: Request) throws -> Future<Response> {

        if let _ = try getUser(req) {
            
            let redirect = req.redirect(to: "/")
            return try AnyResponse(redirect).encode(for: req)
        }else {
            return try req.view().render("login").encode(for: req)
        }
    }
    
    //##################################################################################################
    func register(_ req: Request) throws -> Future<View> {
        return try req.view().render("register")
    }
    
    //##################################################################################################
    func postLogin(_ req: Request) throws -> Future<Response> {
        
        struct login: Codable {
            var email: String
            var password: String
        }
        
        return try req.content.decode(login.self)
            .map(to: String.self) { login in
                return "\(login.email):\(login.password)".data(using: .utf8)!.base64EncodedString()
            }
            
            .flatMap(to: Response.self) { basicAuthString in
               
                return try req.make(Client.self).get("\(constants.BACKEND_HOST)" + "users/login",
                    headers: ["authorization: ": "Basic \(basicAuthString)"])
            }
            .flatMap(to: Response.self) { response in
                return response.http.body.consumeData(max: 100_000, on: req).map(to: Token.self) { data in
                    
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                    let token = try jsonDecoder.decode(Token.self, from: data)
                    
                    let session = try req.session()
                    session["token"] = token.token
                    return token
                    }.flatMap(to: User.self) { token in
                        
                        return User.find(token.userId, on: req).map(to: User.self) { user in
                            guard let user = user else {
                                throw Abort(.badRequest, reason: "no user")
                            }
                            try req.authenticateSession(user)
                            return user
                        }
                    }.flatMap(to: Response.self) { any in
                        let redirect = req.redirect(to: "/")
                        return try AnyResponse(redirect).encode(for: req)
                }
        }
    }
    

    
    //##################################################################################################
    //POST: register
    func postRegister(_ req: Request, user: User) throws -> Future<Response> {
        try user.validate()
        user.password = try BCrypt.hash(user.password, cost: 12)
        return user.save(on: req).flatMap(to: Response.self) { any in
            let redirect = req.redirect(to: "/")
            return try AnyResponse(redirect).encode(for: req)
        }
        
    }
    
    
    //##################################################################################################
    //GET: Logout
    func logout(_ req: Request) throws -> Future<Response> {
        
            try req.unauthenticateSession(User.self)
            try req.destroySession()
            _ = try req.session()
            let redirect = req.redirect(to: "/")
            return try AnyResponse(redirect).encode(for: req)
    }
}


//##################################################################################################

func getUser(_ req: Request) throws -> Future<UserResponse>? {
    
    guard let _ = try req.authenticatedSession(User.self) else {
        return nil
    }
    
    return try UserController().userStructResponse(req).map(to: UserResponse.self) { userResponse in
        
        return userResponse
    }
}




