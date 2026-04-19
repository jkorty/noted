import SwiftUI
import PianoKeyboard   // ← the nice keyboard we just added

struct ContentView: View {
    @StateObject private var playback = PlaybackManager()
    @State private var userHighlighted: Set<Int> = []   // only for taps
        
    // Add the real keyboard ViewModel
    @State private var keyboardViewModel = PianoKeyboardViewModel()
    
    // Merge user taps + auto-playing notes
    private var displayedKeys: Set<Int> {
        userHighlighted.union(playback.highlightedNotes)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your Sheet Music Player")
                .font(.largeTitle)
            
            // ✅ Real nice piano keyboard with external highlighting
//            PianoKeyboard.PianoKeyboardDelegate(
//                            lowestKey: 48,                  // C3
//                            highestKey: 84,                 // C6
//                            pressedKeys: .constant(displayedKeys),   // auto + user highlights
//                            noteOn: { midiNote in
//                                userHighlighted.insert(midiNote)
//                            },
//                            noteOff: { midiNote in
//                                userHighlighted.remove(midiNote)
//                            }
//                        )
            PianoKeyboardView(
                viewModel: keyboardViewModel,
                style: ClassicStyle()
            )
            .frame(height: 300)
            
            
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
            
            Button("Import MusicXML File") {
                // We'll hook up the real picker in the next message if you want
                print("File picker coming next...")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onDisappear { playback.stop() }
    }
}
