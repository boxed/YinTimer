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

func readSongsFromDir(url : URL) -> [Song] {
    do {
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]).sorted(by: {a, b in a.path < b.path }).map { url -> Song? in
            if !url.isFileURL {
                return nil
            }
            let filename = url.lastPathComponent
            if !filename.hasSuffix(".mp3") && !filename.hasSuffix(".m4a") {
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

func readSongs() -> [[Song]] {
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

            Add .mp3 or .m4a files in this folder. Follow this pattern:

            01 ♫ anything you want.mp3
            02 🎸 anything you want.mp3

            The numbers in the front are for making the songs appear in the order you want in YinTimer. Then you should have a space, followed by a symbol that is shown on the button. This can be any text you want. Anything after that is ignored.

            You can also add several rows of song buttons by creating directories with songs in them. The rules in these directories are the same as described above. The names of the directories can be anything but are sorted alphabetically and these lists come after the primary list of files directly in the YinTimer directory.
            """.data(using: .utf8), attributes: nil)
        }
        
        let subdirectory_songs = try FileManager.default.contentsOfDirectory(at: driveURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]).sorted(by: {a, b in a.path < b.path }).map { url -> [Song]? in
            if !url.hasDirectoryPath {
                return nil
            }

            let songs = readSongsFromDir(url: url)
            if songs.count == 0 {
                return nil
            }
            return songs
        }.compactMap { $0 }
        
        return [readSongsFromDir(url: driveURL)] + subdirectory_songs
    }
    catch {
        return []
    }
}

func clockPathInner(path: inout Path, bounds: CGRect, progress: TimeInterval, extraSize: CGFloat = 1) {
    let pi = Double.pi
    let position: Double
    if progress == 0 {
        position = 0
    }
    else {
        position = pi - (2*pi * progress)
    }
    let size = bounds.height / 2
    let offset: CGFloat = bounds.height * 0.070
    let x = bounds.midX + CGFloat(sin(position)) * size * extraSize
    let y = bounds.midY + CGFloat(cos(position)) * size * extraSize
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
            let length = start.distance(to: stop)
            let progress = start.distance(to: now) / length
            clockPathInner(path: &path, bounds: bounds, progress: progress, extraSize: 2)
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
    @State var activeButton: Int = -1

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
                        activeButton = i
                        times = (
                            Date.init(),
                            Date.init(timeIntervalSinceNow: TimeInterval(60 * presets[i])))
                        UIApplication.shared.isIdleTimerDisabled = true
                    }) {
                        Text("\(presets[i])")
                        .font(.system(size: 20))
                        .foregroundColor(activeButton == i ? .purple : .white)
                    }.padding()
                }
                Button(action: {
                    times = epoch
                    activeButton = -1
                })  {
                    Text("Stop")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                }.padding()
            }
        }
    }
    
    let songButtonSize: CGFloat = 50;
  
    var songButtons: some View {
        VStack {
            ForEach(songs.indices, id: \.self) { row_index in
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(songs[row_index].indices, id: \.self) { i in
                            Button(action: {
                                // TODO: start/stop song
                                do {
                                    if player != nil {
                                        player?.stop()
                                        player = nil
                                        if songs[row_index][i] == currentSong {
                                            return
                                        }
                                    }
                                    player = try AVAudioPlayer(contentsOf: songs[row_index][i].fileURL)
                                    player?.prepareToPlay()
                                    player?.numberOfLoops = -1
                                    try AVAudioSession.sharedInstance().setCategory(.playback)
                                    player?.play()
                                    currentSong = songs[row_index][i]
                                }
                                catch {
                                }
                            }) {
                                Text("\(songs[row_index][i].symbol)")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: songButtonSize, height: songButtonSize, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                .background(
                                    Circle()
                                    .strokeBorder()
                                    .foregroundColor(player != nil && songs[row_index][i] == currentSong ? .purple : .white  )
                                )
                                .background(
                                    Path { path in
                                        if player != nil && songs[row_index][i] == currentSong {
                                            if let currentTime = player?.currentTime, let duration = player?.duration {
                                                clockPathInner(path: &path, bounds: CGRect(x: 4, y: 7, width: songButtonSize - 8, height: songButtonSize - 8), progress: currentTime/duration)
                                            }
                                        }
                                    }.stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap:.round))
                                )
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
            }
        }
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
