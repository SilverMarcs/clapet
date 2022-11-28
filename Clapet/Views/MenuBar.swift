import SwiftUI
import KeyboardShortcuts

struct MenuBar: Scene {
    
    private let timeFormatter: DateFormatter
    
    @ObservedObject
    private var inactivityService: InactivityService
    
    @ObservedObject
    private var sleepService: SleepService
    
    @AppStorage(StorageKeys.alreadySetup)
    private var alreadySetup: Bool = StorageDefaults.alreadySetup
    
    @AppStorage(StorageKeys.showMenuIcon)
    private var showMenuIcon: Bool = StorageDefaults.showMenuIcon
    
    @AppStorage(StorageKeys.sleepDurations)
    private var sleepDurations: [SleepDuration] = StorageDefaults.sleepDurations
    
    @State
    private var settingsOpen: Bool = false
    
    init(inactivityService: InactivityService, sleepService: SleepService) {
        self.inactivityService = inactivityService
        self.sleepService = sleepService
        
        self.timeFormatter = DateFormatter()
        self.timeFormatter.dateFormat = "HH:mm:ss"
    }
    
    var body: some Scene {
        let validDurations = sleepDurations.filter { $0.time != nil }
        
        MenuBarExtra("sleep-manager", systemImage: sleepService.enabled ? "laptopcomputer" : "lock.laptopcomputer", isInserted: $showMenuIcon) {
            VStack {
                Toggle(isOn: $sleepService.automatic.onChange(sleepService.toggleAutomaticMode)) {
                    Text("automatically-handle-sleep")
                }.disabled(!alreadySetup)
                
                if let until = sleepService.disabledUntil {
                    Text("sleep-status-disabled-until".localize(timeFormatter.string(from: until)))
                } else {
                    Text(sleepService.enabled ? "sleep-status-enabled" : "sleep-status-disabled")
                }
                
                Divider()
                
                Menu("disable-sleep") {
                    ForEach(validDurations) { duration in
                        Button(duration.display()) {
                            toggleClapet(true, delay: duration.time)
                        }.keyboardShortcut(KeyboardShortcuts.Name(duration.id.uuidString))
                    }
                    
                    Button("until-enabled") {
                        toggleClapet(true)
                    }.keyboardShortcut(.disableSleep)
                }.disabled(!alreadySetup)
                
                Button("enable-sleep") {
                    toggleClapet(false)
                }
                .keyboardShortcut(.enableSleep)
                .disabled(sleepService.enabled || !alreadySetup)
                
                Divider()
                
                Button("preferences") {
                    openSettings()
                }
                .keyboardShortcut("p")
                .disabled(!alreadySetup)
                
                Button("quit") {
                    NSApplication.shared.terminate(nil)
                }.keyboardShortcut("q")
            }
            .environmentObject(inactivityService)
            .environmentObject(sleepService)
        }
    }
    
    private func openSettings() {
        if settingsOpen {
            return
        }
        
        settingsOpen = true
        
        //add application to alt tab
        NSApp.setActivationPolicy(.regular)
        
        //bring application to front
        NSApp.activate(ignoringOtherApps: true)
        
        //open settings
        if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        
        //remove from alt tab when settings window when hidden
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
            let window = NSApp.windows.filter {
                $0.hasTitleBar && $0.title != "introduction".localize()
            }.last
            
            if let settings = window, !settings.isVisible {
                settingsOpen = false
                NSApp.setActivationPolicy(.prohibited)
                
                $0.invalidate()
            }
        }
    }
    
    func toggleClapet(_ clapet: Bool, delay: Int? = nil) {
        if let delay = delay {
            if clapet {
                sleepService.disableFor(delay)
            } else {
                fatalError("Invalid state : can not enable sleep with `for` parameter")
            }
        } else {
            if clapet {
                sleepService.disable()
            } else {
                sleepService.enable()
            }
        }
    }
    
}
