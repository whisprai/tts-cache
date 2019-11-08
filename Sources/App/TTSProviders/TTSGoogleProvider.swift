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
    
    let ttsAPIUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
    let headers = HTTPHeaders([
        ("X-Goog-Api-Key", Environment.get("GOOGLE_API_KEY")!),
        ("Content-Type", "application/json; charset=utf-8")
    ])
    
    func speech(_ ttsRequest: TTSRequest, _ req: Request) throws -> Future<String> {
       
        var newHttp = req.http
        newHttp.url = URL(string:ttsAPIUrl)!
        newHttp.headers = headers
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
}
