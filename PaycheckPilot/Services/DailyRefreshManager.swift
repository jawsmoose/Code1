import Foundation
import BackgroundTasks
import SwiftData

/// Schedules an early-morning background refresh so the allocation plan and
/// daily tip are already updated when the app is opened. iOS decides the
/// exact run time (and the simulator never fires these), so
/// `PlanService.runDailyUpdateIfNeeded` also runs on every foreground as a
/// belt-and-suspenders fallback.
enum DailyRefreshManager {

    static let taskIdentifier = "com.jawsmoose.PaycheckPilot.dailyRefresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(refreshTask)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Aim for ~6am tomorrow; iOS treats this as "no earlier than".
        let startOfToday = Calendar.current.startOfDay(for: Date())
        request.earliestBeginDate = startOfToday.addingTimeInterval(30 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        schedule()

        let work = Task { @MainActor in
            let context = ModelContext(AppModelContainer.shared)
            PlanService.runDailyUpdateIfNeeded(in: context)
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
