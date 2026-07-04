import Foundation
import SwiftData

/// Orchestrates the daily cycle: pulls the ledger, debts, goals and settings
/// out of SwiftData, runs the allocation engine and tips engine, and stores
/// the resulting plan. Called on launch, on foreground (once per day), from
/// the background refresh task, and whenever inputs change.
@MainActor
enum PlanService {

    static func fetchOrCreateSettings(in context: ModelContext) -> AppSettings {
        if let existing = (try? context.fetch(FetchDescriptor<AppSettings>()))?.first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }

    static func runDailyUpdateIfNeeded(in context: ModelContext, reference: Date = Date()) {
        let settings = fetchOrCreateSettings(in: context)
        let last = settings.lastDailyUpdate ?? .distantPast
        if !Calendar.current.isDate(last, inSameDayAs: reference) {
            regeneratePlan(in: context, reference: reference)
        }
    }

    static func regeneratePlan(in context: ModelContext, reference: Date = Date()) {
        let settings = fetchOrCreateSettings(in: context)
        let transactions = (try? context.fetch(FetchDescriptor<BankTransaction>())) ?? []
        let accounts = (try? context.fetch(FetchDescriptor<FinancialAccount>())) ?? []
        let goals = (try? context.fetch(FetchDescriptor<SavingsGoal>())) ?? []

        let debts = accounts.filter { $0.kind.isDebt && $0.currentBalance > 0 }
        let investments = accounts.filter { $0.kind == .investment }

        let paycheck = settings.paycheckAmount > 0
            ? settings.paycheckAmount
            : estimatePaycheck(from: transactions)

        let input = AllocationInput(
            paycheckAmount: paycheck,
            frequency: settings.payFrequency,
            transactions: transactions,
            debts: debts,
            investmentAccounts: investments,
            goals: goals,
            strategy: settings.payoffStrategy,
            debtWeight: settings.debtWeight,
            goalWeight: settings.goalWeight,
            investWeight: settings.investWeight,
            discretionaryTrim: min(0.5, max(0, settings.discretionaryTrimPercent / 100)),
            referenceDate: reference)

        let specs = AllocationEngine.buildPlan(input)
        guard !specs.isEmpty else { return }

        let tip = TipsEngine.tip(for: reference, transactions: transactions, debts: debts, goals: goals)

        let plan = AllocationPlan(
            generatedAt: reference,
            paycheckAmount: paycheck,
            tipTitle: tip.title,
            tipBody: tip.message)
        context.insert(plan)

        for (index, spec) in specs.enumerated() {
            let line = AllocationLine(
                label: spec.label,
                detail: spec.detail,
                amount: spec.amount,
                kind: spec.kind,
                sortOrder: index)
            line.plan = plan
            context.insert(line)
        }

        prunePlans(in: context, olderThanDays: 30, reference: reference)
        settings.lastDailyUpdate = reference
        try? context.save()

        SyncManager.shared.syncIfEnabled(context: context)
    }

    /// When the user hasn't set a paycheck amount, estimate it from the
    /// average of the most recent income deposits.
    static func estimatePaycheck(from transactions: [BankTransaction]) -> Double {
        let deposits = transactions
            .filter { $0.category == .income && $0.amount > 0 }
            .sorted { $0.date > $1.date }
            .prefix(6)
        guard !deposits.isEmpty else { return 2_000 }
        return (deposits.reduce(0) { $0 + $1.amount } / Double(deposits.count)).rounded()
    }

    private static func prunePlans(in context: ModelContext, olderThanDays days: Int, reference: Date) {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: reference) else { return }
        let plans = (try? context.fetch(FetchDescriptor<AllocationPlan>())) ?? []
        for plan in plans where plan.generatedAt < cutoff {
            context.delete(plan)
        }
    }
}
