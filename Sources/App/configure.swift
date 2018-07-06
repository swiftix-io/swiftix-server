import Leaf
import Vapor
import Foundation
import Authentication
import FluentPostgreSQL

/// Called before your application initializes.

/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
    ) throws {
    
    User.defaultDatabase = .psql
    
    //Content Config
    var contentConfig = ContentConfig.default()
    let customEncoder = JSONEncoder()
    let customDecoder = JSONDecoder()
    customDecoder.keyDecodingStrategy = .convertFromSnakeCase
    customEncoder.keyEncodingStrategy = .convertToSnakeCase
    contentConfig.use(encoder: customEncoder, for: .json)
    contentConfig.use(decoder: customDecoder, for: .json)
    services.register(contentConfig)
    
    
    let router = EngineRouter.default()
    try Routes().boot(router: router)
    services.register(router, as: Router.self)
    
    
    //EngineServer config
    services.register(NIOServerConfig.default(
        hostname: constants.APP_URL,
        port: constants.APP_PORT,
        backlog: 256,
        workerCount: ProcessInfo.processInfo.activeProcessorCount,
        maxBodySize: 1_000_0000,
        reuseAddress: true,
        tcpNoDelay: true
    ))
    
    // register authentication
    try services.register(AuthenticationProvider())
  
    // register authentication

    
    // middleware config
    var middlewareConfig = MiddlewareConfig.default()
    middlewareConfig.use(SessionsMiddleware.self)
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
    middlewareConfig.use(FileMiddleware.self)

    services.register(middlewareConfig)
    
    // Leaf config
    try services.register(LeafProvider())
    config.prefer(LeafRenderer.self, for: TemplateRenderer.self)
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
        //Database config
        try services.register(FluentPostgreSQLProvider())
    var databaseConfig = DatabasesConfig()
    var db = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: constants.DATABASE_URL, port: constants.DATABASE_PORT, username: constants.DATABASE_USER, password: constants.DATABASE_PASSWORD))
    if constants.DATABASE_PASSWORD == nil { db = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: constants.DATABASE_URL, port: constants.DATABASE_PORT, username: constants.DATABASE_USER))}
        databaseConfig.add(database: db, as: .psql)
       // databaseConfig.enableLogging(on: .psql)
        services.register(databaseConfig)
    
    
    // migrations config
    var migrationConfig = MigrationConfig()
    migrationConfig.add(model: User.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Token.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Store.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Item.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Cart.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Image.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Product.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Order.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Ticket.self, database: User.defaultDatabase!)
    migrationConfig.add(model: CartProductPivot.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Checkout.self, database: User.defaultDatabase!)
    migrationConfig.add(model: Admin.self, database: User.defaultDatabase!)
    migrationConfig.add(model: CheckoutProductPivot.self, database: User.defaultDatabase!)
    migrationConfig.add(model: UserStorePivot.self, database: User.defaultDatabase!)
    services.register(migrationConfig)
}


