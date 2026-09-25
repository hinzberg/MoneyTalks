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

    func importRevenues(from urls: [URL], into repository: RevenueRepository) {
        let importer = RevenueCSVImporter()
        do {
            var importedRevenues: [Revenue] = []
            for url in urls {
                importedRevenues.append(contentsOf: try importer.revenues(contentsOf: url))
            }
            repository.add(contentsOf: importedRevenues)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
