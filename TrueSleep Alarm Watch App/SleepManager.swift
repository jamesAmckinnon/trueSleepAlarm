//
//  SleepManager.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-23.
//

import Foundation
import HealthKit


// sleep manager will expose public workout metrics that metrics view and summary view can observe
class SleepManager: NSObject, ObservableObject {
    
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            // only call startWorkout when selectedWorkout is not nil, it can be nil
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkout(workoutType: selectedWorkout)
        }
    }
    
    @Published var showingSummaryView: Bool = false {
        didSet {
            // sheet dismissed
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        // diff workout types will have different qualities. Eg. outdoor bike will have location data, indoor bike will not
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore,
                                           configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            return
        }
        
        // an HKLiveWorkoutDataSource provides live data from the active workout session *******
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        // assign workout manager as the HK workout session deligate
        session?.delegate = self
        session?.delegate = self
        
        // Start the workout and begin data collection
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (succes, error) in
            // the workout has started and we have begun data collection
        }
    }
    
    // function to request authorization for our app to read and share any health data our app intends to use
    func requestAuthorization() {
        // The quantity type to write to the health store
        let typesToShare: Set = [
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!,
            HKQuantityType.workoutType()
        ]
        
        // read datatypes automatically recorded by apple watch as part of the session
        let typesToRead: Set = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
//            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
//            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        { (success, error) in
            
        }
    }
    // the workout session state.
    // a public variable that tracks if the session is running
    @Published var running = false
    
    func pause() {
        session?.pause()
    }
    
    func resume() {
        session?.resume()
    }
    
    func togglePause() {
        if running == true {
            pause()
        } else {
            resume()
        }
    }
    
    func endWorkout() {
        session?.end()
        showingSummaryView = true
    }
    
    // add the published workout variables
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?
    
    @Published var sleep: Double = 0
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
                HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default:
                return
            }
        }
    }
    
    // When the summary view dismisses we need to reset our model
    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        session = nil
        workout = nil
        activeEnergy = 0
        averageHeartRate = 0
        heartRate = 0
        distance = 0
    }
    
    func sleepTime() async throws -> Double{
        let startDate = Date().addingTimeInterval( -(86400) )
        let endDate = Date()
        
        // Define the type.
        let sleepType = HKCategoryType(.sleepAnalysis)
        
        let dateRangePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let allAsleepValuesPredicate = HKCategoryValueSleepAnalysis
            .predicateForSamples(equalTo:HKCategoryValueSleepAnalysis.allAsleepValues)
        
        // Combines two predicates with AND. Here it combines dateRangePredicate and allAsleepValuesPredicate:
        // (
        //   endDate >= CAST(712849305.401525, "NSDate") AND endDate < CAST(712892505.401525, "NSDate")
        //   AND
        //   startDate < CAST(712892505.401525, "NSDate") AND offsetFromStartDate >= CAST(712849305.401525, "NSDate")
        // )
        //   AND
        // (
        //   value == 5 OR value == 4 OR value == 1 OR value == 3
        // )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dateRangePredicate, allAsleepValuesPredicate])
        
        // Returns a snapshot of all matching samples in the HealthKit store.
        let descriptor = HKSampleQueryDescriptor(
            // A predicate is a logical condition that evaluates to a Boolean value.
            // It can be used to filter a collection of objects.
            predicates: [.categorySample(type: sleepType, predicate: compoundPredicate)],
            sortDescriptors: []
        )
        
        do {
            let results = try await descriptor.result(for: healthStore)
            var secondsAsleep = 0.0
            for result in results {
                // timeIntervalSince returns the interval between this date and another given date.
                // This looks at each time window of an asleep category and gets the difference between the start
                // and end time of that window in seconds and then adds that to the secondsAsleep variable.
                secondsAsleep += result.endDate.timeIntervalSince(result.startDate)
            }
        
            self.sleep = secondsAsleep
            return secondsAsleep
            
        } catch{
            return 0.0
        }
        
    }
    
}

extension SleepManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState:
                        HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }
        
        // wait for the session to transition state before ending the builder
        // when the session transitions to ended call end collections on the builder
        // to stop collecting workout samples
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                // finishWorkout will save the HK workout to the health database
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

// workout manager needs to observe workout samples added to the builder by being an HKLive workout builder deligate
extension SleepManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder){
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            // Update the published metric values.
            updateForStatistics(statistics)
        }
    }
}
