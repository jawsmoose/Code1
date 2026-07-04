import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FinancialAccount.createdAt) private var accounts: [FinancialAccount]
    @Query(sort: \SavingsGoal.targetDate) private var goals: [SavingsGoal]
    @State private var showingAccountForm = false
    @State private var showingGoalForm = false

    private var debts: [FinancialAccount] { accounts.filter { $0.kind.isDebt } }
    private var cashAndInvestments: [FinancialAccount] { accounts.filter { !$0.kind.isDebt } }

    var body: some View {
        NavigationStack {
            List {
                Section("Debt paydown") {
                    if debts.isEmpty {
                        Text("Add your mortgage, loans and cards so extra dollars can attack the right balance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(debts) { account in
                        NavigationLink {
                            AccountDetailView(account: account)
                        } label: {
                            AccountRow(account: account)
                        }
                    }
                    .onDelete { deleteAccounts($0, from: debts) }
                }

                Section("Savings goals") {
                    if goals.isEmpty {
                        Text("Create goals like a vacation or remodel, and the app funds them a little every paycheck.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(goals) { goal in
                        NavigationLink {
                            GoalDetailView(goal: goal)
                        } label: {
                            GoalRow(goal: goal)
                        }
                    }
                    .onDelete(perform: deleteGoals)
                }

                Section("Cash & investments") {
                    if cashAndInvestments.isEmpty {
                        Text("Add checking, savings and brokerage accounts to track balances alongside debts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(cashAndInvestments) { account in
                        NavigationLink {
                            AccountDetailView(account: account)
                        } label: {
                            AccountRow(account: account)
                        }
                    }
                    .onDelete { deleteAccounts($0, from: cashAndInvestments) }
                }
            }
            .navigationTitle("Debts & Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAccountForm = true
                        } label: {
                            Label("Add Account", systemImage: "building.columns")
                        }
                        Button {
                            showingGoalForm = true
                        } label: {
                            Label("Add Savings Goal", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAccountForm) { AccountFormSheet() }
            .sheet(isPresented: $showingGoalForm) { GoalFormSheet() }
        }
    }

    private func deleteAccounts(_ offsets: IndexSet, from list: [FinancialAccount]) {
        for index in offsets {
            context.delete(list[index])
        }
        PlanService.regeneratePlan(in: context)
    }

    private func deleteGoals(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(goals[index])
        }
        PlanService.regeneratePlan(in: context)
    }
}

// MARK: - Rows

private struct AccountRow: View {
    let account: FinancialAccount

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.kind.symbol)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(account.kind.isDebt ? Color.orange : Color.accentColor)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline.weight(.medium))
                Text(account.institution.isEmpty ? account.kind.displayName : "\(account.institution) • \(account.kind.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(account.currentBalance.wholeCurrency)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                if account.kind.isDebt {
                    Text("min \(account.minimumPayment.wholeCurrency)/mo • \(account.apr.formatted(.number.precision(.fractionLength(1))))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct GoalRow: View {
    let goal: SavingsGoal

    var body: some View {
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
            Text("Target \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Detail editors

private struct AccountDetailView: View {
    @Bindable var account: FinancialAccount
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section("Account") {
                TextField("Name", text: $account.name)
                TextField("Institution", text: $account.institution)
                Picker("Type", selection: $account.kindRaw) {
                    ForEach(AccountKind.allCases) { kind in
                        Text(kind.displayName).tag(kind.rawValue)
                    }
                }
            }
            Section(account.kind.isDebt ? "Balance owed" : "Balance") {
                TextField("Current balance", value: $account.currentBalance, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
            }
            if account.kind.isDebt {
                Section("Debt terms") {
                    TextField("APR %", value: $account.apr, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Minimum monthly payment", value: $account.minimumPayment, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? context.save()
            PlanService.regeneratePlan(in: context)
        }
    }
}

private struct GoalDetailView: View {
    @Bindable var goal: SavingsGoal
    @Environment(\.modelContext) private var context

    private let icons = ["flag.fill", "airplane", "hammer.fill", "car.fill", "gift.fill",
                         "graduationcap.fill", "heart.fill", "house.fill", "pawprint.fill"]

    var body: some View {
        Form {
            Section("Goal") {
                TextField("Name", text: $goal.name)
                Picker("Icon", selection: $goal.iconName) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon).tag(icon)
                    }
                }
            }
            Section("Amounts") {
                TextField("Target amount", value: $goal.targetAmount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                TextField("Saved so far", value: $goal.savedAmount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
            }
            Section("Timing") {
                DatePicker("Target date", selection: $goal.targetDate, displayedComponents: .date)
                Picker("Priority", selection: $goal.priority) {
                    Text("High").tag(1)
                    Text("Medium").tag(2)
                    Text("Low").tag(3)
                }
            }
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? context.save()
            PlanService.regeneratePlan(in: context)
        }
    }
}

// MARK: - Add sheets

private struct AccountFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var institution = ""
    @State private var kind: AccountKind = .creditCard
    @State private var balance = 0.0
    @State private var apr = 0.0
    @State private var minimumPayment = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Account name", text: $name)
                TextField("Institution (optional)", text: $institution)
                Picker("Type", selection: $kind) {
                    ForEach(AccountKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                TextField(kind.isDebt ? "Balance owed" : "Current balance",
                          value: $balance, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                if kind.isDebt {
                    TextField("APR %", value: $apr, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Minimum monthly payment", value: $minimumPayment, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let account = FinancialAccount(
                            name: name,
                            institution: institution,
                            kind: kind,
                            currentBalance: balance,
                            apr: apr,
                            minimumPayment: minimumPayment)
                        context.insert(account)
                        PlanService.regeneratePlan(in: context)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

private struct GoalFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var targetAmount = 0.0
    @State private var savedAmount = 0.0
    @State private var targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var priority = 2

    var body: some View {
        NavigationStack {
            Form {
                TextField("Goal name (e.g. Hawaii Vacation)", text: $name)
                TextField("Target amount", value: $targetAmount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                TextField("Saved so far", value: $savedAmount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                Picker("Priority", selection: $priority) {
                    Text("High").tag(1)
                    Text("Medium").tag(2)
                    Text("Low").tag(3)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let goal = SavingsGoal(
                            name: name,
                            targetAmount: targetAmount,
                            savedAmount: savedAmount,
                            targetDate: targetDate,
                            priority: priority)
                        context.insert(goal)
                        PlanService.regeneratePlan(in: context)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || targetAmount <= 0)
                }
            }
        }
    }
}
