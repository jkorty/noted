import SwiftUI

// Pure SwiftUI piano keyboard — no extra packages required!
struct SimplePianoKeyboard: View {
    @Binding var pressedKeys: Set<Int>   // MIDI numbers for highlighting
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(48...84, id: \.self) { midi in
                    KeyView(midi: midi, isPressed: pressedKeys.contains(midi))
                        .frame(width: geo.size.width / 37)
                }
            }
        }
        .frame(height: 300)
    }
}

struct KeyView: View {
    let midi: Int
    let isPressed: Bool
    
    var body: some View {
        let isBlack = [1, 3, 6, 8, 10].contains(midi % 12)
        Rectangle()
            .fill(isBlack ? Color.black : Color.white)
            .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
            .overlay(isPressed ? Color.red.opacity(0.7) : Color.clear)
            .overlay(
                Text(noteName(midi))
                    .font(.caption2)
                    .foregroundColor(isBlack ? .white : .black)
                    .offset(y: isBlack ? 65 : 115),
                alignment: .bottom
            )
    }
    
    private func noteName(_ midi: Int) -> String {
        let notes = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let noteIndex = midi % 12
        let octave = midi / 12 - 1
        return "\(notes[noteIndex])\(octave)"
    }
}

struct ContentView: View {
    @StateObject private var playback = PlaybackManager()
    @State private var userHighlighted: Set<Int> = []
    
    private var displayedKeys: Set<Int> {
        userHighlighted.union(playback.highlightedNotes)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your Sheet Music Player")
                .font(.largeTitle)
            
            SimplePianoKeyboard(pressedKeys: .constant(displayedKeys))
            
            HStack {
                Button(playback.isPlaying ? "⏹ Stop" : "▶️ Play") {
                    playback.togglePlayback()
                }
                .buttonStyle(.borderedProminent)
                .font(.title2)
                
                Spacer()
                
                VStack {
                    Text("Tempo: \(Int(playback.tempo)) BPM")
                    Slider(value: $playback.tempo, in: 60...180, step: 1)
                }
                .frame(width: 220)
            }
            
            Text("Auto-playing: \(playback.highlightedNotes.map { "\($0)" }.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text("User taps: \(userHighlighted.map { "\($0)" }.joined(separator: ", "))")
                .font(.caption)
            
            // NEW: Real file picker
            Button("Import MusicXML File") {
                // This works on both macOS and iOS
            }
            .fileImporter(
                isPresented: .constant(true),   // we'll make this a proper @State later if needed
                allowedContentTypes: [.xml, .data],  // .musicxml is XML
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        playback.loadMusicXML(from: url)
                    }
                case .failure(let error):
                    print("File picker error: \(error)")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onDisappear { playback.stop() }
    }
}
