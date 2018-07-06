import Async
import Fluent
import Foundation
import Fluent

final class UserStorePivot: ModifiablePivot {
    
    typealias ID = idType
    public static var idKey: IDKey { return \.id }
    var id: ID?
    var userId: User.ID
    var storeId: Store.ID
    
    typealias Left = User
    typealias Right = Store
    
    public static var leftIDKey: LeftIDKey { return \.userId }
    public static var rightIDKey: RightIDKey { return \.storeId }
    
    init(_ user: User, _ store: Store) throws {
        userId = try user.requireID()
        storeId = try store.requireID()
    }
}

extension UserStorePivot: DatabaseModel {
    
    static func prepare(on connection: UserStorePivot.Database.Connection) ->
        Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \UserStorePivot.userId, to: \User.id, onDelete: ._setNull)
                builder.reference(from: \UserStorePivot.storeId, to: \Store.id, onDelete: ._setNull)
            }
    }
}
extension UserStorePivot: Migration {}

