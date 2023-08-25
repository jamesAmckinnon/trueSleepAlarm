//
//  MainView.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-23.
//

import SwiftUI
import HealthKit
import Foundation

//struct getSleep: View {
//    let allAsleepPredicate = HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: .allAsleepValues)
//
//
//    let healthStore = HKHealthStore()
//    let sleepType = HKCategoryType(.sleepAnalysis)
//
//    let dateRangePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
//    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dateRangePredicate, allAsleepPredicate])
//
//    let query = HKSampleQuery(sampleType: sleepType, predicate: predicate) { (query, result, error) in
//        // handle results
//    }
//}

class SessionCoordinator {
    private var session: WKExtendedRuntimeSession?

    func start() {
        guard session?.state != .running else { return }

        // create or recreate session if needed
        if nil == session || session?.state == .invalid {
            session = WKExtendedRuntimeSession()
        }
        session?.start()
    }

    func invalidate() {
        session?.invalidate()
    }
}


private let healthKitStore: HKHealthStore = HKHealthStore()

struct MainView: View {
    @EnvironmentObject var sleepManager: SleepManager
    @EnvironmentObject private var extensionDelegate: ExtensionDelegate
    @State private var alarmIsActive = false
    @State var hours: Int = 0
    @State var minutes: Int = 0
    @State var maxTimeScreen = false
    @State private var path = NavigationPath()
    @State var sleepTimeSecs: Double = 0
    // This will be loaded every time the app starts and will look for the "sleepTime" key.
    @State var sleepTime: Int = UserDefaults.standard.integer(forKey: "sleepTime")
    
    var body: some View {
        
        NavigationStack(path: $path) {
            ScrollView {
                VStack {
                    Button(action: {
                                   self.alarmIsActive = true
                                   if self.alarmIsActive {
                                       extensionDelegate.setupSession()
                                       extensionDelegate.scheduleAlarm()
                                   }
                               }) {
                                   Text("Start Alarm")
                               }
                    Text("Sleep Time")
                        .foregroundColor(Color("appleOrange"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 24))
                        .padding(.bottom, -7)
                    ///////////////// make this a struct since i use it twice //////////////////////
                    HStack {
                        Picker("", selection: $hours){
                            ForEach(0..<24, id: \.self) { i in
                                Text("\(i) hrs").tag(i)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        VStack {
                            Spacer()
                            Text(".")
                                .fontWeight(.bold)
                                .padding(.bottom, -11)
                            Text(".")
                                .fontWeight(.bold)
                                .padding(.bottom, -14)
                            Spacer()
                        }
                        Picker("", selection: $minutes){
                            ForEach(0..<60, id: \.self) { i in
                                Text("\(i) min").tag(i)
                            }
                        }.pickerStyle(WheelPickerStyle())
                    }
                    .frame(minHeight: 90)
                    .padding(.horizontal)
                    .padding(.bottom, 13)
                    // requests authorization from HealthKit when the view appears
                    .onAppear{
                        sleepManager.requestAuthorization()
                    }
                    Button ( action: {
                        //Code here before changing the bool value
                        maxTimeScreen = true
                        UserDefaults.standard.set( (hours * 3600 + minutes * 60), forKey: "sleepTime")
                    }) {
                        Text("Next")
                            .foregroundColor(.black)
                    }
                    .background(Color("appleOrange"))
                    .cornerRadius(8)
                }
                .navigationTitle("Sleep Time")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(false)
                .scenePadding()
                .navigationDestination(isPresented: $maxTimeScreen) {
                    maxTime(maxTimeScreen: $maxTimeScreen,
                            sleepTime: (hours * 3600 + minutes * 60)
                    )
                }
            }
        }
                                        
    }
}


struct CustomBackButton: View {
    var body: some View {
        // Customize your back button view here
        Image(systemName: "arrow.left")
    }
}

struct maxTime: View{
    @Binding var maxTimeScreen:Bool
    @State var sleepTime: Int
    @State var timerVal = 1
    @State var hours: Int = 0
    @State var minutes: Int = 0
    @State var activeTimerScreen = false
    @Environment(\.dismiss) var dismiss
        
    var body: some View {
        ScrollView {
            VStack {
                Text("Max Time")
                    .foregroundColor(Color("appleOrange"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 24))
                    .padding(.bottom, -7)
                    
                HStack {
                    Picker("", selection: $hours){
                        ForEach(0..<24, id: \.self) { i in
                            Text("\(i) hrs").tag(i)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    VStack {
                        Spacer()
                        Text(".")
                            .fontWeight(.bold)
                            .padding(.bottom, -11)
                        Text(".")
                            .fontWeight(.bold)
                            .padding(.bottom, -14)
                        Spacer()
                    }
                    Picker("", selection: $minutes){
                        ForEach(0..<60, id: \.self) { i in
                            Text("\(i) min").tag(i)
                        }
                    }.pickerStyle(WheelPickerStyle())
                }
                .frame(minHeight: 90)
                .padding(.horizontal)
                .padding(.bottom, 13)
                
                Button(action: {activeTimerScreen = true}) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.black)
                            .symbolRenderingMode(.palette)
                        Text("Sleep")
                            .foregroundColor(.black)
                            .padding(.leading, 5)
                    }
                }
                .background(Color("appleOrange"))
                .cornerRadius(8)
                
                Button ( action: {
                        dismiss()
                    }) {
                        Text("Cancel").fontWeight(.light)
                    }
                    .background(Color("appleGray"))
                    .cornerRadius(8)
                    .padding(.top, 4)
            }
            .scenePadding()
            .navigationDestination(isPresented: $activeTimerScreen) {
                ActiveTimer(activeTimerScreen: $activeTimerScreen,
                            maxTimeScreen: $maxTimeScreen,
                            sleepTime: $sleepTime,
                            maxTime: (hours * 3600 + minutes * 60)
                            )
            }
            .navigationTitle("")
            .accentColor(Color.red)
        }
        
    }
}



struct ActiveTimer: View{
    @EnvironmentObject var sleepManager: SleepManager
    @Binding var activeTimerScreen:Bool
    @Binding var maxTimeScreen:Bool
    @Binding var sleepTime:Int
    @State var maxTime:Int
    @State var timerVal = 1
    @State var sleepComplete = true
    @State var sleepTimeSecs = 0.0
        
