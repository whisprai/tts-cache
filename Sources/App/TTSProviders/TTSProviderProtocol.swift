//
//  File.swift
//  
//
//  Created by Jonas on 29/10/2019.
//

import Foundation
import Vapor

protocol TTSProviderProtocol {
    
    var ffmpegFilterString: String? {get set}
    
    var defaultVoices: [String: String] {get}
    
    func speech(_ ttsRequest: TTSRequest, _ req: Request) throws -> Future<String>
    func getTTSRequestWithDefaults(ttsRequest: TTSRequest) throws -> TTSRequest
    func getFallbackProvider() -> TTSProviderProtocol
}

struct MissingApi : Error {}
