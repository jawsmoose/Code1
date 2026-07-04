import Foundation
import SwiftData

/// Seeds four months of realistic, deterministic demo data so every screen
/// works before the user imports their own statements.
@MainActor
enum SampleData {

    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    static func populate(context: ModelContext, reference: Date = Date()) {
        var rng = SeededGenerator(state: 42)
        let calendar = Calendar.current

        // Accounts
        let checking = FinancialAccount(name: "Everyday Checking", institution: "First National", kind: .checking, currentBalance: 3_240)
        let visa = FinancialAccount(name: "Visa Rewards", institution: "First National", kind: .creditCard, currentBalance: 4_150, apr: 22.9, minimumPayment: 125)
        let autoLoan = FinancialAccount(name: "Auto Loan", institution: "DriveTime Credit", kind: .loan, currentBalance: 9_800, apr: 6.4, minimumPayment: 285)
        let mortgage = FinancialAccount(name: "Home Mortgage", institution: "Blue Sky Lending", kind: .mortgage, currentBalance: 284_500, apr: 5.1, minimumPayment: 1_850)
        let brokerage = FinancialAccount(name: "Brokerage", institution: "Vanguard", kind: .investment, currentBalance: 18_600)
        for account in [checking, visa, autoLoan, mortgage, brokerage] {
            context.insert(account)
        }

        // Goals
        let vacation = SavingsGoal(
            name: "Hawaii Vacation",
            iconName: "airplane",
            targetAmount: 5_000,
            savedAmount: 1_150,
            targetDate: calendar.date(byAdding: .month, value: 11, to: reference) ?? reference,
            priority: 1)
        let remodel = SavingsGoal(
            name: "Kitchen Remodel",
            iconName: "hammer.fill",
            targetAmount: 25_000,
            savedAmount: 3_400,
            targetDate: calendar.date(byAdding: .month, value: 26, to: reference) ?? reference,
            priority: 2)
        context.insert(vacation)
        context.insert(remodel)

        // Four months of checking-account activity
        func amount(_ range: ClosedRange<Double>) -> Double {
            (Double.random(in: range, using: &rng) * 100).rounded() / 100
        }

        let diningSpots = ["CHIPOTLE", "PHO SAIGON CAFE", "DOORDASH*THAI HOUSE", "OLIVE & VINE RESTAURANT", "FIVE GUYS BURGERS"]

        for daysAgo in 0...119 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: reference) else { continue }
            let dayOfMonth = calendar.component(.day, from: date)

            func insertTransaction(_ payee: String, _ value: Double, _ category: SpendingCategory) {
                let transaction = BankTransaction(date: date, payee: payee, amount: value, category: category)
                transaction.account = checking
                context.insert(transaction)
            }

            // Income
            if daysAgo % 14 == 3 {
                insertTransaction("ACME CO PAYROLL DIRECT DEP", 2_450, .income)
            }

            // Fixed monthly bills
            if dayOfMonth == 1 { insertTransaction("BLUE SKY LENDING MORTGAGE", -1_850, .debtPayment) }
            if dayOfMonth == 5 { insertTransaction("DRIVETIME CREDIT AUTOPAY", -285, .debtPayment) }
            if dayOfMonth == 20 { insertTransaction("VISA REWARDS PAYMENT THANK YOU", -125, .debtPayment) }
            if dayOfMonth == 8 { insertTransaction("CITY POWER & LIGHT", -amount(120...185), .utilities) }
            if dayOfMonth == 10 { insertTransaction("XFINITY INTERNET", -79.99, .utilities) }
            if dayOfMonth == 12 { insertTransaction("T-MOBILE", -95, .utilities) }
            if dayOfMonth == 14 { insertTransaction("GEICO AUTO INSURANCE", -142, .insurance) }
            if dayOfMonth == 6 { insertTransaction("VANGUARD BUY", -400, .investment) }
            if dayOfMonth == 7 { insertTransaction("TRANSFER TO SAVINGS", -300, .savingsTransfer) }

            // Subscriptions
            if dayOfMonth == 15 { insertTransaction("NETFLIX.COM", -15.49, .subscriptions) }
            if dayOfMonth == 16 { insertTransaction("SPOTIFY USA", -11.99, .subscriptions) }
            if dayOfMonth == 17 { insertTransaction("PLANET FIT MEMBERSHIP", -45, .subscriptions) }
            if dayOfMonth == 3 { insertTransaction("APPLE.COM/BILL", -9.99, .subscriptions) }

            // Groceries & fuel
            if daysAgo % 7 == 2 { insertTransaction("WHOLE FOODS MARKET", -amount(85...150), .groceries) }
            if daysAgo % 7 == 5 { insertTransaction("TRADER JOE'S", -amount(40...80), .groceries) }
            if daysAgo % 7 == 4 { insertTransaction("SHELL OIL", -amount(34...52), .transport) }

            // Discretionary habits
            if daysAgo % 3 == 0 {
                insertTransaction(diningSpots[daysAgo % diningSpots.count], -amount(14...48), .dining)
            }
            if daysAgo % 2 == 1 { insertTransaction("STARBUCKS", -amount(5.25...9.5), .dining) }
            if daysAgo % 11 == 6 { insertTransaction("AMZN MKTP US", -amount(24...110), .shopping) }
            if daysAgo % 16 == 9 { insertTransaction("AMC THEATRES", -amount(22...58), .entertainment) }
            if daysAgo % 23 == 11 { insertTransaction("SALON LUXE", -amount(35...85), .personalCare) }
        }

        let settings = PlanService.fetchOrCreateSettings(in: context)
        settings.paycheckAmount = 2_450
        settings.payFrequency = .biweekly

        try? context.save()
    }
}