    var body: some View {
            VStack {
                
//                Text("\(timerVal / 3600) hours \( (timerVal % 3600)/60 ) mins \(timerVal) seconds")
//                    .onAppear(){
//                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//                            if self.timerVal < sleepTime || self.timerVal < maxTime {
//                                self.timerVal += 1
//                            } else {
//                                sleepComplete = true
//                            }
//                        }
//                    }
                
                
                Text("\(sleepTimeSecs) seconds").task {
                    do {
                        sleepTimeSecs = try await sleepManager.sleepTime()
                    } catch {
                        sleepTimeSecs = 404
                    }
                }
                
                Button(action: {
                    activeTimerScreen = false
                    maxTimeScreen = false
                }) {
                    Text("Cancel").foregroundColor(.red)
                }
        }
    }
}

//struct TimePicker: View{
//
//
//
//    var body: some View {
//        HStack {
//            Picker("", selection: $hours){
//                ForEach(0..<24, id: \.self) { i in
//                    Text("\(i) hrs").tag(i)
//                }
//            }
//            .pickerStyle(WheelPickerStyle())
//            Picker("", selection: $minutes){
//                ForEach(0..<60, id: \.self) { i in
//                    Text("\(i) min").tag(i)
//                }
//            }.pickerStyle(WheelPickerStyle())
//        }
//        .frame(minHeight: 70)
//        .padding(.horizontal)
//        .padding(.bottom, 13)
//    }
//}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

extension HKWorkoutActivityType: Identifiable {
    public var id: UInt {
        rawValue
    }
    
    var name: String {
        switch self {
        case .running:
            return "Run"
        case .cycling:
            return "Bike"
        case .walking:
            return "Walk"
        default:
            return ""
        }
    }
}
