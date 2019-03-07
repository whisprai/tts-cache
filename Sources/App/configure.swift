import FluentSQLite
import Vapor
import Redis

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)
    
    // register Redis provider
    try services.register(RedisProvider())
    
    if env != .development {
        print(env)
        let hostname = Environment.get("REDIS_HOSTNAME") ?? ""
        let database = Environment.get("REDIS_DATABASE") ?? ""
        
        let redisUrlString = "redis://\(hostname):6379/\(database)"
        guard let redisUrl = URL(string: redisUrlString) else { throw Abort(.internalServerError) }
        let redisClientConfig = RedisClientConfig(url: redisUrl)
        
        services.register(redisClientConfig, as: RedisClientConfig.self)
    }
    
    // Configure migrations
//    var migrations = MigrationConfig()
//    migrations.add(model: Todo.self, database: .sqlite)
//    services.register(migrations)
}
