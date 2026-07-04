import Foundation

/// Parses the CSV exports that most banks, credit cards and brokerages offer.
/// Handles quoted fields, several common header spellings, single amount
/// columns as well as split debit/credit columns, and a variety of date formats.
enum CSVStatementParser {

    static func parse(_ text: String) -> [ParsedStatementTransaction] {
        var rows = rows(from: text).filter { row in
            !row.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        guard !rows.isEmpty else { return [] }

        var dateIndex = 0
        var payeeIndex = 1
        var amountIndex: Int? = 2
        var debitIndex: Int?
        var creditIndex: Int?

        let header = rows[0].map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        let looksLikeHeader = header.contains { name in
            name.contains("date") || name.contains("amount") || name.contains("description")
        }

        if looksLikeHeader {
            rows.removeFirst()
            amountIndex = nil
            var foundDate: Int?
            var foundPayee: Int?
            for (index, name) in header.enumerated() {
                if foundDate == nil, name.contains("date") {
                    foundDate = index
                } else if foundPayee == nil,
                          name.contains("description") || name.contains("payee")
                            || name.contains("merchant") || name == "name" || name.contains("memo") {
                    foundPayee = index
                } else if amountIndex == nil, name.contains("amount"), !name.contains("balance") {
                    amountIndex = index
                } else if debitIndex == nil, name.contains("debit") || name.contains("withdrawal") {
                    debitIndex = index
                } else if creditIndex == nil,
                          (name.contains("credit") && !name.contains("card")) || name.contains("deposit") {
                    creditIndex = index
                }
            }
            dateIndex = foundDate ?? 0
            payeeIndex = foundPayee ?? 1
        }

        var result: [ParsedStatementTransaction] = []
        for row in rows {
            guard row.count > max(dateIndex, payeeIndex) else { continue }
            guard let date = date(from: row[dateIndex]) else { continue }

            let payee = row[payeeIndex].trimmingCharacters(in: .whitespacesAndNewlines)

            var amount: Double?
            if let index = amountIndex, index < row.count {
                amount = amountValue(row[index])
            }
            if amount == nil {
                let debit = debitIndex.flatMap { $0 < row.count ? amountValue(row[$0]) : nil }
                let credit = creditIndex.flatMap { $0 < row.count ? amountValue(row[$0]) : nil }
                if debit != nil || credit != nil {
                    amount = (credit ?? 0) - abs(debit ?? 0)
                }
            }

            guard let finalAmount = amount, finalAmount != 0 else { continue }
            result.append(ParsedStatementTransaction(
                date: date,
                payee: payee.isEmpty ? "Unknown" : payee,
                amount: finalAmount))
        }
        return result
    }

    // MARK: - Field helpers

    private static func rows(from text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        let characters = Array(text)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if inQuotes {
                if character == "\"" {
                    if index + 1 < characters.count, characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 2
                        continue
                    }
                    inQuotes = false
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    inQuotes = true
                case ",":
                    row.append(field)
                    field = ""
                case "\n", "\r":
                    if !field.isEmpty || !row.isEmpty {
                        row.append(field)
                        rows.append(row)
                        field = ""
                        row = []
                    }
                default:
                    field.append(character)
                }
            }
            index += 1
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }

    private static func amountValue(_ raw: String) -> Double? {
        var text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        var negative = false
        if text.hasPrefix("("), text.hasSuffix(")") {
            negative = true
            text = String(text.dropFirst().dropLast())
        }
        text = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard let value = Double(text) else { return nil }
        return negative ? -value : value
    }

    private static let dateFormats = [
        "MM/dd/yyyy", "M/d/yyyy", "yyyy-MM-dd", "MM/dd/yy", "M/d/yy",
        "MMM d, yyyy", "dd MMM yyyy", "yyyyMMdd",
    ]

    private static func date(from raw: String) -> Date? {
        let text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) {
                return date
            }
        }
        return nil
    }
}
