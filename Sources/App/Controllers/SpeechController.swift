import Vapor
import Redis

let BYPASS_CACHED = true

final class SpeechController {
    
    struct TestError : Error { }
    
    var httpClient: Vapor.Client? = nil
   
    func speech(_ req: Request) throws -> Future<VoiceResponse> {
        
        var ttsReq = try req.content.syncDecode(TTSRequest.self)
        
        do {
            return try getAudio(req, ttsReq: ttsReq)
        } catch {
            let fallbackProvider = TTSProviderFactory.getTTSProvider(ttsReq).getFallbackProvider()
            ttsReq = try fallbackProvider.getTTSRequestWithDefaults(ttsRequest: ttsReq)
            return try getAudio(req, ttsReq: ttsReq, ttsProvider: fallbackProvider)
        }
    }
    
    func getAudio (_ req: Request, ttsReq: TTSRequest, ttsProvider: TTSProviderProtocol? = nil) throws -> Future<VoiceResponse> {
        
        if(httpClient == nil){
            httpClient = try req.client()
        }
        
        if(Environment.get("BYPASS_CACHED") == "true"){
            return try fetchAudio(req, ttsReq: ttsReq, ttsProvider: ttsProvider, client: httpClient!).flatMap { (audioB64) -> EventLoopFuture<VoiceResponse> in
                return req.future(VoiceResponse(data: audioB64, cached: false))
            }
        }
        
        let keyHash = hashFrom(ttsReq)
        
        return req.withNewConnection(to: .redis) { redis in
            return redis.get(keyHash, as: String.self)
                .flatMap({(cached) -> EventLoopFuture<VoiceResponse> in
                    if let cachedData = cached { return req.eventLoop.newSucceededFuture(result: VoiceResponse(data: cachedData, cached: true)) }
                    
                    return try self.fetchAudio(req, ttsReq: ttsReq, ttsProvider: ttsProvider, client: self.httpClient!).flatMap { (audioB64) -> EventLoopFuture<VoiceResponse> in
                        
                        return redis.set(keyHash, to: audioB64).transform(to: VoiceResponse(data: audioB64, cached: false))
                    }
                })
        }
    }
    
    func fetchAudio(_ req: Request, ttsReq: TTSRequest, ttsProvider: TTSProviderProtocol? = nil, client: Vapor.Client) throws -> Future<String> {
        
        let ttsProvider = ttsProvider ?? TTSProviderFactory.getTTSProvider(ttsReq)
        
        return try ttsProvider.speech(ttsReq, req).flatMap { audio in
        
            let fileExtension = try AudioProcessingService.AudioExtension(audioEncoding: ttsReq.audioConfig.audioEncoding.uppercased())
            
            return try AudioProcessingService().process(req: req, audioB64: audio, ffmpegFilters: ttsProvider.ffmpegFilterString, fileExtension: fileExtension)
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

struct TTSRequest : Content, Codable {
    var voice: TTSRequestVoice
    let audioConfig: TTSRequestAudio
    let input: TTSRequestInput
}

struct TTSRequestVoice : Content {
    var name: String
    var languageCode: String
}

struct TTSRequestAudio :  Content {
    let effectsProfileId: [String]
    let audioEncoding: String
}

struct TTSRequestInput : Content {
    let ssml: String
}
