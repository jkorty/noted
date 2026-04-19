import SwiftUI
import Combine
import MusicXML

class PlaybackManager: ObservableObject {
    @Published var isPlaying = false
    @Published var tempo: Double = 120.0
    @Published var highlightedNotes: Set<Int> = []   // MIDI numbers only
    
    private var noteEvents: [NoteEvent] = []
    private var timer: Timer?
    private var startDate: Date?
    
    init() {
        self.noteEvents = createDemoScore()
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
    
    
    // MARK: - Real MusicXML Loading
//    func loadMusicXML(from url: URL) {
//        do {
//            let score = try Score(url: url)
//            self.noteEvents = parseScore(score)
//            print("✅ Loaded \(url.lastPathComponent) — \(noteEvents.count) notes ready")
//        } catch {
//            print("❌ Failed to parse MusicXML: \(error.localizedDescription)")
//        }
//    }
//    
//    private func parseScore(_ score: Score) -> [NoteEvent] {
//        var events: [NoteEvent] = []
//        var currentTime: Double = 0.0
//        
//        // ✅ Correct way to access the partwise score
//        guard case .partwise(let partwise) = score else { return events }
//        guard let part = partwise.parts.first else { return events }
//        
//        var divisions: Int = 1
//        
//        for measure in part.measures {
//            for element in measure.musicData {
//                switch element {
//                case .attributes(let attr):
//                    if let div = attr.divisions {
//                        divisions = div
//                    }
//                case .note(let note):
//                    guard let pitch = note.pitch, let durationDiv = note.duration else { continue }
//                    
//                    let midi = pitchToMIDI(pitch)
//                    let durationSeconds = Double(durationDiv) / Double(divisions) * (60.0 / tempo)
//                    
//                    events.append(NoteEvent(
//                        pitch: midi,
//                        startTime: currentTime,
//                        duration: durationSeconds
//                    ))
//                    currentTime += durationSeconds
//                default:
//                    break
//                }
//            }
//        }
//        return events
//    }

//    private func pitchToMIDI(_ pitch: Pitch) -> Int {   // ← no MusicXML. prefix
//        let stepMap: [Step: Int] = [.c: 0, .d: 2, .e: 4, .f: 5, .g: 7, .a: 9, .b: 11]
//        let base = stepMap[pitch.step] ?? 0
//        return (pitch.octave + 1) * 12 + base + (pitch.alter ?? 0)
//    }
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
