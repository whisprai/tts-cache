//
//  File.swift
//  
//
//  Created by Jonas on 29/10/2019.
//

import Foundation
import Vapor
import Redis

class TTSGoogleProvider: TTSProviderProtocol {

    var ffmpegFilterString: String?
    
    var defaultVoices = [
        "en-US":"en-US-Wavenet-D",
        "da":"da-DK-Wavenet-A",
        "es":"es-ES-Standard-A"
    ]
    
    let ttsAPIUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
    
    
    func speech(_ ttsRequest: TTSRequest, _ req: Request) throws -> Future<String> {
        
        let googleTtsReq = TTSRequest(voice: ttsRequest.voice,
                                      audioConfig: TTSRequestAudio(effectsProfileId: ["medium-bluetooth-speaker-class-device"], audioEncoding: ProviderUtils.getFetchEncoding()),
                                      input: ttsRequest.input)
        
        let json = try JSONEncoder().encode(googleTtsReq)
        
        guard let apiKey = Environment.get("GOOGLE_API_KEY") else { throw MissingApi() }
        let headers = HTTPHeaders([
            ("X-Goog-Api-Key", apiKey),
            ("Content-Type", "application/json; charset=utf-8")
        ])
        
        var newHttp = req.http
        newHttp.url = URL(string:ttsAPIUrl)!
        newHttp.headers = headers
        newHttp.body = HTTPBody(data: json)
        let newRequest = Request(http: newHttp, using: req.sharedContainer)
        
        let googleAPIRequest = try req.client().send(newRequest)
            .flatMap({ (googleResponse) -> (Future<[String : String]>) in
            try googleResponse.content.decode([String : String].self)
        })
        
        return googleAPIRequest.flatMap { jsonData in
            guard let response = jsonData["audioContent"] else { throw Abort(.badRequest, reason: "No audio received")}
            return req.future( response )
        }
    }
    
    func getTTSRequestWithDefaults(ttsRequest: TTSRequest) throws -> TTSRequest {
        var newTTSReq = ttsRequest;
        newTTSReq.voice.name = defaultVoices[ttsRequest.voice.languageCode]!
        return newTTSReq
    }
    
    func getFallbackProvider() -> TTSProviderProtocol {
        return TTSIBMProvider()
    }
}
