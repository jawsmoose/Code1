import Foundation

struct MonthlySpend: Identifiable {
    let month: Date
    let essentials: Double
    let discretionary: Double
    let debtAndSavings: Double

    var id: Date { month }
    var total: Double { essentials + discretionary + debtAndSavings }
}

struct CategoryTotal: Identifiable {
    let category: SpendingCategory
    let total: Double

    var id: String { category.rawValue }
}

/// Read-only analytics over the transaction ledger: rolling category totals,
/// month-over-month trends and the savings rate that power the dashboard,
/// reports and daily tips.
enum InsightsEngine {

    static func monthlySpending(
        transactions: [BankTransaction],
        months: Int = 6,
        reference: Date = Date()
    ) -> [MonthlySpend] {
        let calendar = Calendar.current
        var result: [MonthlySpend] = []

        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: reference),
                  let interval = calendar.dateInterval(of: .month, for: monthDate) else { continue }

            let monthTransactions = transactions.filter { $0.amount < 0 && interval.contains($0.date) }
            let essentials = monthTransactions
                .filter { $0.category.isEssential }
                .reduce(0) { $0 + abs($1.amount) }
            let discretionary = monthTransactions
                .filter { $0.category.isDiscretionary }
                .reduce(0) { $0 + abs($1.amount) }
            let total = monthTransactions.reduce(0) { $0 + abs($1.amount) }

            result.append(MonthlySpend(
                month: interval.start,
                essentials: essentials,
                discretionary: discretionary,
                debtAndSavings: max(0, total - essentials - discretionary)))
        }
        return result
    }

    static func categoryTotals(
        transactions: [BankTransaction],
        days: Int = 30,
        reference: Date = Date()
    ) -> [CategoryTotal] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: reference) else { return [] }

        var totals: [SpendingCategory: Double] = [:]
        for transaction in transactions
        where transaction.amount < 0 && transaction.date >= cutoff && transaction.date <= reference {
            totals[transaction.category, default: 0] += abs(transaction.amount)
        }
        return totals
            .map { CategoryTotal(category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    static func discretionarySpend(
        transactions: [BankTransaction],
        days: Int = 30,
        reference: Date = Date()
    ) -> Double {
        categoryTotals(transactions: transactions, days: days, reference: reference)
            .filter { $0.category.isDiscretionary }
            .reduce(0) { $0 + $1.total }
    }

    /// Share of recent income not spent on consumption (debt payments,
    /// investing and savings transfers count as "kept").
    static func savingsRate(
        transactions: [BankTransaction],
        days: Int = 30,
        reference: Date = Date()
    ) -> Double? {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: reference) else { return nil }
        let window = transactions.filter { $0.date >= cutoff && $0.date <= reference }

        let income = window.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        guard income > 0 else { return nil }

        let consumption = window
            .filter { $0.amount < 0 && $0.category != .investment && $0.category != .savingsTransfer }
            .reduce(0) { $0 + abs($1.amount) }
        return max(0, (income - consumption) / income)
    }

    static func topMerchants(
        transactions: [BankTransaction],
        days: Int = 30,
        limit: Int = 5,
        reference: Date = Date()
    ) -> [(payee: String, total: Double)] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: reference) else { return [] }

        var totals: [String: Double] = [:]
        for transaction in transactions
        where transaction.amount < 0 && transaction.date >= cutoff && transaction.date <= reference {
            totals[transaction.payee, default: 0] += abs(transaction.amount)
        }
        return totals
            .map { (payee: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
            .prefix(limit)
            .map { $0 }
    }
}
