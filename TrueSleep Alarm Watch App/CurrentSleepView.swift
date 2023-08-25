//
//  CurrentSleepView.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-23.
//

import SwiftUI

struct CurrentSleepView: View {
    @EnvironmentObject var sleepManager: SleepManager
    
    var body: some View {
        TimelineView(
            MetricsTimelineSchedule(
                from: sleepManager.builder?.startDate ?? Date()
            )
        ) { context in
            VStack(alignment: .leading){
                ElapsedTimeView(
                    elapsedTime: sleepManager.builder?.elapsedTime ?? 0,
                    // when cadence is live then subseconds are shown, else hidden in always
                    // on state
                    showSubseconds: context.cadence == .live
                ).foregroundColor(Color.yellow)
                Text(
                    Measurement(
                        value: sleepManager.activeEnergy,
                        unit: UnitEnergy.kilocalories
                    ).formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .workout
                        )
                    )
                )
                Text(
                    sleepManager.heartRate
                        .formatted(
                            .number.precision(.fractionLength(0))
                        )
                    + " bpm"
                )
                Text(
                    Measurement(
                        value: sleepManager.distance,
                        unit: UnitLength.meters
                    ).formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .road
                        )
                    )
                )
            }
            .font(.system(.title, design: .rounded)
                .monospacedDigit()
                .lowercaseSmallCaps()
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
        }
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentSleepView()
    }
}


// timeline view is a new-ish feature
// it updates over time, in line with a schedule
// timeline view makes our view aware of changes when it is in an always on state
// when the app is in the always on state it can update at most once every second
// this means that in the always on state the metrics view will hide subseconds

// this is a custom timeline schedule for our always on. It changes its interval based on
// the timeline schedule mode, dictated by the always on content.
private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    
    init(from startDate: Date) {
        self.startDate = startDate
    }
    
    // creates periodic timeline schedule entries
    // the function creates a periodic timeline schedule using the start date
    // the interval is determined by the timeline schedule mode
    func entries(from startDate: Date, mode: TimelineScheduleMode) ->
        PeriodicTimelineSchedule.Entries {
            PeriodicTimelineSchedule(
                from: self.startDate,
                // when mode is low frequency it is a one second interval
                // when normal it is 30 times per second
                by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
            ).entries(
                from: startDate,
                mode: mode
            )
    }
}
