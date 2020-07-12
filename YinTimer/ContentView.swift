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


struct ContentView: View {
    @State var times: (Date, Date) = (Date(), Date.init(timeIntervalSinceNow: 5))
    
    @State var now: Date = Date()
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Path { path in
            let (start, stop) = times
            if now <= stop {
                let length = stop.distance(to: start)
                let progress = length / now.distance(to: stop)
                let pi = Double.pi
                let position: Double = pi - (2*pi / progress)
                let size = UIScreen.main.bounds.height
                let x = UIScreen.main.bounds.midX + CGFloat(sin(position)) * size
                let y = UIScreen.main.bounds.midY + CGFloat(cos(position)) * size
                path.move(to: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY))
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        .stroke(Color.white, lineWidth: 4)
        .onReceive(timer) { input in
            now = input
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(Rectangle().fill(Color.black)).foregroundColor(Color.white)
//        if times != nil {
//            return Clock()
//                .stroke(lineWidth: 8)
//                .frame(width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.height)
//                .foregroundColor(.purple)

//        }
//        else {
//            return VStack {
//                ForEach(presets.indices, id: \.self) { i in
//                    Button(action: {
//                        times = (
//                            Date.init(),
//                            Date.init(timeIntervalSinceNow: TimeInterval(60 * presets[i])))
//                    }) {
//                        Text("\(presets[i])m")
//                            .font(.system(size: 20))
//                    }
//                }
//            }
//        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: /*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
