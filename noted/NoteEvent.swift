import Foundation

struct NoteEvent: Identifiable {
    let id = UUID()
    let pitch: Int          // MIDI note number
    let startTime: Double
    let duration: Double
}
