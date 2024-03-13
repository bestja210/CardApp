//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor
import Fluent

struct CardsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let cardsRoute = routes.grouped("api", "cards")
    cardsRoute.get(use: getAllHandler)
    cardsRoute.get(":cardID", use: getHandler)
    cardsRoute.get(":cardID", "decks", use: getDecksHandler)
    cardsRoute.get("search", use: searchHandler)
    cardsRoute.get("mostRecent", use: getMostRecentCards)
    
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = cardsRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.post(use: createHandler)
    tokenAuthGroup.delete(":cardID", use: deleteHandler)
    tokenAuthGroup.put(":cardID", use: updateHandler)
    tokenAuthGroup.post(":cardID", "decks", ":deckID", use: addDecksHandler)
    tokenAuthGroup.delete(":cardID", "decks", ":deckID", use: removeDecksHandler)
  }
  
  func createHandler(_ req: Request) throws -> EventLoopFuture<Card> {
    let card = try req.content.decode(Card.self)
    return card.save(on: req.db).map { card }
  }
  
  func getAllHandler(_ req: Request) -> EventLoopFuture<[Card]> {
    Card.query(on: req.db).all()
  }
  
  func getHandler(_ req: Request) -> EventLoopFuture<Card> {
    Card.find(req.parameters.get("cardID"), on: req.db)
      .unwrap(or: Abort(.notFound))
  }
  
  func updateHandler(_ req: Request) throws -> EventLoopFuture<Card> {
    let updateData = try req.content.decode(Card.self)
    return Card.find(req.parameters.get("cardID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { card in
      card.front = updateData.front
      card.back = updateData.back
      return card.save(on: req.db).map {
        card
      }
    }
  }
  
  func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
    Card.find(req.parameters.get("cardID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { card in
        card.delete(on: req.db)
          .transform(to: .noContent)
      }
  }
  
  func searchHandler(_ req: Request) throws -> EventLoopFuture<[Card]> {
    guard let searchTerm = req.query[String.self, at: "term"] else {
      throw Abort(.badRequest)
    }
    return Card.query(on: req.db).group(.or) { or in
      or.filter(\.$front == searchTerm)
      or.filter(\.$back == searchTerm)
    }.all()
  }
  
  func addDecksHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
    let cardQuery = Card.find(req.parameters.get("cardID"), on: req.db).unwrap(or: Abort(.notFound))
    let deckQuery = Deck.find(req.parameters.get("deckID"), on: req.db).unwrap(or: Abort(.notFound))
    return cardQuery.and(deckQuery).flatMap { card, deck in
      card.$decks.attach(deck, on: req.db)
        .transform(to: .created)
    }
  }
  
  func getDecksHandler(_ req: Request) -> EventLoopFuture<[Deck]> {
    Card.find(req.parameters.get("cardID"), on: req.db).unwrap(or: Abort(.notFound))
      .flatMap { card in
        card.$decks.get(on: req.db)
      }
  }
  
  func removeDecksHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
    let cardQuery = Card.find(req.parameters.get("cardID"), on: req.db).unwrap(or: Abort(.notFound))
    let deckQuery = Deck.find(req.parameters.get("deckID"), on: req.db).unwrap(or: Abort(.notFound))
    return cardQuery.and(deckQuery).flatMap { card, deck in
      card.$decks.detach(deck, on: req.db).transform(to: .noContent)
    }
  }
  
  func getMostRecentCards(_ req: Request) -> EventLoopFuture<[Card]> {
    Card.query(on: req.db).sort(\.$updatedAt, .descending).all()
  }
}
