//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor
import Fluent

struct CreateDeckCategoryPivot: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("deck-category-pivot")
      .id()
      .field("deckID", .uuid, .required, .references("decks", "id", onDelete: .cascade))
      .field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("deck-category-pivot").delete()
  }
}
