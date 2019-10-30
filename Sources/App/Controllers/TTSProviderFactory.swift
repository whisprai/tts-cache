//
//  File.swift
//  
//
//  Created by Jonas on 29/10/2019.
//

import Foundation


class TTSProviderFactory  {
    
    static func getTTSProvider(_ ttsRequest: TTSRequest) -> TTSProviderProtocol {
        switch (ttsRequest.voice.languageCode) {
            case "es":
                return TTSIBMProvider()
            default:
                return TTSGoogleProvider()
        }
    }
    
    static func getContentType(_ ttsRequest: TTSRequest) -> String {
        switch (ttsRequest.audioConfig.audioEncoding) {
            
        case "WAV":
            return "audio/wav"
        default:
            return "audio/mp3"
        }
    }
    
}
