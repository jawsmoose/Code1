import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

enum AccountKind: String, Codable, CaseIterable, Identifiable {
    case checking, savings, creditCard, investment, loan, mortgage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .creditCard: return "Credit Card"
        case .investment: return "Investment"
        case .loan: return "Loan"
        case .mortgage: return "Mortgage"
        }
    }

    var isDebt: Bool {
        switch self {
        case .creditCard, .loan, .mortgage: return true
        case .checking, .savings, .investment: return false
        }
    }

    var symbol: String {
        switch self {
        case .checking: return "banknote"
        case .savings: return "building.columns"
        case .creditCard: return "creditcard"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .loan: return "doc.text"
        case .mortgage: return "house"
        }
    }
}

enum PayFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly, biweekly, semimonthly, monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .semimonthly: return "Twice a Month"
        case .monthly: return "Monthly"
        }
    }

    var paychecksPerMonth: Double {
        switch self {
        case .weekly: return 52.0 / 12.0
        case .biweekly: return 26.0 / 12.0
        case .semimonthly: return 2.0
        case .monthly: return 1.0
        }
    }
}

enum PayoffStrategy: String, Codable, CaseIterable, Identifiable {
    case avalanche, snowball

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .avalanche: return "Avalanche"
        case .snowball: return "Snowball"
        }
    }

    var explanation: String {
        switch self {
        case .avalanche: return "Extra dollars attack the highest-APR balance first — mathematically fastest."
        case .snowball: return "Extra dollars attack the smallest balance first — quick wins for motivation."
        }
    }
}

enum SpendingCategory: String, Codable, CaseIterable, Identifiable {
    case income, housing, utilities, groceries, transport, insurance, healthcare
    case dining, entertainment, shopping, subscriptions, travel, personalCare
    case education, debtPayment, investment, savingsTransfer, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .income: return "Income"
        case .housing: return "Housing"
        case .utilities: return "Utilities"
        case .groceries: return "Groceries"
        case .transport: return "Transport"
        case .insurance: return "Insurance"
        case .healthcare: return "Healthcare"
        case .dining: return "Dining Out"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .subscriptions: return "Subscriptions"
        case .travel: return "Travel"
        case .personalCare: return "Personal Care"
        case .education: return "Education"
        case .debtPayment: return "Debt Payment"
        case .investment: return "Investing"
        case .savingsTransfer: return "Savings Transfer"
        case .other: return "Other"
        }
    }

    /// Wants — the flexible spending the app coaches you to trim.
    var isDiscretionary: Bool {
        switch self {
        case .dining, .entertainment, .shopping, .subscriptions, .travel, .personalCare:
            return true
        default:
            return false
        }
    }

    /// Needs — must-pay costs that anchor the allocation plan.
    var isEssential: Bool {
        switch self {
        case .housing, .utilities, .groceries, .transport, .insurance, .healthcare, .education, .other:
            return true
        default:
            return false
        }
    }

    var symbol: String {
        switch self {
        case .income: return "dollarsign.circle.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .groceries: return "cart.fill"
        case .transport: return "car.fill"
        case .insurance: return "shield.fill"
        case .healthcare: return "cross.case.fill"
        case .dining: return "fork.knife"
        case .entertainment: return "popcorn.fill"
        case .shopping: return "bag.fill"
        case .subscriptions: return "tv.fill"
        case .travel: return "airplane"
        case .personalCare: return "scissors"
        case .education: return "graduationcap.fill"
        case .debtPayment: return "creditcard.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .savingsTransfer: return "arrow.left.arrow.right"
        case .other: return "questionmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .income: return .green
        case .housing: return .brown
        case .utilities: return .yellow
        case .groceries: return .mint
        case .transport: return .blue
        case .insurance: return .cyan
        case .healthcare: return .red
        case .dining: return .pink
        case .entertainment: return .orange
        case .shopping: return .purple
        case .subscriptions: return .indigo
        case .travel: return .teal
        case .personalCare: return Color(red: 0.85, green: 0.45, blue: 0.55)
        case .education: return Color(red: 0.35, green: 0.45, blue: 0.85)
        case .debtPayment: return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .investment: return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .savingsTransfer: return Color(red: 0.3, green: 0.65, blue: 0.7)
        case .other: return .gray
        }
    }
}

enum AllocationKind: String, Codable, CaseIterable {
    case essentials, debtMinimum, debtExtra, goal, investment, discretionary, buffer

    var displayName: String {
        switch self {
        case .essentials: return "Essentials"
        case .debtMinimum: return "Debt Minimum"
        case .debtExtra: return "Extra Paydown"
        case .goal: return "Savings Goal"
        case .investment: return "Investing"
        case .discretionary: return "Guilt-Free"
        case .buffer: return "Buffer"
        }
    }

    var symbol: String {
        switch self {
        case .essentials: return "house.fill"
        case .debtMinimum: return "creditcard.fill"
        case .debtExtra: return "flame.fill"
        case .goal: return "flag.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .discretionary: return "party.popper.fill"
        case .buffer: return "umbrella.fill"
        }
    }

