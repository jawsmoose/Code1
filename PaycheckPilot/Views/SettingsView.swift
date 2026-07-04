import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allSettings: [AppSettings]

    var body: some View {
        NavigationStack {
            Group {
                if let settings = allSettings.first {
                    SettingsForm(settings: settings)
                } else {
                    ProgressView()
                        .onAppear {
                            _ = PlanService.fetchOrCreateSettings(in: context)
                        }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct SettingsForm: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context
    @ObservedObject private var sync = SyncManager.shared
    @State private var showingEraseConfirm = false

    var body: some View {
        Form {
            paycheckSection
            strategySection
            splitSection
            guardrailSection
            syncSection
            dataSection
            aboutSection
        }
    }

    // MARK: - Sections

    private var paycheckSection: some View {
        Section {
            TextField("Take-home pay per check",
                      value: $settings.paycheckAmount,
                      format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
            Picker("Frequency", selection: $settings.payFrequencyRaw) {
                ForEach(PayFrequency.allCases) { frequency in
                    Text(frequency.displayName).tag(frequency.rawValue)
                }
            }
            Button("Recalculate my plan now") {
                PlanService.regeneratePlan(in: context)
            }
        } header: {
            Text("Paycheck")
        } footer: {
            Text("Leave the amount at $0 and the app estimates it from your imported payroll deposits. The plan also refreshes itself automatically every day.")
        }
    }

    private var strategySection: some View {
        Section {
            Picker("Payoff order", selection: $settings.payoffStrategyRaw) {
                ForEach(PayoffStrategy.allCases) { strategy in
                    Text(strategy.displayName).tag(strategy.rawValue)
                }
            }
        } header: {
            Text("Debt payoff strategy")
        } footer: {
            Text(settings.payoffStrategy.explanation)
        }
    }

    private var splitSection: some View {
        Section {
            weightSlider("Extra debt paydown", value: $settings.debtWeight)
            weightSlider("Savings goals", value: $settings.goalWeight)
            weightSlider("Investing", value: $settings.investWeight)
        } header: {
            Text("Free-dollar split")
        } footer: {
            Text("After essentials, minimum payments and guilt-free money, what's left gets split by these weights (normalized automatically). Categories that don't apply — no debts, no goals — pass their share to investing.")
        }
    }

    private var guardrailSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Trim fun spending")
                    Spacer()
                    Text("\(Int(settings.discretionaryTrimPercent))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $settings.discretionaryTrimPercent, in: 0...30, step: 5)
            }
        } header: {
            Text("Spending guardrail")
        } footer: {
            Text("Your guilt-free budget is set this far below your recent 90-day average, and the difference is redirected to debt, goals and investing.")
        }
    }

    private var syncSection: some View {
        Section {
            Toggle("Back up on every plan update", isOn: $settings.cloudSyncEnabled)
            Button("Back up now") {
                sync.syncNow(context: context)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Status")
                Text(sync.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Backup & cloud sync")
        } footer: {
            Text(sync.isFirebaseAvailable
                 ? "Backups are mirrored to your Cloud Firestore project."
                 : "The Firebase SDK isn't linked yet, so backups are written to a local JSON file in the app's Documents folder. See the README for the two-step Firestore setup.")
        }
    }

    private var dataSection: some View {
        Section {
            ShareLink("Export all data (JSON)", item: exportJSON())
            Button("Load sample data") {
                SampleData.populate(context: context)
                PlanService.regeneratePlan(in: context)
            }
            Button("Erase all data", role: .destructive) {
                showingEraseConfirm = true
            }
        } header: {
            Text("Data")
        }
        .confirmationDialog(
            "Erase everything?",
            isPresented: $showingEraseConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase All Data", role: .destructive) {
                eraseAll()
            }
        } message: {
            Text("This removes all transactions, accounts, goals and plans from this device. Backups are not deleted.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0")
        } footer: {
            Text("PaycheckPilot refreshes your allocation plan and daily savings tip every morning based on your latest spending. Informational only — not financial advice.")
        }
    }

    // MARK: - Helpers

    private func weightSlider(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(normalizedPercent(value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: 0...1, step: 0.05)
        }
    }

    private func normalizedPercent(_ value: Double) -> String {
        let sum = settings.debtWeight + settings.goalWeight + settings.investWeight
        guard sum > 0 else { return "0%" }
        return (value / sum).formatted(.percent.precision(.fractionLength(0)))
    }

    private func exportJSON() -> String {
        guard let data = try? BackupSnapshot.build(from: context).encoded(),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    private func eraseAll() {
        try? context.delete(model: BankTransaction.self)
        try? context.delete(model: FinancialAccount.self)
        try? context.delete(model: SavingsGoal.self)
        try? context.delete(model: AllocationLine.self)
        try? context.delete(model: AllocationPlan.self)
        try? context.save()
    }
}
