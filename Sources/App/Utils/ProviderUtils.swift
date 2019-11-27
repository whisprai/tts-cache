//
//  ProviderUtils.swift
//  App
//
//  Created by Jonas on 27/11/2019.
//

import Vapor
import Foundation


class ProviderUtils {

    static func getFetchEncoding() -> String {
        return Environment.get("AUDIO_FETCH_ENCODING") ?? "MP3"
    }
}



//https://cloud.ibm.com/apidocs/text-to-speech/text-to-speech?code=swift#synthesize-audio
//https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize#AudioEncoding
enum AudioExtension : String {
    case wav
    case mp3
    case ogg
    
    init(audioEncoding:String) throws {
        let uppercasedEncoding = audioEncoding.uppercased()
        switch uppercasedEncoding {
        case "LINEAR16":
            self = .wav
        case "MP3":
            self = .mp3
        case "OGG_OPUS":
            self = .ogg
        default:
            throw Abort(.badRequest, reason:"extension not found for \(audioEncoding)")
        }
    }
    
    func getAcceptHeader() -> String {
        return "audio/\(self.rawValue)"
    }
}
