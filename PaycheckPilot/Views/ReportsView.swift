import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query private var transactions: [BankTransaction]
    @Query private var accounts: [FinancialAccount]
    @Query(sort: \SavingsGoal.targetDate) private var goals: [SavingsGoal]
    @Query(sort: \AllocationPlan.generatedAt, order: .reverse) private var plans: [AllocationPlan]

    private var monthly: [MonthlySpend] {
        InsightsEngine.monthlySpending(transactions: transactions)
    }

    private var topCategories: [CategoryTotal] {
        Array(InsightsEngine.categoryTotals(transactions: transactions).prefix(6))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if transactions.isEmpty {
                        EmptyStateView(
                            symbol: "chart.pie",
                            title: "No data to chart yet",
                            message: "Import statements (or load sample data) from the Activity tab to see spending trends and reports.")
                            .card()
                    } else {
                        categoryMixCard
                        monthlyTrendCard
                        discretionaryTrendCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: reportText) {
                        Label("Share Report", systemImage: "square.and.arrow.up")
                    }
                    .disabled(transactions.isEmpty)
                }
            }
        }
    }

    private var reportText: String {
        ReportGenerator.monthlyReport(
            transactions: transactions,
            accounts: accounts,
            goals: goals,
            plan: plans.first)
    }

    // MARK: - Category mix (last 30 days)

    private var categoryMixCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where the money went")
                .font(.headline)
            Text("Top categories, last 30 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(topCategories) { entry in
                SectorMark(
                    angle: .value("Spent", entry.total),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5)
                    .foregroundStyle(entry.category.tint)
                    .cornerRadius(4)
            }
            .frame(height: 200)

            VStack(spacing: 6) {
                ForEach(topCategories) { entry in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(entry.category.tint)
                            .frame(width: 8, height: 8)
                        Text(entry.category.displayName)
                            .font(.caption)
                        Spacer()
                        Text(entry.total.currency)
                            .font(.caption.weight(.medium))
                            .monospacedDigit()
                    }
                }
            }
        }
        .card()
    }

    // MARK: - 6-month stacked spending

    private struct StackEntry: Identifiable {
        let id = UUID()
        let month: Date
        let type: String
        let amount: Double
    }

    private var stackEntries: [StackEntry] {
        monthly.flatMap { month in
            [
                StackEntry(month: month.month, type: "Essentials", amount: month.essentials),
                StackEntry(month: month.month, type: "Discretionary", amount: month.discretionary),
                StackEntry(month: month.month, type: "Debt & Saving", amount: month.debtAndSavings),
            ]
        }
    }

    private var monthlyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly spending")
                .font(.headline)
            Text("Last 6 months, by type")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(stackEntries) { entry in
                BarMark(
                    x: .value("Month", entry.month, unit: .month),
                    y: .value("Spent", entry.amount))
                    .foregroundStyle(by: .value("Type", entry.type))
                    .cornerRadius(3)
            }
            .chartForegroundStyleScale([
                "Essentials": Color.blue,
                "Discretionary": Color.pink,
                "Debt & Saving": Color.teal,
            ])
            .frame(height: 220)
        }
        .card()
    }

    // MARK: - Discretionary trend

    private var discretionaryAverage: Double {
        let values = monthly.map(\.discretionary)
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var discretionaryTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discretionary trend")
                .font(.headline)
            Text("Dining, shopping, fun — the dollars the daily tips target")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(monthly) { month in
                    LineMark(
                        x: .value("Month", month.month, unit: .month),
                        y: .value("Discretionary", month.discretionary))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.pink)
                        .symbol(.circle)
                }
                RuleMark(y: .value("Average", discretionaryAverage))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .top, alignment: .leading) {
                        Text("6-mo avg \(discretionaryAverage.wholeCurrency)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(height: 200)

            if !trendCaption.isEmpty {
                Text(trendCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var trendCaption: String {
        let values = monthly.map(\.discretionary)
        guard values.count >= 2, let current = values.last else { return "" }
        let priors = values.dropLast()
        let average = priors.reduce(0, +) / Double(priors.count)
        guard average > 0 else { return "" }

        let delta = (current - average) / average
        let percent = abs(delta).formatted(.percent.precision(.fractionLength(0)))
        return delta <= 0
            ? "This month's fun spending is \(percent) below your recent average — those freed-up dollars are going to work in your plan."
            : "This month's fun spending is \(percent) above your recent average — check today's tip for an easy trim."
    }
}
