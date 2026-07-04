import Foundation
import SwiftData

struct ParsedStatementTransaction {
    var date: Date
    var payee: String
    var amount: Double
}

/// Reads a picked statement file (CSV, OFX or QFX), auto-categorizes each
/// transaction, and inserts anything that isn't already in the ledger.
@MainActor
enum StatementImportService {

    struct ImportResult {
        var imported = 0
        var skippedDuplicates = 0
    }

    enum ImportError: LocalizedError {
        case unreadable
        case empty

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "Couldn't read that file. Export your statement as CSV, OFX or QFX and try again."
            case .empty:
                return "No transactions were found in that file."
            }
        }
    }

    static func importStatement(from url: URL, context: ModelContext) throws -> ImportResult {
        let secured = url.startAccessingSecurityScopedResource()
        defer {
            if secured { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        let text: String
        if let utf8 = String(data: data, encoding: .utf8) {
            text = utf8
        } else if let latin = String(data: data, encoding: .isoLatin1) {
            text = latin
        } else {
            throw ImportError.unreadable
        }

        let ext = url.pathExtension.lowercased()
        let parsed: [ParsedStatementTransaction]
        if ext == "ofx" || ext == "qfx" || text.contains("<OFX") || text.contains("<STMTTRN>") {
            parsed = OFXStatementParser.parse(text)
        } else {
            parsed = CSVStatementParser.parse(text)
        }
        guard !parsed.isEmpty else { throw ImportError.empty }

        let existing = (try? context.fetch(FetchDescriptor<BankTransaction>())) ?? []
        var seen = Set(existing.map(fingerprint))

        var result = ImportResult()
        for item in parsed {
            let transaction = BankTransaction(
                date: item.date,
                payee: item.payee,
                amount: item.amount,
                category: CategorizationEngine.categorize(payee: item.payee, amount: item.amount))

            let key = fingerprint(transaction)
            if seen.contains(key) {
                result.skippedDuplicates += 1
                continue
            }
            seen.insert(key)
            context.insert(transaction)
            result.imported += 1
        }
        try context.save()
        return result
    }

    private static func fingerprint(_ transaction: BankTransaction) -> String {
        let day = Calendar.current.startOfDay(for: transaction.date).timeIntervalSince1970
        return "\(day)|\(transaction.payee.lowercased())|\(String(format: "%.2f", transaction.amount))"
    }
}
