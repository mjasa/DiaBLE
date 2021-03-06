import Foundation
import SwiftUI


struct Graph: View {
    @EnvironmentObject var history: History
    @EnvironmentObject var settings: Settings


    func yMax() -> Double {
        let maxValues = [
            history.rawValues.map{$0.value}.max() ?? 0,
            history.factoryValues.map{$0.value}.max() ?? 0,
            history.values.map{$0.value}.max() ?? 0,
            Int(settings.targetHigh + 20)
        ]
        return Double(maxValues.max()!)
    }


    var body: some View {
        ZStack {

            // Glucose range rect in the background
            GeometryReader { geometry in
                Path() { path in
                    let width  = Double(geometry.size.width) - 60.0
                    let height = Double(geometry.size.height)
                    let yScale = (height - 20.0) / yMax()
                    path.addRect(CGRect(x: 1.0 + 30.0, y: height - settings.targetHigh * yScale + 1.0, width: width - 2.0, height: (settings.targetHigh - settings.targetLow) * yScale - 1.0))
                }.fill(Color.green).opacity(0.15)
            }

            // Target glucose low and high labels at the right
            GeometryReader { geometry in
                ZStack {
                    Text("\(settings.targetHigh.units)")
                        .position(x: CGFloat(Double(geometry.size.width) - 15.0), y: CGFloat(Double(geometry.size.height) - (Double(geometry.size.height) - 20.0) / yMax() * settings.targetHigh))
                    Text("\(settings.targetLow.units)")
                        .position(x: CGFloat(Double(geometry.size.width) - 15.0), y: CGFloat(Double(geometry.size.height) - (Double(geometry.size.height) - 20.0) / yMax() * settings.targetLow))
                    let count = history.rawValues.count
                    if count > 0 {
                        let hours = count / 4
                        let minutes = count % 4 * 15
                        Text((hours > 0 ? "\(hours) h\n" : "") + (minutes != 0 ? "\(minutes) min" : ""))
                            .position(x: 5.0, y: CGFloat(Double(geometry.size.height) - (Double(geometry.size.height)) / 2.0))
                    }
                }.font(.footnote).foregroundColor(.gray)
            }

            // Historic raw values
            GeometryReader { geometry in
                let count = history.rawValues.count
                if count > 0 {
                    Path() { path in
                        let width  = Double(geometry.size.width) - 60.0
                        let height = Double(geometry.size.height)
                        let v = history.rawValues.map{$0.value}
                        let yScale = (height - 20.0) / yMax()
                        let xScale = width / Double(count - 1)
                        var startingVoid = v[count - 1] < 1 ? true : false
                        if startingVoid == false { path.move(to: .init(x: 0.0 + 30.0, y: height - Double(v[count - 1]) * yScale)) }
                        for i in 1 ..< count {
                            if v[count - i - 1] > 0 {
                                let point = CGPoint(x: Double(i) * xScale + 30.0, y: height - Double(v[count - i - 1]) * yScale)
                                if startingVoid == false {
                                    path.addLine(to: point)
                                } else {
                                    startingVoid = false
                                    path.move(to: point)
                                }
                            }
                        }
                    }.stroke(Color.yellow).opacity(0.6)
                }
            }

            // Historic factory values
            GeometryReader { geometry in
                let count = history.factoryValues.count
                if count > 0 {
                    Path() { path in
                        let width  = Double(geometry.size.width) - 60.0
                        let height = Double(geometry.size.height)
                        let v = history.factoryValues.map{$0.value}
                        let yScale = (height - 20.0) / yMax()
                        let xScale = width / Double(count - 1)
                        var startingVoid = v[count - 1] < 1 ? true : false
                        if startingVoid == false { path.move(to: .init(x: 0.0 + 30.0, y: height - Double(v[count - 1]) * yScale)) }
                        for i in 1 ..< count {
                            if v[count - i - 1] > 0 {
                                let point = CGPoint(x: Double(i) * xScale + 30.0, y: height - Double(v[count - i - 1]) * yScale)
                                if startingVoid == false {
                                    path.addLine(to: point)
                                } else {
                                    startingVoid = false
                                    path.move(to: point)
                                }
                            }
                        }
                    }.stroke(Color.orange).opacity(0.75)
                }
            }


            // Frame and historic OOP values
            GeometryReader { geometry in
                Path() { path in
                    let width  = Double(geometry.size.width) - 60.0
                    let height = Double(geometry.size.height)
                    path.addRoundedRect(in: CGRect(x: 0.0 + 30, y: 0.0, width: width, height: height), cornerSize: CGSize(width: 8, height: 8))
                    let count = history.values.count
                    if count > 0 {
                        let v = history.values.map{$0.value}
                        let yScale = (height - 20.0) / yMax()
                        let xScale = width / Double(count - 1)
                        var startingVoid = v[count - 1] < 1 ? true : false
                        if startingVoid == false { path.move(to: .init(x: 0.0 + 30.0, y: height - Double(v[count - 1]) * yScale)) }
                        for i in 1 ..< count {
                            if v[count - i - 1] > 0 {
                                let point = CGPoint(x: Double(i) * xScale + 30.0, y: height - Double(v[count - i - 1]) * yScale)
                                if startingVoid == false {
                                    path.addLine(to: point)
                                } else {
                                    startingVoid = false
                                    path.move(to: point)
                                }
                            }
                        }
                    }
                }.stroke(Color.blue)
            }
        }
    }
}


struct Graph_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(AppState.test(tab: .monitor))
                .environmentObject(Log())
                .environmentObject(History.test)
                .environmentObject(Settings())
        }
    }
}
