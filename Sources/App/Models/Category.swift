//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor
import Fluent

final class Category: Content, Model {
  static let schema = "categories"
  
  @ID
  var id: UUID?
  
  @Field(key: "name")
  var name: String
  
  @Siblings(through: DeckCategoryPivot.self, from: \.$category, to: \.$deck)
  var decks: [Deck]
  
  init() {}
  
  init(id: UUID? = nil, name: String) {
    self.id = id
    self.name = name
  }
}
