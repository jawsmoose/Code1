import Foundation

struct AllocationInput {
    var paycheckAmount: Double
    var frequency: PayFrequency
    var transactions: [BankTransaction]
    var debts: [FinancialAccount]
    var investmentAccounts: [FinancialAccount]
    var goals: [SavingsGoal]
    var strategy: PayoffStrategy
    var debtWeight: Double
    var goalWeight: Double
    var investWeight: Double
    /// 0...1 fraction to trim discretionary spending below the recent average.
    var discretionaryTrim: Double
    var referenceDate: Date = Date()
}

struct AllocationLineSpec {
    var label: String
    var detail: String
    var amount: Double
    var kind: AllocationKind
}

/// Gives every dollar of a paycheck a job:
///  1. Essentials, sized from the last 90 days of real spending
///  2. Required debt minimums (mortgage, loans, cards)
///  3. A guarded "guilt-free" budget, trimmed below the recent pace
///  4. Free dollars split across extra debt paydown, savings goals and investing
///  5. Rounding leftovers land in a cash buffer, so the lines always sum to the paycheck
enum AllocationEngine {

    static func buildPlan(_ input: AllocationInput) -> [AllocationLineSpec] {
        let paycheck = max(0, input.paycheckAmount)
        guard paycheck > 0 else { return [] }

        let perMonth = input.frequency.paychecksPerMonth
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -90, to: input.referenceDate) ?? input.referenceDate
        let recentSpend = input.transactions.filter {
            $0.date >= cutoff && $0.date <= input.referenceDate && $0.amount < 0
        }

        // Normalize by how much history actually exists (0.5–3 months).
        let monthsObserved: Double
        if let earliest = recentSpend.map(\.date).min() {
            let days = max(14.0, input.referenceDate.timeIntervalSince(earliest) / 86_400)
            monthsObserved = min(3.0, days / 30.0)
        } else {
            monthsObserved = 1.0
        }

        func monthlyTotal(where matches: (SpendingCategory) -> Bool) -> Double {
            let total = recentSpend
                .filter { matches($0.category) }
                .reduce(0) { $0 + abs($1.amount) }
            return total / monthsObserved
        }

        var essentialsMonthly = monthlyTotal { $0.isEssential }
        var discretionaryMonthly = monthlyTotal { $0.isDiscretionary }

        // No imported history yet? Fall back to the 50/30/20 guideline.
        let monthlyIncome = paycheck * perMonth
        if essentialsMonthly == 0 { essentialsMonthly = monthlyIncome * 0.5 }
        if discretionaryMonthly == 0 { discretionaryMonthly = monthlyIncome * 0.15 }

        var lines: [AllocationLineSpec] = []
        var remaining = paycheck

        // 1. Essentials
        let historyDays = Int((monthsObserved * 30).rounded())
        let essentials = min(remaining, round2(essentialsMonthly / perMonth))
        if essentials > 0 {
            lines.append(AllocationLineSpec(
                label: "Essentials",
                detail: "Housing, groceries, utilities & other must-pays, sized from your last \(historyDays) days",
                amount: essentials,
                kind: .essentials))
            remaining -= essentials
        }

        // 2. Required debt minimums
        for debt in input.debts.sorted(by: { $0.minimumPayment > $1.minimumPayment })
        where debt.minimumPayment > 0 && debt.currentBalance > 0 {
            let share = min(remaining, round2(debt.minimumPayment / perMonth))
            guard share > 0 else { continue }
            lines.append(AllocationLineSpec(
                label: "\(debt.name) minimum",
                detail: "Required payment • \(percentText(debt.apr)) APR",
                amount: share,
                kind: .debtMinimum))
            remaining -= share
        }

        // 3. Guarded discretionary budget
        let discretionaryBase = discretionaryMonthly / perMonth
        let discretionaryBudget = min(remaining, round2(discretionaryBase * (1 - input.discretionaryTrim)))
        if discretionaryBudget > 0 {
            let trimPercent = Int((input.discretionaryTrim * 100).rounded())
            lines.append(AllocationLineSpec(
                label: "Guilt-free spending",
                detail: trimPercent > 0
                    ? "Dining, fun & shopping — trimmed \(trimPercent)% below your recent pace"
                    : "Dining, fun & shopping, matched to your recent pace",
                amount: discretionaryBudget,
                kind: .discretionary))
            remaining -= discretionaryBudget
        }

