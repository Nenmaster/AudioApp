//
//  AudioManager.swift
//  AudioApp
//
//  Created by Omar Mendivil on 11/6/25.
//

import Foundation
import AVFAudio

enum AudioError: Error {
    case unableToSetSession, unableToStop, unableToStoreRecording
}

class AudioManager: ObservableObject {
    var audioEngine: AVAudioEngine
    var audioFile: AVAudioFile?
    @Published var isRecording: Bool
    var recordingURL: URL?
    @Published var currentPower: Float = 0.0
    @Published var recordings: [URL] = []
    @Published var recordingPlayer : AVAudioPlayer?
    @Published var isCurrentlyPlaying: URL?
    
    init() {
        self.audioEngine = AVAudioEngine()
        self.audioFile = nil
        self.isRecording = false
        self.recordingURL = nil
    }

   
    func startSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        if await AVAudioApplication.requestRecordPermission() {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker] )
            try audioSession.setActive(true)
        } else {
            print("User Denied recording")
        }
    }
    
    func createEngine() {
        let inputNode = audioEngine.inputNode
        inputNode.inputFormat(forBus: 0)
        
        audioEngine.prepare()
    }
    
    func startRecording() throws {
        let fileURL = FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
    
        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)
        let format = input.inputFormat(forBus: 0)
        
        let file = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            try? file.write(from: buffer)
            let data = buffer.floatChannelData?[0]
            let frameLen = Int(buffer.frameLength)
            if let data = data {
                let rms = sqrt((0..<frameLen).reduce(0) { $0 + pow(data[$1],2)} / Float(frameLen))
                let avgPower = 20 * log10(rms)
                DispatchQueue.main.async {
                    self.currentPower = avgPower
                }
            }
        }
            
        self.audioFile = file
        self.recordingURL = fileURL
        
        try audioEngine.start()
        isRecording = true
        print("isRecording = \(isRecording)")
        print("recording started")
    }
    
    func loadRecording() throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
            self.recordings = files.filter { $0.pathExtension == "m4a" }
        } catch {
            throw AudioError.unableToStoreRecording
        }
        
    }
    
    func stopRecording() {
        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)
        
        audioEngine.stop()
        audioEngine.reset()
        isRecording = false
        audioFile = nil
        do {
            try loadRecording()
        } catch {
            print("Recoriding not load \(error)")
        }
        print("recording stopped")
        print("isRecordng = \(isRecording)")
    }
    
    func deleteRecording(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            try loadRecording()
        } catch {
            print("Failed to delete")
        }
    }
    
    func playRecording(url: URL) throws {
        if let player = recordingPlayer {
            if player.url != url || !FileManager.default.fileExists(atPath: url.path) {
                player.stop()
                recordingPlayer = nil
                isCurrentlyPlaying = nil
            }
        }
        
        if let player = recordingPlayer {
            if player.isPlaying {
                player.pause()
                isCurrentlyPlaying = nil
                return
            } else {
                player.play()
                isCurrentlyPlaying = url
                return
            }
        }
        
        do {
            recordingPlayer = try AVAudioPlayer(contentsOf: url)
            recordingPlayer?.prepareToPlay()
            recordingPlayer?.play()
            isCurrentlyPlaying = url
        } catch {
            print("play failed")
        }
        
    }
    
}