    var tint: Color {
        switch self {
        case .essentials: return .blue
        case .debtMinimum: return .orange
        case .debtExtra: return .red
        case .goal: return .purple
        case .investment: return .green
        case .discretionary: return .pink
        case .buffer: return .teal
        }
    }
}

// MARK: - SwiftData Models

@Model
final class FinancialAccount {
    var name: String
    var institution: String
    var kindRaw: String
    var currentBalance: Double
    /// Annual percentage rate — only meaningful for debt accounts.
    var apr: Double
    /// Required monthly payment — only meaningful for debt accounts.
    var minimumPayment: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BankTransaction.account)
    var transactions: [BankTransaction] = []

    init(name: String,
         institution: String = "",
         kind: AccountKind,
         currentBalance: Double = 0,
         apr: Double = 0,
         minimumPayment: Double = 0) {
        self.name = name
        self.institution = institution
        self.kindRaw = kind.rawValue
        self.currentBalance = currentBalance
        self.apr = apr
        self.minimumPayment = minimumPayment
        self.createdAt = Date()
    }

    var kind: AccountKind {
        get { AccountKind(rawValue: kindRaw) ?? .checking }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class BankTransaction {
    var date: Date
    var payee: String
    var details: String
    /// Negative = money out, positive = money in.
    var amount: Double
    var categoryRaw: String
    var account: FinancialAccount?

    init(date: Date,
         payee: String,
         amount: Double,
         category: SpendingCategory,
         details: String = "") {
        self.date = date
        self.payee = payee
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.details = details
        self.account = nil
    }

    var category: SpendingCategory {
        get { SpendingCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class SavingsGoal {
    var name: String
    var iconName: String
    var targetAmount: Double
    var savedAmount: Double
    var targetDate: Date
    /// 1 = high, 2 = medium, 3 = low.
    var priority: Int
    var createdAt: Date

    init(name: String,
         iconName: String = "flag.fill",
         targetAmount: Double,
         savedAmount: Double = 0,
         targetDate: Date,
         priority: Int = 2) {
        self.name = name
        self.iconName = iconName
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.targetDate = targetDate
        self.priority = priority
        self.createdAt = Date()
    }

    var remainingAmount: Double { max(0, targetAmount - savedAmount) }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, savedAmount / targetAmount)
    }
}

@Model
final class AllocationPlan {
    var generatedAt: Date
    var paycheckAmount: Double
    var tipTitle: String
    var tipBody: String

    @Relationship(deleteRule: .cascade, inverse: \AllocationLine.plan)
    var lines: [AllocationLine] = []

    init(generatedAt: Date, paycheckAmount: Double, tipTitle: String, tipBody: String) {
        self.generatedAt = generatedAt
        self.paycheckAmount = paycheckAmount
        self.tipTitle = tipTitle
        self.tipBody = tipBody
    }

    var sortedLines: [AllocationLine] {
        lines.sorted { $0.sortOrder < $1.sortOrder }
    }
}

@Model
final class AllocationLine {
    var label: String
    var detail: String
    var amount: Double
    var kindRaw: String
    var sortOrder: Int
    var plan: AllocationPlan?

    init(label: String, detail: String, amount: Double, kind: AllocationKind, sortOrder: Int) {
        self.label = label
        self.detail = detail
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.sortOrder = sortOrder
        self.plan = nil
    }

    var kind: AllocationKind {
        get { AllocationKind(rawValue: kindRaw) ?? .buffer }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class AppSettings {
    var paycheckAmount: Double
    var payFrequencyRaw: String
    var payoffStrategyRaw: String
    /// Relative weights for splitting free dollars; normalized before use.
    var debtWeight: Double
    var goalWeight: Double
    var investWeight: Double
    /// Percent (0–30) to trim discretionary spending below the recent average.
    var discretionaryTrimPercent: Double
    var lastDailyUpdate: Date?
    var cloudSyncEnabled: Bool
    var createdAt: Date

    init(paycheckAmount: Double = 0,
         payFrequency: PayFrequency = .biweekly,
         payoffStrategy: PayoffStrategy = .avalanche,
         debtWeight: Double = 0.4,
         goalWeight: Double = 0.3,
         investWeight: Double = 0.3,
         discretionaryTrimPercent: Double = 10,
         cloudSyncEnabled: Bool = false) {
        self.paycheckAmount = paycheckAmount
        self.payFrequencyRaw = payFrequency.rawValue
        self.payoffStrategyRaw = payoffStrategy.rawValue
        self.debtWeight = debtWeight
        self.goalWeight = goalWeight
        self.investWeight = investWeight
        self.discretionaryTrimPercent = discretionaryTrimPercent
        self.lastDailyUpdate = nil
        self.cloudSyncEnabled = cloudSyncEnabled
        self.createdAt = Date()
    }

    var payFrequency: PayFrequency {
        get { PayFrequency(rawValue: payFrequencyRaw) ?? .biweekly }
        set { payFrequencyRaw = newValue.rawValue }
    }

    var payoffStrategy: PayoffStrategy {
        get { PayoffStrategy(rawValue: payoffStrategyRaw) ?? .avalanche }
        set { payoffStrategyRaw = newValue.rawValue }
    }
}
