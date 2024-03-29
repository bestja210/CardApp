//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

@testable import App
@testable import XCTVapor

extension Application {
  static func testable() throws -> Application {
    let app = Application(.testing)
    try configure(app)
    
    try app.autoRevert().wait()
    try app.autoMigrate().wait()
    
    return app
  }
}

extension XCTApplicationTester {
  public func login(
    user: User
  ) throws -> Token {
    var request = XCTHTTPRequest(
      method: .POST,
      url: .init(path: "/api/users/login"),
      headers: [:],
      body: ByteBufferAllocator().buffer(capacity: 0)
    )
    request.headers.basicAuthorization = .init(username: user.username, password: "password")
    let response = try performTest(request: request)
    return try response.content.decode(Token.self)
  }
  
  @discardableResult
  public func test(
    _ method: HTTPMethod,
    _ path: String,
    headers: HTTPHeaders = [:],
    body: ByteBuffer? = nil,
    loggedInRequest: Bool = false,
    loggedInUser: User? = nil,
    file: StaticString = #file,
    line: UInt = #line,
    beforeRequest: (inout XCTHTTPRequest) throws -> () = { _ in },
    afterResponse: (XCTHTTPResponse) throws -> () = { _ in }
  ) throws -> XCTApplicationTester {
    var request = XCTHTTPRequest(
      method: method,
      url: .init(path: path),
      headers: headers,
      body: body ?? ByteBufferAllocator().buffer(capacity: 0)
    )
    
    if (loggedInRequest || loggedInUser != nil) {
      let userToLogin: User
      if let user = loggedInUser {
        userToLogin = user
      } else {
        userToLogin = User(firstName: "Admin", lastName: "1", username: "admin1", password: "password")
      }
      
      let token = try login(user: userToLogin)
      request.headers.bearerAuthorization = .init(token: token.value)
    }
    
    try beforeRequest(&request)
    
    do {
      let response = try performTest(request: request)
      try afterResponse(response)
    } catch {
      XCTFail("\(error)", file: (file), line: line)
      throw error
    }
    return self
  }
}

