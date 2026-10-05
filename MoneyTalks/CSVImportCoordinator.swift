//
//  CSVImportCoordinator.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import Foundation
import Observation

@Observable
@MainActor
final class CSVImportCoordinator {

    var isImportingCSV = false
    var errorMessage: String?
    var skippedItemsMessage: String?

    func importRevenues(from urls: [URL], into repository: RevenueRepository) {
        let importer = RevenueCSVImporter()
        do {
            var importedRevenues: [Revenue] = []
            for url in urls {
                importedRevenues.append(contentsOf: try importer.revenues(contentsOf: url))
            }
            let skippedCount = importedRevenues.count - repository.add(contentsOf: importedRevenues)
            skippedItemsMessage = skippedCount > 0 ? Self.skippedMessage(skippedCount: skippedCount, totalCount: importedRevenues.count) : nil
            errorMessage = nil
        } catch {
            skippedItemsMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    private static func skippedMessage(skippedCount: Int, totalCount: Int) -> String {
        let itemLabel = skippedCount == 1 ? "item was" : "items were"
        let subject = skippedCount == 1 ? "it was" : "they were"
        return "\(skippedCount) of \(totalCount) \(itemLabel) skipped, because \(subject) already imported."
    }
}
