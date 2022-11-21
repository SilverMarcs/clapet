import SwiftUI
import ServiceManagement
import OSLog

struct GeneralSettings: View {
    
    private let logger = Logger()
    
    @EnvironmentObject
    private var inactivityService: InactivityService
    
    @AppStorage(StorageKeys.launchAtLogin)
    private var launchAtLogin: Bool = StorageDefaults.launchAtLogin
    
    @AppStorage(StorageKeys.showMenuIcon)
    private var showMenuIcon: Bool = StorageDefaults.showMenuIcon
    
    @AppStorage(StorageKeys.automaticSwitchNotification)
    private var automaticSwitchNotification: Bool = StorageDefaults.automaticSwitchNotification
    
    @AppStorage(StorageKeys.enableInactivityDelay)
    private var enableInactivityDelay: Bool = StorageDefaults.enableInactivityDelay
    
    @AppStorage(StorageKeys.inactivityDelay)
    private var inactivityDelay: Int = StorageDefaults.inactivityDelay
    
    var body: some View {
        ScrollView {
            Grid(horizontalSpacing: 30, verticalSpacing: 10) {
                GridRow(alignment: .top) {
                    Text("behavior")
                    VStack(alignment: .leading) {
                        Toggle(isOn: $launchAtLogin.onChange(self.onLaunchAtLoginChange)) {
                            Text("launch-at-login")
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $showMenuIcon) {
                            Text("menu-bar-icon")
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        Toggle(isOn: $automaticSwitchNotification) {
                            Text("automatic-notifications")
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Divider()
                GridRow(alignment: .top) {
                    Text("inactivity")
                    VStack(alignment: .leading) {
                        Toggle(isOn: $enableInactivityDelay) {
                            Text("enable-inactivity-delay")
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        NumberField("", value: $inactivityDelay.onChange {
                            inactivityService.setDelay(delay: $0)
                        })
                        .disabled(!enableInactivityDelay)
                        .frame(width: 100)
                        .padding(.top, 5)
                        
                        Text("inactivity-delay-description".localize(inactivityDelay)).asHint()
                    }
                }
            }
        }
        .frame(width: 390, height: 250)
        .padding(10)
    }
    
    func onLaunchAtLoginChange(launch: Bool) {
        do {
            if launch {
                if SMAppService.mainApp.status == .enabled {
                    try? SMAppService.mainApp.unregister()
                }
                
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Failed to \(launch ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            self.launchAtLogin = !launch
        }
    }
    
}
