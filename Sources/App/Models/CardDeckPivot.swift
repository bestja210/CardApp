//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

import Fluent
import Foundation

final class CardDeckPivot: Model {
  static let schema = "card-deck-pivot"
  
  @ID
  var id: UUID?
  
  @Parent(key: "cardID")
  var card: Card
  
  @Parent(key: "deckID")
  var deck: Deck
  
  init() {}
  
  init(id: UUID? = nil, card: Card, deck: Deck) throws {
    self.id = id
    self.$card.id = try card.requireID()
    self.$deck.id = try deck.requireID()
  }
}
