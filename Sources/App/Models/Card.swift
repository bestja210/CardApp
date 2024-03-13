//
//  File.swift
//  
//
//  Created by Jacob Best on 2/16/24.
//

import Fluent
import Vapor

final class Card: Model, Content {
  static let schema = "cards"
  
  @ID
  var id: UUID?
  
  @Field(key: "front")
  var front: String
  
  @Field(key: "back")
  var back: String
  
  @Siblings(through: CardDeckPivot.self, from: \.$card, to: \.$deck)
  var decks: [Deck]
  
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?
  
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?
  
  init() { }
  
  init(id: UUID? = nil, front: String, back: String) {
    self.id = id
    self.front = front
    self.back = back
  }
}
