import Foundation
import SwiftUI


struct Monitor: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var log: Log
    @EnvironmentObject var history: History
    @EnvironmentObject var settings: Settings

    @Environment(\.presentationMode) var presentationMode

    @State private var showingHamburgerMenu = false

    @State private var readingCountdown: Int = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {

        VStack(spacing: 0) {

            VStack(spacing: 0) {

                HStack {

                    VStack(spacing: 0) {
                        if app.lastReadingDate != Date.distantPast {
                            Text(app.lastReadingDate.shortTime)
                            Text("\(Int(Date().timeIntervalSince(app.lastReadingDate)/60)) min ago").font(.system(size: 10)).lineLimit(1)
                        } else {
                            Text("---")
                        }
                    }.font(.footnote).frame(maxWidth: .infinity, alignment: .trailing ).foregroundColor(Color(.lightGray))

                    Text(app.currentGlucose > 0 ? "\(app.currentGlucose.units)" : "---")
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .padding(.vertical, 10).padding(.horizontal, 10)
                        .background(app.currentGlucose > 0 && (app.currentGlucose > Int(settings.alarmHigh) || app.currentGlucose < Int(settings.alarmLow)) ?
                                        Color.red : app.currentGlucose < 0 ? Color.orange : Color.blue)
                        .cornerRadius(5)

                    // TODO
                    Group {
                        if app.trendDeltaMinutes > 0 {
                            HStack(spacing: 4) {
                                Text("\(app.trendDelta > 0 ? "+ " : app.trendDelta < 0 ? "- " : "")\(app.trendDelta == 0 ? "→" : abs(app.trendDelta).units)")
                                    .fontWeight(.black)
                                    .padding(.bottom, -20)
                                    .fixedSize()
                                Text("\(app.trendDeltaMinutes)m").font(.footnote).padding(.bottom, -20)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 0)
                        } else {
                            Text(LibreTrendArrow(rawValue: app.oopTrend)?.symbol ?? "---").font(.system(size: 28)).bold()
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 10).padding(.bottom, -18)
                        }
                    }.foregroundColor(app.currentGlucose > 0 && (app.currentGlucose > Int(settings.alarmHigh) && app.trendDelta > 0 || app.currentGlucose < Int(settings.alarmLow)) && app.trendDelta < 0 ?
                                        .red : app.currentGlucose < 0 ? .orange : .blue)

                }

                Text("\(app.oopAlarm.replacingOccurrences(of: "_", with: " ")) - \(app.oopTrend.replacingOccurrences(of: "_", with: " "))")
                    .font(.footnote).foregroundColor(.blue).lineLimit(1)

                HStack {
                    Text(app.deviceState)
                        .foregroundColor(app.deviceState == "Connected" ? .green : .red)
                        .font(.footnote).fixedSize()

                    if !app.deviceState.isEmpty && app.deviceState != "Disconnected" {
                        Text(readingCountdown > 0 || app.deviceState == "Reconnecting..." ?
                                "\(readingCountdown) s" : "")
                            .fixedSize()
                            .font(Font.footnote.monospacedDigit()).foregroundColor(.orange)
                            .onReceive(timer) { _ in
                                // workaround: watchOS fails converting the interval to an Int32
                                if app.lastReadingDate == Date.distantPast {
                                    readingCountdown = 0
                                } else {
                                    readingCountdown = settings.readingInterval * 60 - Int(Date().timeIntervalSince(app.lastReadingDate))
                                }
                            }
                    }
                }
            }


            Graph().frame(width: 31 * 4 + 60, height: 80)


            VStack(spacing: 0) {

                HStack(spacing: 2) {

                    if app.sensor != nil && (app.sensor.state != .unknown || app.sensor.serial != "") {
                        VStack(spacing: 0) {
                            Text(app.sensor.state.description)
                                .foregroundColor(app.sensor.state == .active ? .green : .red)

                            if app.sensor.age > 0 {
                                Text(app.sensor.age.shortFormattedInterval)
                            }
                        }
                    }

                    if app.device != nil {
                        VStack(spacing: 0) {
                            if app.device.battery > -1 {
                                Text("Battery: ").foregroundColor(Color(.lightGray)) +
                                    Text("\(app.device.battery)%").foregroundColor(app.device.battery > 10 ? .green : .red)
                            }
                            if app.device.rssi != 0  {
                                Text("RSSI: ").foregroundColor(Color(.lightGray)) +
                                    Text("\(app.device.rssi) dB")
                            }
                        }
                    }

                }.font(.footnote).foregroundColor(.yellow)

                Text(app.status.hasPrefix("Scanning") ? app.status : app.status.replacingOccurrences(of: "\n", with: " "))
                    .font(.footnote)
                    .lineLimit(app.status.hasPrefix("Scanning") ? 3 : 1)
                    .truncationMode(app.status.hasPrefix("Scanning") ?.tail : .head)
                    .frame(maxWidth: .infinity)

            }

            Spacer()
            
            HStack {
                Spacer()

                Button {
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left.circle.fill").resizable().frame(width: 16, height: 16).foregroundColor(.blue)
                }.frame(height: 16)

                Spacer()

                Button {
                    app.main.rescan()
                } label: {
                    Image(systemName: "arrow.clockwise.circle").resizable().frame(width: 16, height: 16).foregroundColor(.blue)
                }
                .frame(height: 16)

                if (app.status.hasPrefix("Scanning") || app.status.hasSuffix("retrying...")) && app.main.centralManager.state != .poweredOff {
                    Spacer()
                    Button {
                        app.main.centralManager.stopScan()
                        app.main.status("Stopped scanning")
                        app.main.log("Bluetooth: stopped scanning")
                    } label: {
                        Image(systemName: "stop.circle").resizable().frame(width: 16, height: 16).foregroundColor(.red)
                    }
                    .frame(height: 16)
                }

                Spacer()

                NavigationLink(destination: Details()) {
                    Image(systemName: "info.circle").resizable().frame(width: 16, height: 16).foregroundColor(.blue)
                }.frame(height: 16)
                Spacer()
            }
        }
        // .navigationTitle("Monitor")
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea([.bottom])
        .buttonStyle(PlainButtonStyle())
        .multilineTextAlignment(.center)
    }
}


struct Monitor_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            Monitor()
                .environmentObject(AppState.test(tab: .monitor))
                .environmentObject(Log())
                .environmentObject(History.test)
                .environmentObject(Settings())
        }
    }
}
