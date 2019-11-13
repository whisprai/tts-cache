//
//  AudioProcessingService.swift
//  App
//
//  Created by Jonas on 04/11/2019.
//
import Vapor
import Foundation

class AudioProcessingService {
    
    //https://cloud.ibm.com/apidocs/text-to-speech/text-to-speech?code=swift#synthesize-audio
    //https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize#AudioEncoding
    enum AudioExtension : String {
        case wav
        case mp3
        case ogg
        
        init(audioEncoding:String) throws {
            switch audioEncoding {
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
    
    static var ffmpegPath: String? = Environment.get("FFMPEG_PATH")
    
    init(){
        
        if(Environment.get("FFMPEG_FILTERS") == "true"){
            let task = Process()
            task.launchPath = AudioProcessingService.ffmpegPath!
            task.arguments = ["-filters"]
            task.launch()
        }
        
        if(AudioProcessingService.ffmpegPath == nil){
            do {
                AudioProcessingService.ffmpegPath = try getFFmpegPath()
            } catch {
                print("Error find ffmpeg path!")
            }
        }
    }
    
    //For macOS
    func getFFmpegPath() throws -> String {
        
        let ffmpegLibPath = "\(Environment.get("LIB_PATH")!)/ffmpeg"

        let versions = try FileManager.default.contentsOfDirectory(atPath: ffmpegLibPath)
        
        return "\(ffmpegLibPath)/\(versions[0])/bin/ffmpeg"
    }
    
    func getDataSize (_ data: Data) -> String{
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(data.count))
    }
       
    func process(req: Request, audioB64: String, ffmpegFilters: String?, fileExtension: AudioExtension = .mp3) throws -> Future<String> {
        let data = Data(base64Encoded: audioB64)!
        return try process(req: req, audio: data, ffmpegFilters: ffmpegFilters, fileExtension: fileExtension).flatMap({(data) -> EventLoopFuture<String> in
                       
            let base64 = data.base64EncodedString()
            return req.future(base64)
        })
    }
    
    func process(req: Request, audio: Data, ffmpegFilters: String?, fileExtension: AudioExtension = .mp3) throws -> Future<Data> {
        
        let fm = FileManager.default
           
        let initTimer = Timer()
        
        let id = UUID().uuidString
        let tmpPath = "/tmp/\(id).adat"
        let outPath = "/tmp/\(id)_out.\(fileExtension.rawValue)"
        
        fm.createFile(atPath: tmpPath, contents: audio)
        
        let addedAf = "\((ffmpegFilters != nil) ? "," : "")\(ffmpegFilters ?? "")"
        //let ffmpegAf = "silenceremove=start_periods=1:start_threshold=-60dB:detection=peak,areverse,silenceremove=start_periods=1:start_threshold=-60dB:detection=peak,areverse\(addedAf)"
        let ffmpegAf = "silenceremove=start_periods=1:start_threshold=-55dB,areverse,silenceremove=start_periods=1:start_threshold=-55dB,areverse\(addedAf)"
        
        let args = [
                    "-nostdin",
                    "-i", "\(tmpPath)",
                    "-af", ffmpegAf,
                    "-y",
                    "-hide_banner",
                    "-loglevel", Environment.get("FFMPEG_LOG") == "true" ? "info" : "panic",
                    "\(outPath)"
                    ]
        
        let promise = req.eventLoop.newPromise(Data.self)
        
        let task = Process()
        task.launchPath = AudioProcessingService.ffmpegPath!
        task.arguments = args
        
        task.terminationHandler = { (process) in
            
            let newData = fm.contents(atPath: outPath)!
            
            do {
                try fm.removeItem(atPath: tmpPath)
                try fm.removeItem(atPath: outPath)
            } catch {
                print("Error removing tmp files!")
            }
            
            if(Environment.get("FFMPEG_LOG") == "true"){
                initTimer.display("FFmpeg")
                
                let size = self.getDataSize(audio)
                let procData = self.getDataSize(newData)
                print("Audio size: \(size) -> \(procData)")
            }
            
            promise.succeed(result: newData)
        }
        
        task.launch()
        
        return promise.futureResult
    }
}

