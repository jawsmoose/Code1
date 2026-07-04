import SwiftUI
import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            FinancialAccount.self,
            BankTransaction.self,
            SavingsGoal.self,
            AllocationPlan.self,
            AllocationLine.self,
            AppSettings.self,
        ])
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()
}

@main
struct PaycheckPilotApp: App {

    init() {
        DailyRefreshManager.register()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
