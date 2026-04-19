import SwiftUI
import Combine
import MusicXML   // ← now we use the real parser

class PlaybackManager: ObservableObject {
    @Published var isPlaying = false
    @Published var tempo: Double = 120.0
    @Published var highlightedNotes: Set<Int> = []
    
    private var noteEvents: [NoteEvent] = []
    private var timer: Timer?
    private var startDate: Date?
    
    init() {
        self.noteEvents = createDemoScore()   // fallback demo
    }
    
    // MARK: - Real MusicXML Parser
    func loadMusicXML(from url: URL) {
        do {
            let score = try Score(url: url)
            self.noteEvents = parseScore(score)
            print("✅ Successfully parsed \(url.lastPathComponent) — \(noteEvents.count) notes loaded")
        } catch {
            print("❌ Failed to parse MusicXML: \(error.localizedDescription)")
        }
    }
    
    private func parseScore(_ score: Score) -> [NoteEvent] {
        var events: [NoteEvent] = []
        var currentTime: Double = 0.0
        
        // Use the first part only (most scores have one melody line for piano tutor)
        guard let part = score.parts.first else { return events }
        
        var divisions: Int = 1   // default
        
        for measure in part.measures {
            for element in measure.musicData {
                switch element {
                case .attributes(let attr):
                    if let div = attr.divisions {
                        divisions = div
                    }
                case .note(let note):
                    guard let pitch = note.pitch else { continue }   // skip rests
                    guard let durationDivisions = note.duration else { continue }
                    
                    let midi = pitchToMIDI(pitch)
                    let durationSeconds = Double(durationDivisions) / Double(divisions) * (60.0 / tempo)
                    
                    events.append(NoteEvent(
                        pitch: midi,
                        startTime: currentTime,
                        duration: durationSeconds
                    ))
                    
                    currentTime += durationSeconds
                default:
                    break
                }
            }
        }
        return events
    }
    
    private func pitchToMIDI(_ pitch: MusicXML.Pitch) -> Int {
        let stepMap: [MusicXML.Step: Int] = [.c: 0, .d: 2, .e: 4, .f: 5, .g: 7, .a: 9, .b: 11]
        let base = stepMap[pitch.step] ?? 0
        let midi = (pitch.octave + 1) * 12 + base + (pitch.alter ?? 0)
        return midi
    }
    
    // (keep the rest of your existing code: createDemoScore, togglePlayback, start, stop)
    private func createDemoScore() -> [NoteEvent] { ... }  // your existing demo code
    func togglePlayback() { ... }
    private func start() { ... }
    func stop() { ... }
}
