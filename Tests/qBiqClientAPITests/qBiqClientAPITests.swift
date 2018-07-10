import XCTest
@testable import qBiqClientAPI

final class qBiqClientAPITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(qBiqClientAPI().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
