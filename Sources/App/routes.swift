import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    // Basic "Hello, world!" example
    router.get("environment") { req in
        return try Environment.detect().name
    }

    // Example of configuring a controller
    let speechController = SpeechController()
    router.post("speech", use: speechController.speech)
}
