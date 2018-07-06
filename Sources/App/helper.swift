import Vapor
import Fluent
import Foundation
import Authentication


//returns the user from token
func tokenUser(req: Request) throws -> Future<User> {
    guard let token = req.http.headers.bearerAuthorization?.token else {
        throw Abort(.badRequest, reason: "not authorized")
        
    }
    return Token.query(on: req).filter(\Token.token == token).first().flatMap(to: User.self) { token in
        
         guard let user = token?.authUser.get(on: req) else {
            throw Abort(.badRequest, reason: "")
        }
        return user
    }
}

