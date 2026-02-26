import SwiftData
import Foundation

// MARK: - Schema V1 (Current)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ClipboardItem.self,
            ClipboardItemContent.self,
            ClipGroup.self,
            Snippet.self,
        ]
    }
}

// MARK: - Migration Plan

enum BoboMindMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
