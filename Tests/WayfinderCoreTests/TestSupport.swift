// Minimal assertion adapter for Command Line Tools installations without XCTest.
// The same CoreTests.swift runs under real XCTest in a full Xcode installation.
import Foundation
class XCTestCase {}
var testFailures = 0
func fail(_ message: String, file: StaticString, line: UInt) {
    testFailures += 1
    print("FAIL \(file):\(line): \(message)")
}
func XCTAssertEqual<T: Equatable>(_ actual: @autoclosure () throws -> T, _ expected: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do { let a = try actual(); let e = try expected(); if a != e { fail("\(a) != \(e)", file: file, line: line) } }
    catch { fail(error.localizedDescription, file: file, line: line) }
}
func XCTAssertTrue(_ actual: @autoclosure () throws -> Bool, file: StaticString = #filePath, line: UInt = #line) {
    do { if try !actual() { fail("Expected true", file: file, line: line) } }
    catch { fail(error.localizedDescription, file: file, line: line) }
}
func XCTAssertFalse(_ actual: @autoclosure () throws -> Bool, file: StaticString = #filePath, line: UInt = #line) {
    do { if try actual() { fail("Expected false", file: file, line: line) } }
    catch { fail(error.localizedDescription, file: file, line: line) }
}
func XCTAssertNil<T>(_ actual: @autoclosure () -> T?, file: StaticString = #filePath, line: UInt = #line) {
    if actual() != nil { fail("Expected nil", file: file, line: line) }
}
func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do { _ = try expression(); fail("Expected an error", file: file, line: line) } catch {}
}
func XCTUnwrap<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) throws -> T {
    guard let value else {
        fail("Expected non-nil", file: file, line: line)
        throw NSError(domain: "Tests", code: 1)
    }
    return value
}
