//
//  ControlsView.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-23.
//

import SwiftUI

struct ControlsView: View {
    // add workoutManager as an environment object so that this view can control the session
    @EnvironmentObject var sleepManager: SleepManager
    
    var body: some View {
        HStack {
            VStack {
                Button {
                    // call end workout on workout manager
                    sleepManager.endWorkout()
                } label: {
                    Image(systemName: "xmark")
                }
                .tint(Color.red)
                .font(.title2)
                Text("End")
            }
            VStack {
                Button {
                    sleepManager.togglePause()
                } label: {
                    Image(systemName: sleepManager.running
                          ? "pause" : "play"
                    )
                }
                .tint(Color.yellow)
                .font(.title2)
                Text(sleepManager.running ? "Pause" : "Resume")
            }
        }
    }
}


struct ControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ControlsView()
    }
}
