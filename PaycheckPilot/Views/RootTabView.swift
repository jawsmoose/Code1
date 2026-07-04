import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Today", systemImage: "sparkles") }
            TransactionsView()
                .tabItem { Label("Activity", systemImage: "list.bullet.rectangle.portrait") }
            AccountsView()
                .tabItem { Label("Debts & Goals", systemImage: "creditcard") }
            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar.xaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .onAppear {
            SyncManager.shared.configureIfNeeded()
            PlanService.runDailyUpdateIfNeeded(in: context)
            DailyRefreshManager.schedule()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                PlanService.runDailyUpdateIfNeeded(in: context)
                DailyRefreshManager.schedule()
            }
        }
    }
}
