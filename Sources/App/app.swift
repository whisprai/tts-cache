import Vapor

/// Creates an instance of `Application`. This is called from `main.swift` in the run target.
public func app(_ env: Environment) throws -> Application {
    var config = Config.default()
    var env = env
    var services = Services.default()
    try configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try boot(app)
    return app
}

/*
 Env:
 IBM_API_KEY
 GOOGLE_API_KEY
 
 REDIS_HOSTNAME
 REDIS_DATABASE
 REDIS_PORT
 REDIS_AUTH
 
 FFMPEG_PATH
 
 ENCODE_BITRATE: 32k
 AUDIO_FETCH_ENCODING: LINEAR16

 */
