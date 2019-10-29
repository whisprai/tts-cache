import Vapor
import Redis

final class speechController {
    
   
    func speech(_ req: Request) throws -> Future<VoiceResponse> {
        let ttsReq = try req.content.syncDecode(TTSRequest.self)
        
        let keyHash = hashFrom(ttsReq)
        
        return req.withNewConnection(to: .redis) { redis in
            return redis.get(keyHash, as: String.self)
                .flatMap({(cached) -> EventLoopFuture<VoiceResponse> in
                    if let cachedData = cached { return req.eventLoop.newSucceededFuture(result: VoiceResponse(data: cachedData, cached: true)) }
                    
                    let ttsProvider = TTSProviderFactory.getTTSProvider(ttsReq)
                    
                    return try ttsProvider.speech(ttsReq, req).flatMap { audio in
                        return redis.set(keyHash, to: audio).transform(to: VoiceResponse(data: audio, cached: false))
                    }
                })
        }
    }
    
    private func hashFrom(_ ttsReq: TTSRequest) -> String {
        var hasher = Hasher()
        hasher.combine(ttsReq.input.ssml)
        hasher.combine(ttsReq.voice.name)
        hasher.combine(ttsReq.voice.languageCode)
        hasher.combine(ttsReq.audioConfig.effectsProfileId)
        hasher.combine(ttsReq.audioConfig.audioEncoding)
        return String(hasher.finalize())
    }
}

struct VoiceResponse : Content {
    let data: String
    let cached:Bool
}

struct TTSResponse : Content {
    let data: String
    let cached:Bool
}

struct TTSRequest : Content {
    let voice: TTSRequestVoice
    let audioConfig: TTSRequestAudio
    let input: TTSRequestInput
}

struct TTSRequestVoice : Content {
    let name: String
    let languageCode: String
}

struct TTSRequestAudio :  Content {
    let effectsProfileId: String
    let audioEncoding: String
}

struct TTSRequestInput : Content {
    let ssml: String
}
