//
//  MockDatabaseService.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

//import Testing


// Mock do Firebase Service
final class MockFirebaseService: FirebaseServiceProtocol {
  var eventsLogged: [AnalyticsEvent] = []
  var errorsRecorded: [Error] = []

  func configure() {}

  func logEvent(_ event: AnalyticsEvent) {
    eventsLogged.append(event)
  }

  func recordError(_ error: Error, context: String) {
    errorsRecorded.append(error)
  }

  func recordNonFatalError(_ error: Error, context: String) {
    errorsRecorded.append(error)
  }

  func setUserID(_ userID: String) {}
  func setUserProperty(_ value: String?, forName name: String) {}
}
