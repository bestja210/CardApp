//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Fluent
import Foundation

final class DeckCategoryPivot: Model {
  static let schema = "deck-category-pivot"
  
  @ID
  var id: UUID?
  
  @Parent(key: "deckID")
  var deck: Deck
  
  @Parent(key: "categoryID")
  var category: Category
  
  init() {}
  
  init(id: UUID? = nil, deck: Deck, category: Category) throws {
    self.id = id
    self.$deck.id = try deck.requireID()
    self.$category.id = try category.requireID()
  }
}
