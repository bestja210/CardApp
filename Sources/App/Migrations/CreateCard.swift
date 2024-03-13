//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor
import Fluent

struct CreateCard: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("cards")
      .id()
      .field("front", .string, .required)
      .field("back", .string, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("cards").delete()
  }
}
