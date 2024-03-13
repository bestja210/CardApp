//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor
import Fluent

struct UserMiddleware: ModelMiddleware {
  func create(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
    User.query(on: db).filter(\.$username == model.username).count().flatMap { count in
      guard count == 0 else {
        return db.eventLoop.future(error: Abort(.badRequest, reason: "Username already exists"))
      }
      return next.create(model, on: db).map {
        db.logger.debug("Created user wth username \(model.username)")
      }
    }
  }
}
