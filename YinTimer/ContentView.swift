//
//  ContentView.swift
//  YinTimer
//
//  Created by Anders Hovmöller on 2020-07-11.
//

import SwiftUI

let presets = [
    3,
    5,
    6,
]

let epoch = (Date.init(timeIntervalSince1970: 0), Date.init(timeIntervalSince1970: 0))


struct ContentView: View {
    @State var times: (Date, Date) = epoch
    
    @State var now: Date = Date()
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var clock: some View {
        VStack {
            Path { path in
                let (start, stop) = times
                if now <= stop {
                    let length = stop.distance(to: start)
                    let progress = length / now.distance(to: stop)
                    let pi = Double.pi
                    let position: Double = pi - (2*pi / progress)
                    let size = UIScreen.main.bounds.height
                    let offset: CGFloat = UIScreen.main.bounds.height * 0.075
                    let x = UIScreen.main.bounds.midX + CGFloat(sin(position)) * size
                    let y = UIScreen.main.bounds.midY + CGFloat(cos(position)) * size
                    path.move(
                        to: CGPoint(
                            x: UIScreen.main.bounds.midX,
                            y: UIScreen.main.bounds.midY - offset
                        )
                    )
                    path.addLine(to: CGPoint(x: x, y: y - offset))
                }
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap:.round))
            .onReceive(timer) { input in
                now = input
            }
            .background(Rectangle().fill(Color.black)).foregroundColor(Color.white)
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Spacer().frame(maxWidth: .infinity)
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
