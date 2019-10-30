//
//  File.swift
//  
//
//  Created by Jonas on 29/10/2019.
//

import Foundation
import Vapor
import AVFoundation
import Redis

class ttsIBM: IttsProvider {
    
    let ttsAPIUrl = "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?voice="
    let apiKey = "ndHUMUN-WDu872AfMmVa_vcQDidclpqQRUgi3rk-KZpu"
    
    let defaultVoice = "es-ES_EnriqueV3Voice"
    
    func speech(_ ttsRequest: TTSRequest, _ req: Request) throws -> Future<String> {
        
        let url = ttsAPIUrl + defaultVoice //ttsRequest.voice.name
        
        let authData = ("apiKey:\(apiKey)").data(using: String.Encoding.utf8)
        let auth_b64 = authData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        let authValue = "Basic \(auth_b64)"
        
        let headers = HTTPHeaders([
            ("Accept", TTSProviderFactory.getContentType(ttsRequest)),
            ("Content-Type", "application/json; charset=utf-8"),
            ("Authorization", authValue)
        ])
        
        var newHttp = req.http
        newHttp.method = HTTPMethod.POST;
        newHttp.url = URL(string:url)!
        newHttp.headers = headers
        newHttp.body = HTTPBody(string: "{\"text\":\"\(ttsRequest.input.ssml)\"}")
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
}
