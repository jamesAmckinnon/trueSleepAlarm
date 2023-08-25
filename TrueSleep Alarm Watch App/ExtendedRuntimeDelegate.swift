//
//  ExtendedRuntimeDelegate.swift
//  TrueSleep Alarm Watch App
//
//  Created by James McKinnon on 2023-07-31.
//

import WatchKit
import Foundation


class ExtensionDelegate: NSObject, ObservableObject, WKExtensionDelegate, WKExtendedRuntimeSessionDelegate {
    
    private var session: WKExtendedRuntimeSession!
    
    func setupSession() {
        session = WKExtendedRuntimeSession()
        session.delegate = self
        print("Session SetUp")
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Session Ended")
        return
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Session Started")
        var sleepTime = UserDefaults.standard.integer(forKey: "sleepTime")
        print("Sleep Time: \(sleepTime)")
        session.notifyUser(hapticType: WKHapticType.notification, repeatHandler: {_ in TimeInterval(2.0)})
        return
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Session Expired")
        return
    }
    
    func scheduleAlarm() {
        // This is just proof of concept code that triggers the alarm 2 seconds after pressing "Start Alarm". This would be replaced with the actual real-time alarm that our algorithm decides on
        session.start(at: Date() + TimeInterval(10))
    }
    
    func stopSession() {
        session.invalidate()
    }
}
