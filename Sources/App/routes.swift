import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return try Environment.detect().name
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.post("speech", use: todoController.speech)
}
