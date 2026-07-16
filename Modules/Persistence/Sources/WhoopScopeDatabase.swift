import Foundation
internal import GRDB
import WhoopScopeDomain

public struct WhoopScopeDatabase: Sendable {
    private let writer: any DatabaseWriter

    init(writer: any DatabaseWriter) {
        self.writer = writer
    }

    public static func inMemory() throws -> WhoopScopeDatabase {
        let database = WhoopScopeDatabase(writer: try DatabaseQueue())
        try database.migrate()
        return database
    }

    public static func live() throws -> WhoopScopeDatabase {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport.appending(
            path: "WhoopScope",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        let database = WhoopScopeDatabase(
            writer: try DatabasePool(
                path: directory.appending(path: "whoopscope.sqlite").path
            )
        )
        try database.migrate()
        return database
    }

    public func save(_ account: WhoopAccount) async throws {
        let row = WhoopAccountRow(account: account)
        try await writer.write { database in
            try row.save(database)
        }
    }

    public func readAccount() async throws -> WhoopAccount? {
        try await writer.read { database in
            try WhoopAccountRow.fetchOne(database)?.domainValue
        }
    }

    public func activityWatermarks() async throws -> WhoopActivityWatermarks {
        try await writer.read { database in
            WhoopActivityWatermarks(
                cycleStart: try Date.fetchOne(
                    database,
                    sql: "SELECT MAX(start) FROM whoopCycle"
                ),
                recoveryStart: try Date.fetchOne(
                    database,
                    sql: """
                    SELECT MAX(c.start)
                    FROM whoopRecovery r
                    JOIN whoopCycle c ON c.id = r.cycleID
                    """
                ),
                sleepStart: try Date.fetchOne(
                    database,
                    sql: "SELECT MAX(start) FROM whoopSleep"
                ),
                workoutStart: try Date.fetchOne(
                    database,
                    sql: "SELECT MAX(start) FROM whoopWorkout"
                )
            )
        }
    }

    public func saveActivities(
        cycles: [WhoopCycle],
        recoveries: [WhoopRecovery],
        sleeps: [WhoopSleep],
        workouts: [WhoopWorkout],
        synchronizedAt: Date
    ) async throws {
        let encoder = JSONEncoder()
        let cycleRows = try cycles.map { try WhoopCycleRow(value: $0, encoder: encoder) }
        let recoveryRows = try recoveries.map {
            try WhoopRecoveryRow(value: $0, encoder: encoder)
        }
        let sleepRows = try sleeps.map { try WhoopSleepRow(value: $0, encoder: encoder) }
        let workoutRows = try workouts.map {
            try WhoopWorkoutRow(value: $0, encoder: encoder)
        }

        try await writer.write { database in
            for row in cycleRows { try row.save(database) }
            for row in recoveryRows { try row.save(database) }
            for row in sleepRows { try row.save(database) }
            for row in workoutRows { try row.save(database) }
            try WhoopSyncStateRow(id: 1, synchronizedAt: synchronizedAt).save(database)
        }
    }

    public func readArchive() async throws -> WhoopDataArchive? {
        try await writer.read { database in
            guard let account = try WhoopAccountRow.fetchOne(database)?.domainValue else {
                return nil
            }
            let decoder = JSONDecoder()
            let cycles = try WhoopCycleRow
                .order(Column("start").desc)
                .fetchAll(database)
                .map { try decoder.decode(WhoopCycle.self, from: $0.payload) }
            let recoveries = try WhoopRecoveryRow
                .fetchAll(database)
                .map { try decoder.decode(WhoopRecovery.self, from: $0.payload) }
            let sleeps = try WhoopSleepRow
                .order(Column("start").desc)
                .fetchAll(database)
                .map { try decoder.decode(WhoopSleep.self, from: $0.payload) }
            let workouts = try WhoopWorkoutRow
                .order(Column("start").desc)
                .fetchAll(database)
                .map { try decoder.decode(WhoopWorkout.self, from: $0.payload) }
            let synchronizedAt = try WhoopSyncStateRow.fetchOne(database)?.synchronizedAt
                ?? account.syncedAt
            return WhoopDataArchive(
                account: account,
                cycles: cycles,
                recoveries: recoveries,
                sleeps: sleeps,
                workouts: workouts,
                lastSynchronizedAt: synchronizedAt
            )
        }
    }

    public func saveHealthEnrichment(_ payload: HealthEnrichmentPayload) async throws {
        let rows = payload.samples.map { HealthMetricSampleRow(sample: $0) }
        try await writer.write { database in
            for row in rows {
                try row.save(database)
            }
            try HealthImportStateRow(
                id: 1,
                deviceName: payload.deviceName,
                importedAt: payload.generatedAt
            ).save(database)
        }
    }

    public func readHealthEnrichment(
        since startDate: Date? = nil
    ) async throws -> [HealthMetricSample] {
        try await writer.read { database in
            var request = HealthMetricSampleRow.order(Column("date").asc)
            if let startDate {
                request = request.filter(Column("date") >= startDate)
            }
            return try request.fetchAll(database).map(\.domainValue)
        }
    }

    public func readHealthImportStatus() async throws -> HealthImportStatus? {
        try await writer.read { database in
            try HealthImportStateRow.fetchOne(database)?.domainValue
        }
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_create_whoop_account") { database in
            try database.create(table: WhoopAccountRow.databaseTableName) { table in
                table.column("userID", .integer).primaryKey()
                table.column("email", .text).notNull()
                table.column("firstName", .text).notNull()
                table.column("lastName", .text).notNull()
                table.column("heightMeters", .double).notNull()
                table.column("weightKilograms", .double).notNull()
                table.column("maxHeartRate", .integer).notNull()
                table.column("syncedAt", .datetime).notNull()
            }
        }
        migrator.registerMigration("v2_create_whoop_activity_tables") { database in
            try database.create(table: WhoopCycleRow.databaseTableName) { table in
                table.column("id", .integer).primaryKey()
                table.column("start", .datetime).notNull().indexed()
                table.column("updatedAt", .datetime).notNull()
                table.column("payload", .blob).notNull()
            }
            try database.create(table: WhoopRecoveryRow.databaseTableName) { table in
                table.column("cycleID", .integer).primaryKey()
                table.column("updatedAt", .datetime).notNull()
                table.column("payload", .blob).notNull()
            }
            try database.create(table: WhoopSleepRow.databaseTableName) { table in
                table.column("id", .text).primaryKey()
                table.column("cycleID", .integer).notNull().indexed()
                table.column("start", .datetime).notNull().indexed()
                table.column("updatedAt", .datetime).notNull()
                table.column("isNap", .boolean).notNull()
                table.column("payload", .blob).notNull()
            }
            try database.create(table: WhoopWorkoutRow.databaseTableName) { table in
                table.column("id", .text).primaryKey()
                table.column("start", .datetime).notNull().indexed()
                table.column("updatedAt", .datetime).notNull()
                table.column("payload", .blob).notNull()
            }
            try database.create(table: WhoopSyncStateRow.databaseTableName) { table in
                table.column("id", .integer).primaryKey()
                table.column("synchronizedAt", .datetime).notNull()
            }
        }
        migrator.registerMigration("v3_create_health_enrichment_tables") { database in
            try database.create(table: HealthMetricSampleRow.databaseTableName) { table in
                table.column("kind", .text).notNull()
                table.column("date", .datetime).notNull().indexed()
                table.column("value", .double).notNull()
                table.column("unit", .text).notNull()
                table.column("source", .text).notNull()
                table.primaryKey(["kind", "date", "source"])
            }
            try database.create(table: HealthImportStateRow.databaseTableName) { table in
                table.column("id", .integer).primaryKey()
                table.column("deviceName", .text).notNull()
                table.column("importedAt", .datetime).notNull()
            }
        }
        try migrator.migrate(writer)
    }
}

