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
                
            PianoKeyboardView(
                viewModel: keyboardViewModel,
                style: ClassicStyle()
            )
            .frame(height: 300)
            .onAppear {
                // Tell the keyboard to send user taps to your playback manager
                keyboardViewModel.delegate = playback
            }
            
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
        .onChange(of: playback.highlightedNotes) { oldNotes, newNotes in
            // 1. Find which notes just started playing
            let notesToPress = newNotes.subtracting(oldNotes)
            
            // 2. Find which notes just finished playing
            let notesToRelease = oldNotes.subtracting(newNotes)
            
            // 3. Tell the ViewModel to press/release them!
            for note in notesToPress {
                keyboardViewModel.delegate?.pianoKeyDown(note)
            }
            
            for note in notesToRelease {
                keyboardViewModel.delegate?.pianoKeyUp(note)
            }
        }
    }
}
