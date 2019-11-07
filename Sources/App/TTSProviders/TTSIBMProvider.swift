//
//  File.swift
//  
//
//  Created by Jonas on 29/10/2019.
//

import Foundation
import Vapor
import Redis

class TTSIBMProvider: TTSProviderProtocol {
    
    var ffmpegFilterString: String? = "acompressor=ratio=6:attack=0.03:release=25:threshold=-19dB:knee=6dB:makeup=8dB:mix=1:detection=peak,equalizer=f=2000:g=3.85dB:w=1.14,equalizer=f=700:g=7dB:w=0.7"
    
    let defaultVoice = "es-ES_EnriqueV3Voice"
    
    let apiKey = Environment.get("IBM_API_KEY")!
    
    func getApiUrl (voiceName: String) -> String {
        return "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?voice=\(voiceName)"
    }
    
    func speech(_ ttsRequest: TTSRequest, _ req: Request) throws -> Future<String> {
        
        let url = getApiUrl(voiceName: defaultVoice) //ttsRequest.voice.name
        
        let authData = ("apiKey:\(apiKey)").data(using: String.Encoding.utf8)
        let auth_b64 = authData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        let authValue = "Basic \(auth_b64)"
        
        let headers = HTTPHeaders([
            ("Accept", "audio/mp3"),
            ("Content-Type", "application/json; charset=utf-8"),
            ("Authorization", authValue)
        ])
        
        var newHttp = req.http
        newHttp.method = HTTPMethod.POST;
        newHttp.url = URL(string:url)!
        newHttp.headers = headers
        
        let body = ReqBody(text: ttsRequest.input.ssml)
        let jsonData = try JSONEncoder().encode(body)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        newHttp.body = HTTPBody(string: jsonString)
        
        let newRequest = Request(http: newHttp, using: req.sharedContainer)
        
        return try req.client().send(newRequest)
            .flatMap({ (response) -> (Future<String>) in
                
                if(response.http.status.code != 200) {
                    let code = Int(response.http.status.code)
                    let reason = String(data: response.http.body.data!, encoding: String.Encoding.utf8);
                    throw Abort(HTTPResponseStatus(statusCode: code), reason: reason)
                }

                let data = response.http.body.data
                let base64 = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                return req.future( base64 )
        })
    }
    
    struct ReqBody: Codable {
        let text: String
    }
}
