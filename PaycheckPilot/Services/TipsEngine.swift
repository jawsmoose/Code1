import Foundation

struct DailyTip {
    let title: String
    let message: String
    let symbol: String
}

/// Serves one fresh, personalized money-saving tip per day. Tips are chosen
/// from the categories you actually overspend in, quantified with your real
/// 30-day numbers, and always point the freed-up dollars at your highest-APR
/// debt or most urgent goal. The pick is deterministic per calendar day, so
/// the tip stays stable all day and rotates overnight.
enum TipsEngine {

    static func tip(
        for date: Date = Date(),
        transactions: [BankTransaction],
        debts: [FinancialAccount],
        goals: [SavingsGoal]
    ) -> DailyTip {
        let discretionaryTotals = InsightsEngine
            .categoryTotals(transactions: transactions, days: 30, reference: date)
            .filter { $0.category.isDiscretionary && $0.total > 0 }

        let target = redirectTarget(debts: debts, goals: goals)

        var candidates: [DailyTip] = []
        for entry in discretionaryTotals.prefix(3) {
            candidates.append(contentsOf: tips(for: entry.category, spent: entry.total, target: target))
        }
        candidates.append(contentsOf: generalTips(target: target))

        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let index = (day * 31 + year) % max(1, candidates.count)
        return candidates[index]
    }

    // MARK: - Category-specific tips

    private static func tips(for category: SpendingCategory, spent: Double, target: String) -> [DailyTip] {
        let monthly = spent.currency

        switch category {
        case .dining:
            return [
                DailyTip(
                    title: "Cook one more dinner at home",
                    message: "You've spent \(monthly) on dining out in the last 30 days. Swapping one restaurant meal a week for a home-cooked one frees up about \((spent * 0.12).currency)/month for \(target).",
                    symbol: "fork.knife"),
                DailyTip(
                    title: "Brown-bag it three days this week",
                    message: "Dining out ran \(monthly) over the last 30 days. Packing lunch three days a week typically keeps \((spent * 0.15).currency)/month in your pocket — send it to \(target).",
                    symbol: "takeoutbag.and.cup.and.straw.fill"),
                DailyTip(
                    title: "Make coffee a home ritual",
                    message: "Café stops add up inside your \(monthly) dining total. Brewing at home on weekdays saves most people \((spent * 0.08).currency)/month — enough to chip away at \(target).",
                    symbol: "cup.and.saucer.fill"),
            ]
        case .subscriptions:
            return [
                DailyTip(
                    title: "Audit one subscription today",
                    message: "Subscriptions cost you \(monthly) in the last 30 days. Cancel the one you use least and redirect it to \(target) — even $12/month compounds to ~$150/year.",
                    symbol: "tv.fill"),
                DailyTip(
                    title: "Rotate, don't stack, streaming",
                    message: "You're paying \(monthly)/month across subscriptions. Keep one streaming service at a time and rotate monthly; the difference goes straight to \(target).",
                    symbol: "arrow.triangle.2.circlepath"),
            ]
        case .shopping:
            return [
                DailyTip(
                    title: "Try the 24-hour cart rule",
                    message: "Shopping totaled \(monthly) over the last 30 days. Leave anything non-essential in the cart for 24 hours before buying — impulse buys drop ~20%, worth about \((spent * 0.2).currency)/month for \(target).",
                    symbol: "cart.badge.minus"),
                DailyTip(
                    title: "Unsubscribe from 3 retail emails",
                    message: "Retailers engineered those \(monthly) of purchases. Unsubscribing from three promo lists today removes the trigger — aim the savings at \(target).",
                    symbol: "envelope.badge.shield.half.filled"),
            ]
        case .entertainment:
            return [
                DailyTip(
                    title: "Swap one paid night for a free one",
                    message: "Entertainment ran \(monthly) in the last 30 days. Trade one ticketed outing this month for a free option (parks, library passes, game night) and push \((spent * 0.25).currency) to \(target).",
                    symbol: "figure.socialdance"),
            ]
        case .travel:
            return [
                DailyTip(
                    title: "Book with alerts, not impulse",
                    message: "Travel spending hit \(monthly) in the last 30 days. Setting fare alerts instead of booking same-day typically saves 15–25% — that's \((spent * 0.2).currency) toward \(target).",
                    symbol: "airplane.circle.fill"),
            ]
        case .personalCare:
            return [
                DailyTip(
                    title: "Stretch appointments by a week",
                    message: "Personal care cost \(monthly) over the last 30 days. Stretching each appointment cycle by one week trims roughly \((spent * 0.15).currency)/month for \(target).",
                    symbol: "scissors"),
            ]
        default:
            return []
        }
    }

    // MARK: - Evergreen tips

    private static func generalTips(target: String) -> [DailyTip] {
        [
            DailyTip(
                title: "Automate a $5 daily sweep",
                message: "Set up an automatic $5/day transfer out of checking. You won't feel it day to day, but it's ~$150/month working for \(target).",
                symbol: "arrow.right.circle.fill"),
            DailyTip(
                title: "Negotiate one bill today",
                message: "Call your internet or phone provider and ask for the current promo rate. A 10-minute call saves $10–30/month — redirect it to \(target).",
                symbol: "phone.arrow.up.right.fill"),
            DailyTip(
                title: "Try a no-spend weekend",
                message: "Challenge: no discretionary purchases this weekend. Most people bank $40–80, and every dollar can go to \(target).",
                symbol: "calendar.badge.checkmark"),
            DailyTip(
                title: "Bump investing by 1%",
                message: "If your employer offers a retirement plan, raise your contribution by just 1%. It's nearly invisible per paycheck and accelerates the same plan that funds \(target).",
                symbol: "percent"),
            DailyTip(
                title: "Pay with cash this week",
                message: "Studies consistently show cash purchases run 10–20% smaller than card taps. Withdraw your fun-money budget in cash and let the leftovers go to \(target).",
                symbol: "banknote.fill"),
            DailyTip(
                title: "Batch errands into one trip",
                message: "Combining this week's errands into a single loop cuts fuel and impulse stops. Small, boring, effective — and \(target) collects the difference.",
                symbol: "car.circle.fill"),
        ]
    }

    private static func redirectTarget(debts: [FinancialAccount], goals: [SavingsGoal]) -> String {
        if let debt = debts.filter({ $0.currentBalance > 0 }).max(by: { $0.apr < $1.apr }) {
            let apr = debt.apr.formatted(.number.precision(.fractionLength(1)))
            return "your \(debt.name) (\(apr)% APR)"
        }
        if let goal = goals.filter({ $0.remainingAmount > 0 }).min(by: { $0.targetDate < $1.targetDate }) {
            return "your \"\(goal.name)\" goal"
        }
        return "your investments"
    }
}
