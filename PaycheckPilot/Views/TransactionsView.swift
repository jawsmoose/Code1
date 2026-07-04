import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TransactionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BankTransaction.date, order: .reverse) private var transactions: [BankTransaction]
    @State private var showingImporter = false
    @State private var importMessage: String?

    private var monthGroups: [(month: Date, items: [BankTransaction])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: transactions) { transaction in
            calendar.dateInterval(of: .month, for: transaction.date)?.start ?? transaction.date
        }
        return groups.keys.sorted(by: >).map { (month: $0, items: groups[$0] ?? []) }
    }

    private var importTypes: [UTType] {
        var types: [UTType] = [.commaSeparatedText, .plainText, .text, .data]
        if let ofx = UTType(filenameExtension: "ofx") { types.append(ofx) }
        if let qfx = UTType(filenameExtension: "qfx") { types.append(qfx) }
        return types
    }

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    VStack {
                        EmptyStateView(
                            symbol: "tray.and.arrow.down",
                            title: "No activity yet",
                            message: "Import a bank, card or investment statement (CSV, OFX or QFX) to teach the app your spending habits.",
                            actionTitle: "Import Statement") {
                                showingImporter = true
                            }
                        Button("Or explore with sample data") {
                            SampleData.populate(context: context)
                            PlanService.regeneratePlan(in: context)
                        }
                        .font(.subheadline)
                    }
                } else {
                    List {
                        ForEach(monthGroups, id: \.month) { group in
                            Section(group.month.formatted(.dateTime.month(.wide).year())) {
                                ForEach(group.items) { transaction in
                                    NavigationLink {
                                        TransactionDetailView(transaction: transaction)
                                    } label: {
                                        TransactionRow(transaction: transaction)
                                    }
                                }
                                .onDelete { offsets in
                                    delete(offsets, from: group.items)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import Statement", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: importTypes,
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert(
                "Statement Import",
                isPresented: Binding(
                    get: { importMessage != nil },
                    set: { if !$0 { importMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let outcome = try StatementImportService.importStatement(from: url, context: context)
                var message = "Imported \(outcome.imported) transactions."
                if outcome.skippedDuplicates > 0 {
                    message += " Skipped \(outcome.skippedDuplicates) duplicates."
                }
                importMessage = message
                PlanService.regeneratePlan(in: context)
            } catch {
                importMessage = error.localizedDescription
            }
        case .failure(let error):
            importMessage = error.localizedDescription
        }
    }

    private func delete(_ offsets: IndexSet, from items: [BankTransaction]) {
        for index in offsets {
            context.delete(items[index])
        }
        try? context.save()
    }
}

// MARK: - Row

private struct TransactionRow: View {
    let transaction: BankTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.symbol)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(transaction.category.tint))
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.payee)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text("\(transaction.category.displayName) • \(transaction.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(transaction.amount.currency)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(transaction.amount > 0 ? .green : .primary)
        }
    }
}

// MARK: - Detail / recategorize

private struct TransactionDetailView: View {
    @Bindable var transaction: BankTransaction
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Payee", value: transaction.payee)
                LabeledContent("Date", value: transaction.date.formatted(date: .long, time: .omitted))
                LabeledContent("Amount", value: transaction.amount.currency)
            }
            Section("Category") {
                Picker("Category", selection: $transaction.categoryRaw) {
                    ForEach(SpendingCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.symbol)
                            .tag(category.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? context.save()
        }
    }
}
