//
//  File.swift
//  
//
//  Created by Jonas on 29/10/2019.
//

import Foundation


class TTSProviderFactory  {
    
    static func getTTSProvider(_ ttsRequest: TTSRequest) -> IttsProvider {
        switch (ttsRequest.voice.languageCode) {
            case "es":
                return ttsIBM()
            default:
                return ttsGoogle()
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
