import Vapor
import Redis

final class TodoController {
    
    let ttsAPIUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
    let headers = HTTPHeaders([
            ("X-Goog-Api-Key", "AIzaSyC0vELi8Rl_92yiwCRum7Lhfj88hifzCNw"),
            ("Content-Type", "application/json; charset=utf-8")
    ])
    
    func speech(_ req: Request) throws -> Future<VoiceResponse> {
        let jsonBody = req.http.body.description
        
        var newHttp = req.http
        newHttp.url = URL(string:ttsAPIUrl)!
        newHttp.headers = headers
        let newRequest = Request(http: newHttp, using: req.sharedContainer)
        
        let googleAPIRequest = try req.client().send(newRequest)
            .flatMap({ (googleResponse) -> (Future<[String : String]>) in
            try googleResponse.content.decode([String : String].self)
        })
        var config = try req.make(RedisClientConfig.self)
        print(config)
        
        return req.withNewConnection(to: .redis) { redis in
            
            return redis.get(jsonBody, as: String.self)
                .flatMap({ (cached) -> EventLoopFuture<VoiceResponse> in
                    if let cachedData = cached { return req.eventLoop.newSucceededFuture(result: VoiceResponse(data: cachedData, cached: true)) }
                    return googleAPIRequest.flatMap { jsonData in
                        guard let audio = jsonData["audioContent"] else { throw Abort(.badRequest) }
                        return redis.set(jsonBody, to: audio).transform(to: VoiceResponse(data: audio, cached: false))
                    }
                })

        }
    }
    
    struct VoiceResponse : Content {
        let data: String
        let cached:Bool
    }
}