        // 4. Free dollars → extra paydown, goals, investing
        remaining = max(0, round2(remaining))
        if remaining > 0 {
            let hasDebt = input.debts.contains { $0.currentBalance > 0 }
            let hasGoals = input.goals.contains { $0.remainingAmount > 0 }

            var debtShare = hasDebt ? max(0, input.debtWeight) : 0
            var goalShare = hasGoals ? max(0, input.goalWeight) : 0
            var investShare = max(0, input.investWeight)
            let shareSum = debtShare + goalShare + investShare
            if shareSum > 0 {
                debtShare /= shareSum
                goalShare /= shareSum
                investShare /= shareSum
            } else {
                debtShare = 0
                goalShare = 0
                investShare = 1
            }

            var debtPot = round2(remaining * debtShare)
            let goalPot = round2(remaining * goalShare)
            var investPot = remaining - debtPot - goalPot

            if debtPot > 0, let target = payoffTarget(debts: input.debts, strategy: input.strategy) {
                let detail = input.strategy == .avalanche
                    ? "Avalanche: highest APR first (\(percentText(target.apr)))"
                    : "Snowball: smallest balance first (\(target.currentBalance.currency) left)"
                lines.append(AllocationLineSpec(
                    label: "Extra payment → \(target.name)",
                    detail: detail,
                    amount: debtPot,
                    kind: .debtExtra))
            } else {
                investPot += debtPot
                debtPot = 0
            }

            if goalPot > 0 {
                let funded = fundGoals(input.goals, pot: goalPot, perMonth: perMonth, reference: input.referenceDate)
                lines.append(contentsOf: funded.lines)
                investPot += funded.leftover
            }

            if investPot > 0.005 {
                let destination = input.investmentAccounts.first?.name ?? "brokerage / retirement"
                lines.append(AllocationLineSpec(
                    label: "Invest",
                    detail: "Automatic transfer to \(destination)",
                    amount: round2(investPot),
                    kind: .investment))
            }
        }

        // 5. Rounding leftovers become the cash buffer.
        let assigned = lines.reduce(0) { $0 + $1.amount }
        let buffer = round2(paycheck - assigned)
        if buffer > 0.005 {
            lines.append(AllocationLineSpec(
                label: "Cash buffer",
                detail: "Stays in checking to absorb surprises",
                amount: buffer,
                kind: .buffer))
        } else if buffer < -0.005, let index = lines.lastIndex(where: { $0.kind == .discretionary }) {
            lines[index].amount = round2(lines[index].amount + buffer)
        }

        return lines
    }

    static func payoffTarget(debts: [FinancialAccount], strategy: PayoffStrategy) -> FinancialAccount? {
        let active = debts.filter { $0.currentBalance > 0 }
        switch strategy {
        case .avalanche:
            return active.max { $0.apr < $1.apr }
        case .snowball:
            return active.min { $0.currentBalance < $1.currentBalance }
        }
    }

    // MARK: - Goals

    private static func fundGoals(
        _ goals: [SavingsGoal],
        pot: Double,
        perMonth: Double,
        reference: Date
    ) -> (lines: [AllocationLineSpec], leftover: Double) {
        var leftover = pot
        var lines: [AllocationLineSpec] = []

        let ranked = goals
            .filter { $0.remainingAmount > 0 }
            .sorted {
                let lhs = neededPerPaycheck($0, perMonth: perMonth, reference: reference)
                let rhs = neededPerPaycheck($1, perMonth: perMonth, reference: reference)
                if $0.priority != $1.priority { return $0.priority < $1.priority }
                return lhs > rhs
            }

        for goal in ranked {
            guard leftover > 0.01 else { break }
            let need = neededPerPaycheck(goal, perMonth: perMonth, reference: reference)
            let amount = round2(min(leftover, need))
            guard amount > 0.01 else { continue }
            lines.append(AllocationLineSpec(
                label: goal.name,
                detail: "On pace for \(goal.targetDate.formatted(date: .abbreviated, time: .omitted)) • \(goal.remainingAmount.currency) to go",
                amount: amount,
                kind: .goal))
            leftover -= amount
        }
        return (lines, max(0, round2(leftover)))
    }

    private static func neededPerPaycheck(_ goal: SavingsGoal, perMonth: Double, reference: Date) -> Double {
        let months = max(0.5, goal.targetDate.timeIntervalSince(reference) / (86_400 * 30))
        let periods = max(1.0, months * perMonth)
        return goal.remainingAmount / periods
    }

    // MARK: - Helpers

    private static func round2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static func percentText(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(1))))%"
    }
}
