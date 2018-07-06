import Fluent
import Foundation
import Vapor



final class Admin: Content {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    
    var id: ID?
    var userId: User.ID

    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey
    {
        case id = "id"
        case userId = "user_id"
        case createdAt = "created_At"
        case updatedAt = "updated_At"
    }

    public static var createdAtKey: TimestampKey { return \.createdAt }
    public static var updatedAtKey: TimestampKey { return \.updatedAt }

    
    var user: Parent<Admin, User> {
        return parent(\Admin.userId)
    }
    
    init(user: User) throws {
        self.userId = try user.requireID()
    }
}
extension Admin: Model{}
extension Admin: DatabaseModel {
    static func prepare(on connection: Admin.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in

                try addProperties(to: builder)
                builder.reference(from: \Admin.userId, to: \User.id, onDelete: ._setNull)
            }
    }
    
}
extension Admin: Migration {}
extension Admin: Parameter {}

