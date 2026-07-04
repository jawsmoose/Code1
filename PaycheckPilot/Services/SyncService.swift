import Foundation
import SwiftData
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Backup snapshot (Codable mirror of the SwiftData store)

struct BackupSnapshot: Codable {

    struct AccountDTO: Codable {
        var name: String
        var institution: String
        var kind: String
        var currentBalance: Double
        var apr: Double
        var minimumPayment: Double
    }

    struct TransactionDTO: Codable {
        var date: Date
        var payee: String
        var amount: Double
        var category: String
    }

    struct GoalDTO: Codable {
        var name: String
        var iconName: String
        var targetAmount: Double
        var savedAmount: Double
        var targetDate: Date
        var priority: Int
    }

    struct SettingsDTO: Codable {
        var paycheckAmount: Double
        var payFrequency: String
        var payoffStrategy: String
        var debtWeight: Double
        var goalWeight: Double
        var investWeight: Double
        var discretionaryTrimPercent: Double
    }

    var exportedAt: Date
    var accounts: [AccountDTO]
    var transactions: [TransactionDTO]
    var goals: [GoalDTO]
    var settings: SettingsDTO?

    @MainActor
    static func build(from context: ModelContext) throws -> BackupSnapshot {
        let accounts = try context.fetch(FetchDescriptor<FinancialAccount>())
        let transactions = try context.fetch(FetchDescriptor<BankTransaction>())
        let goals = try context.fetch(FetchDescriptor<SavingsGoal>())
        let settings = try context.fetch(FetchDescriptor<AppSettings>()).first

        return BackupSnapshot(
            exportedAt: Date(),
            accounts: accounts.map {
                AccountDTO(
                    name: $0.name,
                    institution: $0.institution,
                    kind: $0.kindRaw,
                    currentBalance: $0.currentBalance,
                    apr: $0.apr,
                    minimumPayment: $0.minimumPayment)
            },
            transactions: transactions.map {
                TransactionDTO(date: $0.date, payee: $0.payee, amount: $0.amount, category: $0.categoryRaw)
            },
            goals: goals.map {
                GoalDTO(
                    name: $0.name,
                    iconName: $0.iconName,
                    targetAmount: $0.targetAmount,
                    savedAmount: $0.savedAmount,
                    targetDate: $0.targetDate,
                    priority: $0.priority)
            },
            settings: settings.map {
                SettingsDTO(
                    paycheckAmount: $0.paycheckAmount,
                    payFrequency: $0.payFrequencyRaw,
                    payoffStrategy: $0.payoffStrategyRaw,
                    debtWeight: $0.debtWeight,
                    goalWeight: $0.goalWeight,
                    investWeight: $0.investWeight,
                    discretionaryTrimPercent: $0.discretionaryTrimPercent)
            })
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

// MARK: - Sync manager

/// Backs the user's data up on every plan regeneration (when enabled).
/// Always writes a local JSON backup; when the Firebase SDK is linked and
/// GoogleService-Info.plist is present, it also mirrors the snapshot to
/// Cloud Firestore. The app compiles and runs fully offline without Firebase —
/// see the README for the two-step Firestore setup.
final class SyncManager: ObservableObject {

    static let shared = SyncManager()

    @Published var statusMessage = "Not backed up yet"
    @Published var lastSync: Date?

    private init() {}

    var isFirebaseAvailable: Bool {
        #if canImport(FirebaseFirestore)
        return true
        #else
        return false
        #endif
    }

    func configureIfNeeded() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        #endif
    }

    @MainActor
    func syncIfEnabled(context: ModelContext) {
        let settings = PlanService.fetchOrCreateSettings(in: context)
        guard settings.cloudSyncEnabled else { return }
        syncNow(context: context)
    }

    @MainActor
    func syncNow(context: ModelContext) {
        do {
            let snapshot = try BackupSnapshot.build(from: context)
            let data = try snapshot.encoded()
            try writeLocalBackup(data)

            #if canImport(FirebaseFirestore)
            uploadToFirestore(data)
            #else
            lastSync = Date()
            statusMessage = "Local backup saved \(Date().formatted(date: .abbreviated, time: .shortened))"
            #endif
        } catch {
            statusMessage = "Backup failed: \(error.localizedDescription)"
        }
    }

    var localBackupURL: URL? {
        try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("PaycheckPilotBackup.json")
    }

    private func writeLocalBackup(_ data: Data) throws {
        guard let url = localBackupURL else { return }
        try data.write(to: url, options: .atomic)
    }

    #if canImport(FirebaseFirestore)
    private func uploadToFirestore(_ data: Data) {
        configureIfNeeded()
        guard FirebaseApp.app() != nil else {
            statusMessage = "Add GoogleService-Info.plist to finish Firebase setup"
            return
        }
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            statusMessage = "Could not serialize backup for Firestore"
            return
        }
        Firestore.firestore()
            .collection("backups")
            .document(Self.deviceIdentifier)
            .setData(json) { [weak self] error in
                DispatchQueue.main.async {
                    if let error {
                        self?.statusMessage = "Cloud sync failed: \(error.localizedDescription)"
                    } else {
                        self?.lastSync = Date()
                        self?.statusMessage = "Synced to Firestore \(Date().formatted(date: .abbreviated, time: .shortened))"
                    }
                }
            }
    }
    #endif

    private static var deviceIdentifier: String {
        let key = "paycheckpilot.device.id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }
}
