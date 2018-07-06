import Fluent
import Foundation
import Vapor
import Authentication

final class Token: Content, Authentication.Token {
    
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var token: String
    var userId: User.ID
    var expiry: Date
    
    //BearerAuthenticatable
    typealias UserType = User
    static var userIDKey: WritableKeyPath<Token, User.ID> { return \Token.userId }
    static var tokenKey: WritableKeyPath<Token, String> { return \Token.token }
    
    
    init(user: User) throws {
        self.token = constants.TOKEN_STRING
        self.userId = try user.requireID()
        
        self.expiry = Date().addingTimeInterval(86400)
    }
}

extension Token: DatabaseModel {}

extension Token: Migration {
    static func prepare(on connection: Token.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \Token.userId, to: \User.id, onDelete: ._setNull)
            }
    }
}
extension Token: BearerAuthenticatable {}


