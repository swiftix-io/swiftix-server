import Vapor
import Foundation
import Fluent

struct StoreAdminMiddleware: Middleware {
    func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        do {
            
            guard let userId = try req.authenticatedSession(User.self) else {
                throw Abort(.badRequest, reason: "no user")
            }
            return UserStorePivot.query(on: req).filter(\UserStorePivot.userId == userId).all().flatMap(to: Response.self) { admin in
                
                if admin.count <= 0{
                    throw Abort(.badRequest, reason: "not authorized")
                }
                return try next.respond(to: req)
            }
            
        } catch {
            throw Abort(.badRequest, reason: "")
        }
    }
}
