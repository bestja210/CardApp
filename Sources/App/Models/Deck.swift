//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor
import Fluent

final class Deck: Model, Content {
  static let schema = "decks"
  
  @ID
  var id: UUID?
  
  @Field(key: "title")
  var title: String
  
  @Parent(key: "userID")
  var user: User
  
  @Siblings(through: CardDeckPivot.self, from: \.$deck, to: \.$card)
  var cards: [Card]
  
  @Siblings(through: DeckCategoryPivot.self, from: \.$deck, to: \.$category)
  var categories: [Category]
  
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?
  
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?
  
  init() { }
  
  init(id: UUID? = nil, title: String, userID: User.IDValue) {
    self.id = id
    self.title = title
    self.$user.id = userID
  }
}
