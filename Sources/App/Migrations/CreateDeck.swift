//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor
import Fluent

struct CreateDeck: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("decks")
      .id()
      .field("title", .string, .required)
      .field("userID", .uuid, .required, .references("users", "id"))
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("decks").delete()
  }
}
