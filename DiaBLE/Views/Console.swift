import Foundation
import SwiftUI


struct ConsoleTab: View {
    var body: some View {
        NavigationView {
            // Workaround to avoid top textfields scrolling offscreen in iOS 14
            GeometryReader { _ in
                Console()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct Console: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var log: Log
    @EnvironmentObject var settings: Settings

    @State private var showingNFCAlert: Bool = false
    @State private var showingFilterField: Bool = false
    @State private var filterString: String = ""

    var body: some View {
        VStack(spacing: 0) {

            if showingFilterField {
                HStack {
                    Image(systemName: "magnifyingglass").padding(.leading).foregroundColor(Color(.lightGray))
                    TextField("Filter", text: $filterString)
                        .autocapitalization(.none)
                        .padding(.vertical, 8)
                        .foregroundColor(Color.accentColor)
                    if filterString.count > 0 {
                        Button {
                            filterString = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill").padding(.trailing)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
            }

            HStack(spacing: 4) {

                ScrollView(showsIndicators: true) {
                    if filterString.isEmpty {
                        Text(log.text)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(4)
                    } else {
                        Text(log.text.split(separator: "\n").filter({$0.lowercased().contains(filterString.lowercased()
                        )}).joined(separator: ("\n \n")) + "\n")
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(4)
                    }
                }
                .font(.system(.footnote, design: .monospaced)).foregroundColor(Color(.lightGray))

                ConsoleSidebar(showingNFCAlert: $showingNFCAlert)
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Console")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ConsoleToolbar(showingNFCAlert: $showingNFCAlert,
                           showingFilterField: $showingFilterField,
                           filterString: $filterString)
            }
        }
        .alert(isPresented: $showingNFCAlert) {
            Alert(
                title: Text("NFC not supported"),
                message: Text("This device doesn't allow scanning the Libre."))
        }
    }
}


struct ConsoleSidebar: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var log: Log
    @EnvironmentObject var settings: Settings

    @Binding var showingNFCAlert: Bool

    @State private var readingCountdown: Int = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .center, spacing: 8) {

            Spacer()

            VStack(spacing: 0) {

                Button {
                    if app.main.nfc.isAvailable {
                        app.main.nfc.startSession()
                    } else {
                        showingNFCAlert = true
                    }
                } label: {
                    Image("NFC").renderingMode(.template).resizable().frame(width: 26, height: 18).padding(EdgeInsets(top: 10, leading: 6, bottom: 14, trailing: 0))
                }

                Button {
                    app.main.rescan()
                } label: {
                    VStack {
                        Image("Bluetooth").renderingMode(.template).resizable().frame(width: 32, height: 32)
                        Text("Scan")
                    }
                }
            }.foregroundColor(.accentColor)


            if (app.status.hasPrefix("Scanning") || app.status.hasSuffix("retrying...")) && app.main.centralManager.state != .poweredOff {
                Button {
                    app.main.centralManager.stopScan()
                    app.main.status("Stopped scanning")
                    app.main.log("Bluetooth: stopped scanning")
                } label: {
                    Image(systemName: "octagon").resizable().frame(width: 32, height: 32)
                        .overlay((Image(systemName: "hand.raised.fill").resizable().frame(width: 18, height: 18).offset(x: 1)))
                }.foregroundColor(.red)

            } else if app.deviceState == "Connected" || app.deviceState == "Reconnecting..." || app.status.hasSuffix("retrying...") {
                Button {
                    if app.device != nil {
                        app.main.centralManager.cancelPeripheralConnection(app.device.peripheral!)
                    }
                } label: {
                    Image(systemName: "escape").resizable().padding(5).frame(width: 32, height: 32)
                        .foregroundColor(.blue)
                }

            } else {
                Image(systemName: "octagon").resizable().frame(width: 32, height: 32)
                    .hidden()
            }

            if !app.deviceState.isEmpty && app.deviceState != "Disconnected" {
                Text(readingCountdown > 0 || app.deviceState == "Reconnecting..." ?
                        "\(readingCountdown) s" : "")
                    .fixedSize()
                    .font(Font.caption.monospacedDigit()).foregroundColor(.orange)
                    .onReceive(timer) { _ in
                        readingCountdown = settings.readingInterval * 60 - Int(Date().timeIntervalSince(app.lastReadingDate))
                    }
            } else {
                Text("").fixedSize().font(Font.caption.monospacedDigit()).hidden()
            }

            Spacer()

            Button {
                settings.debugLevel = 1 - settings.debugLevel
            } label: {
                VStack {
                    Image(systemName: settings.debugLevel == 0 ? "wrench.fill" : "ladybug").resizable().frame(width: 24, height: 24).offset(y: 2)
                    Text(settings.debugLevel == 1 ? "Devel" : "Basic").font(.caption).offset(y: -4)
                }
            }
            .background(settings.debugLevel == 1 ? Color.accentColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .foregroundColor(settings.debugLevel == 1 ? .black : .accentColor)
            .padding(.bottom, 6)

            VStack(spacing: 0) {

                Button {
                    UIPasteboard.general.string = log.text
                } label: {
                    VStack {
                        Image(systemName: "doc.on.doc").resizable().frame(width: 24, height: 24)
                        Text("Copy").offset(y: -6)
                    }
                }

                Button {
                    log.text = "Log cleared \(Date().local)\n"
                } label: {
                    VStack {
                        Image(systemName: "clear").resizable().frame(width: 24, height: 24)
                        Text("Clear").offset(y: -6)
                    }
                }

            }

            Button {
                settings.reversedLog.toggle()
                log.text = log.text.split(separator:"\n").reversed().joined(separator: "\n")
                if !settings.reversedLog { log.text.append(" \n") }
            } label: {
                VStack {
                    Image(systemName: "backward.fill").resizable().frame(width: 12, height: 12).offset(y: 5)
                    Text(" REV ").offset(y: -2)
                }
            }
            .background(settings.reversedLog ? Color.accentColor : Color.clear)
            .border(Color.accentColor, width: 3)
            .cornerRadius(5)
            .foregroundColor(settings.reversedLog ? .black : .accentColor)


            Button {
                settings.logging.toggle()
                app.main.log("\(settings.logging ? "Log started" : "Log stopped") \(Date().local)")
            } label: {
                VStack {
                    Image(systemName: settings.logging ? "stop.circle" : "play.circle").resizable().frame(width: 32, height: 32)
                }
            }.foregroundColor(settings.logging ? .red : .green)

            Spacer()

        }.font(.footnote)
    }
}


struct ConsoleToolbar: View {
    @EnvironmentObject var app: AppState

    @Binding var showingNFCAlert: Bool
    @Binding var showingFilterField: Bool
    @Binding var filterString: String

    @State var showingUnlockAlert: Bool = false

    var body: some View {
        HStack(alignment: .bottom) {

            Button {
                withAnimation { showingFilterField.toggle() }
            } label: {
                VStack(spacing: 0) {
                    Image(systemName: filterString.isEmpty ? "line.horizontal.3.decrease.circle" : "line.horizontal.3.decrease.circle.fill").font(.title2)
                    Text("Filter").font(.footnote)
                }
            }

            Menu {

                Button {
                    if app.main.nfc.isAvailable {
                        app.main.settings.logging = true
                        app.main.nfc.taskRequest = .enableStreaming
                    } else {
                        showingNFCAlert = true
                    }
                } label: {
                    Label {
                        Text("RePair Streaming")
                    } icon: {
                        Image("NFC").renderingMode(.template).resizable().frame(width: 26, height: 18)
                    }
                }

                Button {
                    if app.main.nfc.isAvailable {
                        app.main.settings.logging = true
                        app.main.nfc.taskRequest = .readFRAM
                    } else {
                        showingNFCAlert = true
                    }
                } label: {
                    Label("Read FRAM", systemImage: "memorychip")
                }

                Button {
                    if app.main.nfc.isAvailable {
                        app.main.settings.logging = true
                        showingUnlockAlert = true
                    } else {
                        showingNFCAlert = true
                    }
                } label: {
                    Label("Unlock", systemImage: "lock.open")
                }

                Button {
                    if app.main.nfc.isAvailable {
                        app.main.settings.logging = true
                        app.main.nfc.taskRequest = .dump
                    } else {
                        showingNFCAlert = true
                    }
                } label: {
                    Label("Dump Memory", systemImage: "cpu")
                }


            } label: {
                Label {
                    Text("Tools")
                } icon: {
                    VStack(spacing: 0) {
                        Image(systemName: "wrench.and.screwdriver").font(.title3)
                        Text("Tools").font(.footnote).fixedSize()
                    }
                }
            }
        }
        .alert(isPresented: $showingUnlockAlert) {
            Alert(
                title: Text("Confirm to unlock"),
                message: Text("Unlocking the Libre 2 is not reversible and will make it unreadable by LibreLink and other apps."),
                primaryButton: .cancel(),
                secondaryButton: .destructive(Text("Unlock")) {
                    app.main.nfc.taskRequest = .unlock
                }
            )
        }
    }
}


struct Console_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(AppState.test(tab: .console))
                .environmentObject(Log())
                .environmentObject(History.test)
                .environmentObject(Settings())
        }
    }
}
