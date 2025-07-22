//
//  MockErrorManager.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import SwiftData
//import Testing


final class MockErrorManager: ErrorManagerProtocol {
  var handledErrors: [(Error, String)] = []
  var warnings: [(String, String)] = []
  var infos: [(String, String)] = []

  func handle(_ error: Error, context: String) {
    handledErrors.append((error, context))
  }

  func handleNonFatal(_ error: Error, context: String) {
    handledErrors.append((error, context))
  }

  func logWarning(_ message: String, context: String) {
    warnings.append((message, context))
  }

  func logInfo(_ message: String, context: String) {
    infos.append((message, context))
  }
}