public struct HealthImportStatus: Equatable, Sendable {
    public let deviceName: String
    public let importedAt: Date

    public init(deviceName: String, importedAt: Date) {
        self.deviceName = deviceName
        self.importedAt = importedAt
    }
}

public struct WhoopActivityWatermarks: Equatable, Sendable {
    public let cycleStart: Date?
    public let recoveryStart: Date?
    public let sleepStart: Date?
    public let workoutStart: Date?

    public init(
        cycleStart: Date?,
        recoveryStart: Date?,
        sleepStart: Date?,
        workoutStart: Date?
    ) {
        self.cycleStart = cycleStart
        self.recoveryStart = recoveryStart
        self.sleepStart = sleepStart
        self.workoutStart = workoutStart
    }
}

private struct WhoopAccountRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "whoopAccount"

    let userID: Int64
    let email: String
    let firstName: String
    let lastName: String
    let heightMeters: Double
    let weightKilograms: Double
    let maxHeartRate: Int
    let syncedAt: Date

    init(account: WhoopAccount) {
        userID = account.profile.userID
        email = account.profile.email
        firstName = account.profile.firstName
        lastName = account.profile.lastName
        heightMeters = account.bodyMeasurements.heightMeters
        weightKilograms = account.bodyMeasurements.weightKilograms
        maxHeartRate = account.bodyMeasurements.maxHeartRate
        syncedAt = account.syncedAt
    }

    var domainValue: WhoopAccount {
        WhoopAccount(
            profile: WhoopUserProfile(
                userID: userID,
                email: email,
                firstName: firstName,
                lastName: lastName
            ),
            bodyMeasurements: WhoopBodyMeasurements(
                heightMeters: heightMeters,
                weightKilograms: weightKilograms,
                maxHeartRate: maxHeartRate
            ),
            syncedAt: syncedAt
        )
    }
}

