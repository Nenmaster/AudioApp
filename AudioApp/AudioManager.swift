//
//  AudioManager.swift
//  AudioApp
//
//  Created by Omar Mendivil on 11/6/25.
//

import Foundation
import AVFAudio

enum AudioError: Error {
    case unableToSetSession
}

class AudioManager {
    var audioEngine: AVAudioEngine
    var audioFile: AVAudioFile?
    var isRecording: Bool
    var recordingURL: URL?
    
    init() {
        self.audioEngine = AVAudioEngine()
        self.audioFile = nil
        self.isRecording = false
        self.recordingURL = nil
    }

   
    func startSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        if await AVAudioApplication.requestRecordPermission() {
            try audioSession.setCategory(.playAndRecord, mode: .default )
            try audioSession.setActive(true)
        } else {
            print("User Denied recording")
        }
    }
    
    func createEngine() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        audioEngine.prepare()
    }
    
    func startRecording() throws {
        let fileURL = FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
    
        let input = audioEngine.inputNode
        let format = input.inputFormat(forBus: 0)
        
        let file = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            try? file.write(from: buffer)
        }
        
        self.audioFile = file
        self.recordingURL = fileURL
        
        try audioEngine.start()
        isRecording = true
    }
}

