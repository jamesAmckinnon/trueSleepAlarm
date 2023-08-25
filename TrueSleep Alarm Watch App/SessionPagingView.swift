//
//  SessionPagingView.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-23.
//

import SwiftUI
import WatchKit

struct SessionPagingView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var sleepManager: SleepManager
    @State private var selection: Tab = .currentSleep
    
    enum Tab {
        case controls, currentSleep
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
            CurrentSleepView().tag(Tab.currentSleep)
        }
        .navigationTitle(sleepManager.selectedWorkout?.name ?? "")
        .navigationBarBackButtonHidden(true)
        .onChange(of: sleepManager.running) { _ in
            displayMetricsView()
        }
        .tabViewStyle(
            PageTabViewStyle(indexDisplayMode:
                                isLuminanceReduced ? .never : .automatic
            )
        )
        .onChange(of: isLuminanceReduced) {
            _ in displayMetricsView()
        }
    }
    private func displayMetricsView(){
        withAnimation {
            selection = .currentSleep
        }
    }
}

struct SessionPagingView_Previews: PreviewProvider {
    static var previews: some View {
        SessionPagingView()
    }
}
