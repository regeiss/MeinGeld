//
//  Metrics.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 23/07/25.
//

import Foundation
import os.signpost

final class PerformanceMonitor {
  private let performanceLog = OSLog(
    subsystem: "MeinGeld",
    category: "Performance"
  )
  private let logger = Logger(subsystem: "MeinGeld", category: "Performance")

  func measureTransaction<T>(_ operation: String, block: () throws -> T)
    rethrows -> T
  {
    let signpost = OSSignpostID(log: performanceLog)
    os_signpost(
      .begin,
      log: performanceLog,
      name: "Transaction",
      signpostID: signpost,
      "%{public}s",
      operation
    )

    defer {
      os_signpost(
        .end,
        log: performanceLog,
        name: "Transaction",
        signpostID: signpost
      )
    }

    return try block()
  }
}
