//
//  TimePicker.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-23.
//

import SwiftUI

struct TimePicker: View {
   // Start timer at mid-day
    @State private var seconds: TimeInterval = 60 * 60 * 12

    static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()

    var body: some View {
        Text(Self.formatter.string(from: seconds)!)
            .font(.title)
            .digitalCrownRotation(
                $seconds, from: 0, through: 60 * 60 * 24 - 1, by: 60)
    }

}

struct TimePicker_Previews: PreviewProvider {
    static var previews: some View {
        TimePicker()
    }
}
