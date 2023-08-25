//
//  SummaryView.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-23.
//

import SwiftUI
import HealthKit

struct SummaryView: View {
    @EnvironmentObject var sleepManager: SleepManager
    @Environment(\.dismiss) var dismiss
    @State private var durationFormatter:
        DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var body: some View {
        if sleepManager.workout == nil {
            ProgressView("Saving workout")
                .navigationBarHidden(true)
        } else {
            ScrollView(.vertical) {
                VStack(alignment: .leading){
                    SummaryMetricView(
                        title: "Total Time",
                        value: durationFormatter
                            .string(from:
                                        sleepManager.workout?
                                .duration ?? 0.0) ?? ""
                    ).accentColor(Color.yellow)
                    SummaryMetricView(
                        title: "Total Distance",
                        value: Measurement(
                            value: sleepManager.workout?.totalDistance?
                                .doubleValue(for: .meter()) ?? 0,
                            unit: UnitLength.meters
                        ).formatted(
                            .measurement(
                                width: .abbreviated,
                                usage: .road
                            )
                        )
                    ).accentColor(Color.green)
                    SummaryMetricView(
                        title: "Total Energy",
                        value: Measurement(
                            value: sleepManager.workout?
                                .totalEnergyBurned?
                                .doubleValue(for: .kilocalorie()) ?? 0,
                            unit: UnitEnergy.kilocalories
                        ).formatted(
                            .measurement(
                                width: .abbreviated,
                                usage: .workout
                            )
                        )
                    ).accentColor(Color.pink)
                    SummaryMetricView(
                        title: "Avg. Heart Rate",
                        value: sleepManager.averageHeartRate
                            .formatted(
                                .number.precision(
                                    .fractionLength(0)
                                )
                            )
                        + " bpm"
                    ).accentColor(Color.red)
                    Button("Done"){
                        dismiss()
                    }
                }
                .scenePadding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String
    
    var body: some View {
        Text(title)
        Text(value)
            .font(.system(.title2, design: .rounded)
                .lowercaseSmallCaps()
            )
            .foregroundColor(.accentColor)
        Divider()
    }
}
