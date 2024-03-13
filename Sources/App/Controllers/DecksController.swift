//
//  File.swift
//  
//
//  Created by Jacob Best on 2/9/24.
//

import Vapor
import Fluent
import SQLKit

struct DecksController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let decksRoutes = routes.grouped("api","decks")
    decksRoutes.get(use: getAllHandler)
    decksRoutes.get(":deckID", use: getHandler)
    decksRoutes.get("search", use: searchHandler)
    decksRoutes.get("first", use: getFirstHandler)
    decksRoutes.get("sorted", use: sortedHandler)
    decksRoutes.get(":deckID", "user", use: getUserHandler)
    decksRoutes.get(":deckID", "categories", use: getCategoriesHandler)
    decksRoutes.get(":deckID", "cards", use: getCardsHandler)
    decksRoutes.get("mostRecent", use: getMostRecentDecks)
    decksRoutes.get("cards", use: getAllDecksWithCards)
    decksRoutes.get("raw", use: getAllDecksRaw)
    
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = decksRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.post(use: createHandler)
    tokenAuthGroup.delete(":deckID", use: deleteHandler)
    tokenAuthGroup.put(":deckID", use: updateHandler)
    tokenAuthGroup.post(":deckID", "categories", ":categoryID", use: addCategoriesHandler)
    tokenAuthGroup.delete(":deckID", "categories", ":categoryID", use: removeCategoriesHandler)
  }
  
  func getAllHandler(_ req: Request) -> EventLoopFuture<[Deck]> {
    Deck.query(on: req.db).all()
  }
  
  func createHandler(_ req: Request) throws -> EventLoopFuture<Deck> {
    let data = try req.content.decode(CreateDeckData.self)
    let user = try req.auth.require(User.self)
    let deck = try Deck(title: data.title, userID: user.requireID())
    return deck.save(on: req.db).map { deck }
  }
  
  func getHandler(_ req: Request) throws -> EventLoopFuture<Deck> {
    Deck.find(req.parameters.get("deckID"), on: req.db)
      .unwrap(or: Abort(.notFound))
  }
  
  func updateHandler(_ req: Request) throws -> EventLoopFuture<Deck> {
    let updatedData = try req.content.decode(CreateDeckData.self)
    let user = try req.auth.require(User.self)
    let userID = try user.requireID()
    return Deck.find(req.parameters.get("deckID"), on: req.db)
      .unwrap(or: Abort(.notFound)).flatMap { deck in
        deck.title = updatedData.title
        deck.$user.id = userID
        return deck.save(on: req.db).map {
          deck
        }
      }
  }
  
  func deleteHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
    Deck.find(req.parameters.get("deckID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { deck in
        deck.delete(on: req.db)
          .transform(to: .noContent)
      }
  }
  
  func searchHandler(_ req: Request) throws -> EventLoopFuture<[Deck]> {
    guard let searchTerm = req
      .query[String.self, at: "term"] else {
      throw Abort(.badRequest)
    }
    return Deck.query(on: req.db)
      .filter(\.$title == searchTerm)
      .all()
  }
  
  func getFirstHandler(_ req: Request) -> EventLoopFuture<Deck> {
    return Deck.query(on: req.db)
      .first()
      .unwrap(or: Abort(.notFound))
  }
  
  func sortedHandler(_ req: Request) -> EventLoopFuture<[Deck]> {
    return Deck.query(on: req.db).sort(\.$title, .ascending).all()
  }
  
  func getUserHandler(_ req: Request) -> EventLoopFuture<User.Public> {
    Deck.find(req.parameters.get("deckID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { deck in
        deck.$user.get(on: req.db).convertToPublic()
      }
  }
  
  func addCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
    let deckQuery = Deck.find(req.parameters.get("deckID"), on: req.db).unwrap(or: Abort(.notFound))
    let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
    return deckQuery.and(categoryQuery).flatMap { deck, category in
      deck.$categories.attach(category, on: req.db)
        .transform(to: .created)
    }
  }
  
  func getCategoriesHandler(_ req: Request) -> EventLoopFuture<[Category]> {
    Deck.find(req.parameters.get("deckID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { deck in
        deck.$categories.query(on: req.db).all()
      }
  }
  
  func getCardsHandler(_ req: Request) -> EventLoopFuture<[Card]> {
    Deck.find(req.parameters.get("deckID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { deck in
        deck.$cards.query(on: req.db).all()
      }
  }
  
  func removeCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
    let deckQuery = Deck.find(req.parameters.get("deckID"), on: req.db).unwrap(or: Abort(.notFound))
    let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
    return deckQuery.and(categoryQuery).flatMap { deck, category in
      deck.$categories.detach(category, on: req.db)
        .transform(to: .noContent)
    }
  }
  
  func getMostRecentDecks(_ req: Request) -> EventLoopFuture<[Deck]> {
    Deck.query(on: req.db).sort(\.$updatedAt, .descending).all()
  }
  
  func getAllDecksWithCards(_ req: Request) -> EventLoopFuture<[DeckWithCards]> {
    Deck.query(on: req.db).with(\.$cards)
      .all().map { decks in
        decks.map { deck in
          let deckCards = deck.cards
          return DeckWithCards(
            id: deck.id,
            title: deck.title,
            cards: deckCards)
        }
      }
  }
  
  func getAllDecksRaw(_ req: Request) throws -> EventLoopFuture<[Deck]> {
    guard let sql = req.db as? SQLDatabase else {
      throw Abort(.internalServerError)
    }
    return sql.raw("SELECT * FROM decks").all(decoding: Deck.self)
  }
}

struct CreateDeckData: Content {
  let title: String
}

struct DeckWithCards: Content {
  let id: UUID?
  let title: String
  let cards: [Card]
}
