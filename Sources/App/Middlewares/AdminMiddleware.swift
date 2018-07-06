import Vapor
import Fluent

struct AdminMiddleware: Middleware {
    func respond(to req: Request, chainingTo next: Responder) throws
        -> Future<Response> {
            do {
                return try tokenUser(req: req)
                    .flatMap(to: Response.self) { user in
                        guard let userId = user.id else {
                            throw Abort(.unauthorized)
                        }
                        return Admin.query(on: req)
                            .filter(\Admin.userId == userId)
                            .first().flatMap(to: Response.self) { admin in
                                guard let _ = admin else {
                                    throw Abort(.unauthorized)
                                }
                                return try next.respond(to: req)
                        }
                }
            } catch {
                throw Abort(.unauthorized)
            }
    }
}
