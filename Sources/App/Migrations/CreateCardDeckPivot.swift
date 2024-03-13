//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

import Vapor
import Fluent

struct CreateCardDeckPivot: Migration {
  func prepare(on database: any Database) -> EventLoopFuture<Void> {
    database.schema("card-deck-pivot")
      .id()
      .field("cardID", .uuid, .required, .references("cards", "id", onDelete: .cascade))
      .field("deckID", .uuid, .required, .references("decks", "id", onDelete: .cascade))
      .create()
  }
  
  func revert(on database: any Database) -> EventLoopFuture<Void> {
    database.schema("card-deck-pivot").delete()
  }
}
