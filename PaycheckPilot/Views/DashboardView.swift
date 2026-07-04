import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \AllocationPlan.generatedAt, order: .reverse) private var plans: [AllocationPlan]
    @Query private var transactions: [BankTransaction]
    @Query private var accounts: [FinancialAccount]
    @Query(sort: \SavingsGoal.targetDate) private var goals: [SavingsGoal]

    private var plan: AllocationPlan? { plans.first }

    private var totalDebt: Double {
        accounts.filter { $0.kind.isDebt }.reduce(0) { $0 + $1.currentBalance }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let plan {
                        tipCard(plan)
                        planCard(plan)
                    } else {
                        EmptyStateView(
                            symbol: "wand.and.stars",
                            title: "Let's build your first plan",
                            message: "PaycheckPilot assigns a job to every dollar of your paycheck — bills, debt paydown, savings goals and investing.",
                            actionTitle: "Build My Plan") {
                                PlanService.regeneratePlan(in: context)
                            }
                            .card()
                    }
                    statsGrid
                    if transactions.isEmpty {
                        importHintCard
                    }
                    if !goals.isEmpty {
                        goalsCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        PlanService.regeneratePlan(in: context)
                    } label: {
                        Label("Refresh Plan", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }

    // MARK: - Plan card

    private func planCard(_ plan: AllocationPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Where your next paycheck goes")
                        .font(.headline)
                    Text("Updated \(plan.generatedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(plan.paycheckAmount.currency)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }
            ForEach(plan.sortedLines) { line in
                lineRow(line, total: plan.paycheckAmount)
            }
        }
        .card()
    }

    private func lineRow(_ line: AllocationLine, total: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: line.kind.symbol)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(line.kind.tint))
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.label)
                        .font(.subheadline.weight(.semibold))
                    Text(line.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(line.amount.currency)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            AllocationBar(fraction: total > 0 ? line.amount / total : 0, tint: line.kind.tint)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Tip card

    private func tipCard(_ plan: AllocationPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's money move", systemImage: "lightbulb.fill")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .opacity(0.9)
            Text(plan.tipTitle)
                .font(.headline)
            Text(plan.tipBody)
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [.indigo, .purple],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
        )
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(
                title: "Fun spending · 30d",
                value: InsightsEngine.discretionarySpend(transactions: transactions).wholeCurrency,
                symbol: "party.popper.fill",
                tint: .pink)
            StatTile(
                title: "Total debt",
                value: totalDebt.wholeCurrency,
                symbol: "creditcard.fill",
                tint: .orange)
            StatTile(
                title: "Savings rate · 30d",
                value: savingsRateText,
                symbol: "chart.line.uptrend.xyaxis",
                tint: .green)
            StatTile(
                title: "Saved for goals",
                value: goals.reduce(0) { $0 + $1.savedAmount }.wholeCurrency,
                symbol: "flag.checkered",
                tint: .purple)
        }
    }

    private var savingsRateText: String {
        guard let rate = InsightsEngine.savingsRate(transactions: transactions) else { return "—" }
        return rate.formatted(.percent.precision(.fractionLength(0)))
    }

    // MARK: - Extras

    private var importHintCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Personalize with real data")
                    .font(.subheadline.weight(.semibold))
                Text("Import bank & investment statements from the Activity tab, and the plan retrains on your actual habits.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings goals")
                .font(.headline)
            ForEach(goals) { goal in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(goal.name, systemImage: goal.iconName)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(goal.savedAmount.wholeCurrency) / \(goal.targetAmount.wholeCurrency)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    ProgressView(value: goal.progress)
                        .tint(.purple)
                }
            }
        }
        .card()
    }
}
