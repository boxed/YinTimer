//
//  ContentView.swift
//  YinTimer
//
//  Created by Anders Hovmöller on 2020-07-11.
//

import SwiftUI
import AVFoundation

let choices: [Int] = [Int](1...20) + stride(from: 25, to: 95, by: 5)

struct Song : Equatable {
    let fileURL: URL
    let symbol: String
}

let epoch = (Date.init(timeIntervalSince1970: 0), Date.init(timeIntervalSince1970: 0))

func readPresets() -> [Int] {
    UserDefaults.standard.register(defaults: ["presets": [3, 5, 6]])
    return UserDefaults.standard.object(forKey: "presets") as! [Int]
}

func savePresets(_ presets: [Int]) {
    UserDefaults.standard.setValue(presets, forKey: "presets")
}

func readSongs() -> [Song] {
    let fm = FileManager.default
    // TODO: do this in a queue! https://dev.to/nemecek_f/ios-saving-files-into-user-s-icloud-drive-using-filemanager-4kpm
    guard let driveURL = fm.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else { return []
    }
    
    do {
        try fm.createDirectory(at: driveURL, withIntermediateDirectories: true, attributes: nil)
        let howto = driveURL.appendingPathComponent("how to add songs.txt").path
        if !fm.fileExists(atPath: howto) {
            fm.createFile(atPath: howto, contents: """
            How to add songs to YinTimer
            ============================

            Add .mp3 files in this folder. Follow this pattern:

            01 ♫ anything you want.mp3
            02 🎸 anything you want.mp3

            The numbers in the front are for making the songs appear in the order you want in YinTimer. Then you should have a space, followed by a symbol that is shown on the button. This can be any text you want. Anything after that is ignored.
            """.data(using: .utf8), attributes: nil)
        }
        return try fm.contentsOfDirectory(at: driveURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles).sorted(by: {a, b in a.path < b.path }).map { url -> Song? in
            let filename = url.lastPathComponent
            if !filename.hasSuffix(".mp3") {
                return nil
            }
            let parts = filename.split(separator: " ", maxSplits: 1)
            if parts.count != 2 || parts[1].count < 1 {
                return nil
            }
            guard let symbol = String(parts[1]).first else { return nil }
            return Song(fileURL: url, symbol: String(symbol))
        }.compactMap { $0 }
    }
    catch {
        return []
    }
}

func clockPathInner(path: inout Path, bounds: CGRect, progress: TimeInterval) {
    let pi = Double.pi
    let position: Double = pi - (2*pi / progress)
    let size = bounds.height
    let offset: CGFloat = bounds.height * 0.070
    let x = bounds.midX + CGFloat(sin(position)) * size
    let y = bounds.midY + CGFloat(cos(position)) * size
    path.move(
        to: CGPoint(
            x: bounds.midX,
            y: bounds.midY - offset
        )
    )
    path.addLine(to: CGPoint(x: x, y: y - offset))

}

func clockPath(times: (Date, Date), now: Date, bounds: CGRect) -> Path {
    Path { path in
        let (start, stop) = times
        if now <= stop {
            let length = stop.distance(to: start)
            let progress = length / now.distance(to: stop)
            clockPathInner(path: &path, bounds: bounds, progress: progress)
        }
    }
}

struct ContentView: View {
    @State var times: (Date, Date) = epoch
    @State var now: Date = Date()
    @State var showSettings = false
    @State var presets = readPresets()
    @State var songs = readSongs()
    @State var player: AVAudioPlayer? = nil
    @State var currentSong: Song? = nil

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var clock: some View {
        VStack {
            clockPath(times: times, now: now, bounds: UIScreen.main.bounds)
            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap:.round))
            .onReceive(timer) { input in
                now = input
            }
            .background(Rectangle().fill(Color.black)).foregroundColor(Color.white)
        }
    }
    
    var settings: some View {
        HStack {
            Spacer().frame(maxWidth: .infinity)
            if showSettings {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack {
                        ForEach(choices, id: \.self) { choice in
                            Button(action: {
                                var s = Set<Int>.init(presets)
                                if !presets.contains(choice) {
                                    s.insert(choice)
                                }
                                else {
                                    s.remove(choice)
                                }
                                presets = s.sorted()
                                savePresets(presets)
                            }) {
                                Text("\(choice)")
                                .font(.system(size: 20))
                                .foregroundColor(presets.contains(choice) ? .white : .gray)
                            }.padding()
                        }
                    }
                }
            }
            else {
                ScrollView {}
            }
        }
    }
    
    var presetsButtons: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(presets.indices, id: \.self) { i in
                    Button(action: {
                        times = (
                            Date.init(),
                            Date.init(timeIntervalSinceNow: TimeInterval(60 * presets[i])))
                        UIApplication.shared.isIdleTimerDisabled = true
                    }) {
                        Text("\(presets[i])")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    }.padding()
                }
                Button(action: {
                    times = epoch
                })  {
                    Text("Stop")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                }.padding()
            }
        }
    }
  
    var songButtons: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(songs.indices, id: \.self) { i in
                    Button(action: {
                        // TODO: start/stop song
                        do {
                            if player != nil {
                                player?.stop()
                                player = nil
                                if songs[i] == currentSong {
                                    return
                                }
                            }
                            player = try AVAudioPlayer(contentsOf: songs[i].fileURL)
                            player?.prepareToPlay()
                            player?.numberOfLoops = -1
                            try AVAudioSession.sharedInstance().setCategory(.playback)
                            player?.play()
                            currentSong = songs[i]
                        }
                        catch {
                        }
                    }) {
                        Text("\(songs[i].symbol)")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .background(
                            Circle()
                            .strokeBorder()
                            .foregroundColor(player != nil && songs[i] == currentSong ? .purple : .white  )
                        )
                        // TODO: progress information for player
//                        .background(
//                            Path { path in
//                                if player != nil && songs[i] == currentSong {
//                                    if let currentTime = player?.currentTime, let duration = player?.duration {
//                                        clockPathInner(path: &path, bounds: path.boundingRect, progress: currentTime/duration)
//                                    }
//                                }
//                            }
//                        )
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Spacer().frame(maxWidth: .infinity)
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                }.padding().foregroundColor(.white)
            }
            settings
            presetsButtons
            songButtons
            Spacer().frame(maxHeight: 5)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(clock)
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
