import SwiftUI
import AVFoundation
import Combine
import MusicXML
import PianoKeyboard

class PlaybackManager: ObservableObject, PianoKeyboardDelegate {
    @Published var isPlaying = false
    @Published var tempo: Double = 120.0
    @Published var highlightedNotes: Set<Int> = []   // MIDI numbers only
    
    private var noteEvents: [NoteEvent] = []
    private var timer: Timer?
    private var startDate: Date?
    private let audioEngine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    
    init() {
        self.noteEvents = createDemoScore()
        setupAudio() // Start the engine!
    }
    
    private func setupAudio() {
        audioEngine.attach(sampler)
        audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
            // Optional: Load a default Apple piano sound bank if available
            // If this fails, it defaults to a basic sine wave synthesizer
        } catch {
            print("❌ Audio Engine failed to start: \(error.localizedDescription)")
        }
    }

    
    func loadMusicXML(from url: URL) {
            print("✅ MusicXML file selected: \(url.lastPathComponent)")
            print("   (Using demo song for now — full parser coming in next step)")
            // We keep the demo song so the keyboard works perfectly
        }
        
        private func parseScore(_ score: Score) -> [NoteEvent] {
            // Simplified — just return the demo song for now
            return createDemoScore()
        }
    
    func pianoKeyDown(_ keyNumber: Int) {
        sampler.startNote(UInt8(keyNumber), withVelocity: 80, onChannel: 0)
            // The user tapped a key on the screen!
            DispatchQueue.main.async {
                self.highlightedNotes.insert(keyNumber)
            }
        }
        
        func pianoKeyUp(_ keyNumber: Int) {
            sampler.stopNote(UInt8(keyNumber), onChannel: 0)
            // The user released a key on the screen!
            DispatchQueue.main.async {
                self.highlightedNotes.remove(keyNumber)
            }
        }
    
    private func pitchToMIDI(_ pitch: Pitch) -> Int {
        let stepMap: [Step: Int] = [.c: 0, .d: 2, .e: 4, .f: 5, .g: 7, .a: 9, .b: 11]
        let base = stepMap[pitch.step] ?? 0
        
        // Explicitly convert Double → Int
        let octaveOffset = Int(pitch.octave + 1) * 12
        let alter = Int(pitch.alter ?? 0)
        
        return octaveOffset + base + alter
    }
    
    
    // MARK: - Demo Song
    private func createDemoScore() -> [NoteEvent] {
        let beat = 60.0 / 120.0
        var events: [NoteEvent] = []
        var time: Double = 0.0
        
        let pattern: [(Int, Double)] = [
            (60, beat), (60, beat), (67, beat), (67, beat),
            (69, beat), (69, beat), (67, beat * 2),
            (65, beat), (65, beat), (64, beat), (64, beat),
            (62, beat), (62, beat), (60, beat * 2)
        ]
        
        for (midi, dur) in pattern {
            events.append(NoteEvent(pitch: midi, startTime: time, duration: dur))
            time += dur
        }
        return events
    }
    
    // MARK: - Playback
    func togglePlayback() {
        isPlaying ? stop() : start()
    }
    
    private func start() {
        isPlaying = true
        startDate = Date()
        highlightedNotes.removeAll()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startDate else { return }
            let elapsed = Date().timeIntervalSince(start) * (120.0 / self.tempo)
            
            DispatchQueue.main.async {
                var active: Set<Int> = []
                for event in self.noteEvents {
                    if elapsed >= event.startTime && elapsed < event.startTime + event.duration {
                        active.insert(event.pitch)
                    }
                }
                self.highlightedNotes = active
                active.forEach { x in self.pianoKeyDown(x) }
                
                if elapsed > (self.noteEvents.last?.startTime ?? 0) + 2.0 {
                    self.stop()
                }
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
        highlightedNotes.removeAll()
    }
}
