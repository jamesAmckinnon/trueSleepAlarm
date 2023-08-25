//
//  TrueSleep_AlarmApp.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-22.
//

import SwiftUI

@main
struct TrueSleep_Alarm_Watch_AppApp: App {
    @StateObject var sleepManager = SleepManager()
    @StateObject var extensionDelegate = ExtensionDelegate()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView{
                MainView()
            }
            .sheet(isPresented: $sleepManager.showingSummaryView){
                SummaryView()
            }
            .environmentObject(sleepManager)
            .environmentObject(extensionDelegate)
        }
        
//        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
