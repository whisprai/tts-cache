import Vapor
import Redis

let BYPASS_CACHED = true

final class SpeechController {
    
   
    func speech(_ req: Request) throws -> Future<VoiceResponse> {
        let ttsReq = try req.content.syncDecode(TTSRequest.self)
        
        let keyHash = hashFrom(ttsReq)
        

        if(Environment.get("BYPASS_CACHED") == "true"){
            let ttsProvider = TTSProviderFactory.getTTSProvider(ttsReq)

            return try ttsProvider.speech(ttsReq, req).flatMap { audio in
                
                let fileExtension = try AudioProcessingService.AudioExtension(audioEncoding: ttsReq.audioConfig.audioEncoding.uppercased())
                
                return try AudioProcessingService().process(req: req, audioB64: audio, ffmpegFilters: ttsProvider.ffmpegFilterString, fileExtension: fileExtension).flatMap({(audioB64) -> EventLoopFuture<VoiceResponse> in
                        
                    return req.future(VoiceResponse(data: audioB64, cached: false))
                })
            }
        }
        
        return req.withNewConnection(to: .redis) { redis in
            return redis.get(keyHash, as: String.self)
                .flatMap({(cached) -> EventLoopFuture<VoiceResponse> in
                    if let cachedData = cached { return req.eventLoop.newSucceededFuture(result: VoiceResponse(data: cachedData, cached: true)) }
                    
                    let ttsProvider = TTSProviderFactory.getTTSProvider(ttsReq)
                    
                    return try ttsProvider.speech(ttsReq, req).flatMap { audio in
                        
                        let fileExtension = try AudioProcessingService.AudioExtension(audioEncoding: ttsReq.audioConfig.audioEncoding.uppercased())
                        
                        return try AudioProcessingService().process(req: req, audioB64: audio, ffmpegFilters: ttsProvider.ffmpegFilterString, fileExtension: fileExtension).flatMap({(audioB64) -> EventLoopFuture<VoiceResponse> in
                            
                            return redis.set(keyHash, to: audioB64).transform(to: VoiceResponse(data: audioB64, cached: false))
                        })
                    }
                })
        }
    }
    
    private func hashFrom(_ ttsReq: TTSRequest) -> String {
        let effectsProfile = ttsReq.audioConfig.effectsProfileId.joined()
        let combined = ttsReq.input.ssml+ttsReq.voice.name+ttsReq.voice.languageCode+effectsProfile+ttsReq.audioConfig.audioEncoding
        return String(combined.hashValue)
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
    let effectsProfileId: [String]
    let audioEncoding: String
}

struct TTSRequestInput : Content {
    let ssml: String
}