private struct HealthMetricSampleRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "healthMetricSample"

    let kind: String
    let date: Date
    let value: Double
    let unit: String
    let source: String

    init(sample: HealthMetricSample) {
        kind = sample.kind.rawValue
        date = sample.date
        value = sample.value
        unit = sample.unit
        source = sample.source
    }

    var domainValue: HealthMetricSample {
        HealthMetricSample(
            kind: HealthMetricKind(rawValue: kind)!,
            date: date,
            value: value,
            unit: unit,
            source: source
        )
    }
}

private struct HealthImportStateRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "healthImportState"

    let id: Int
    let deviceName: String
    let importedAt: Date

    var domainValue: HealthImportStatus {
        HealthImportStatus(deviceName: deviceName, importedAt: importedAt)
    }
}

private struct WhoopCycleRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "whoopCycle"

    let id: Int64
    let start: Date
    let updatedAt: Date
    let payload: Data

    init(value: WhoopCycle, encoder: JSONEncoder) throws {
        id = value.id
        start = value.start
        updatedAt = value.updatedAt
        payload = try encoder.encode(value)
    }
}

private struct WhoopRecoveryRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "whoopRecovery"

    let cycleID: Int64
    let updatedAt: Date
    let payload: Data

    init(value: WhoopRecovery, encoder: JSONEncoder) throws {
        cycleID = value.cycleID
        updatedAt = value.updatedAt
        payload = try encoder.encode(value)
    }
}

private struct WhoopSleepRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "whoopSleep"

    let id: String
    let cycleID: Int64
    let start: Date
    let updatedAt: Date
    let isNap: Bool
    let payload: Data

    init(value: WhoopSleep, encoder: JSONEncoder) throws {
        id = value.id.uuidString
        cycleID = value.cycleID
        start = value.start
        updatedAt = value.updatedAt
        isNap = value.isNap
        payload = try encoder.encode(value)
    }
}

private struct WhoopWorkoutRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "whoopWorkout"

    let id: String
    let start: Date
    let updatedAt: Date
    let payload: Data

    init(value: WhoopWorkout, encoder: JSONEncoder) throws {
        id = value.id.uuidString
        start = value.start
        updatedAt = value.updatedAt
        payload = try encoder.encode(value)
    }
}

private struct WhoopSyncStateRow: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "whoopSyncState"

    let id: Int
    let synchronizedAt: Date
}
