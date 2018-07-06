import Fluent
import Foundation
import Vapor
import Authentication
import Validation

final class User: Content {
    

    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var email: String
    var password: String
    var name: String
    var lastName: String
    //Timestampable
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    public static var deletedAtKey: TimestampKey { return \.deletedAt }
    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }

    //DatabaseModel
    
    //BasicAuthenticatable
    public static var passwordKey: PasswordKey { return \.password }
    public static var usernameKey: UsernameKey { return \.email }

  
    //TokenAuthenticatable
    typealias TokenType = Token
    
    var tokens: Children<User, Token> {
        return children(\Token.userId)
    }
    
    var carts: Children<User, Cart> {
        return children(\Cart.userId)
    }
    
    var admins: Children<User, Admin> {
        return children(\Admin.userId)
    }
    var order: Children<User, Order> {
        return children(\Order.userId)
    }
    
    init(email: String, password: String, name: String, lastName: String) throws {
        self.email = email
        self.password = password
        self.name = name
        self.lastName = lastName
        self.id = try self.requireID()
        
    }
}

extension User: Migration {
    static func prepare(on connection: User.Database.Connection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.email)
        }
    }
}
extension User: DatabaseModel  {}
extension User: Parameter {}
extension User: BasicAuthenticatable {}
extension User: TokenAuthenticatable {}
extension User: SessionAuthenticatable {}

//extension User: Validatable {
//    static var validations: Validations = [
//        key(\.name): IsCount(1...) && IsAlphanumeric(),
//        key(\.lastName): IsCount(1...) && IsAlphanumeric(),
//        key(\.email): IsEmail(),
//        key(\.password): IsCount(8...) && IsASCII()
//    ]
//}

extension User: Validatable {
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.name, .count(1...) && .alphanumeric)
        try validations.add(\.lastName, .count(1...) && .alphanumeric)
        try validations.add(\.email, .email)
        try validations.add(\.password, .count(8...) && .ascii)
        return validations
    } }

