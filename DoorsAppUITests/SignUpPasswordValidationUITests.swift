//
//  SignUpPasswordValidationUITests.swift
//  DoorsAppUITests
//

import XCTest

final class SignUpPasswordValidationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()

        let signUpButton = app.buttons["navigate_to_sign_up"]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 5))
        signUpButton.tap()
    }

    // MARK: - Tests

    @MainActor
    func testRequirements_initialState_allNeutral() {
        XCTAssertTrue(requirementElement("password_req_length").waitForExistence(timeout: 3))
        XCTAssertEqual(requirementElement("password_req_length").value as? String, "neutral")
        XCTAssertEqual(requirementElement("password_req_uppercase").value as? String, "neutral")
        XCTAssertEqual(requirementElement("password_req_number").value as? String, "neutral")
        XCTAssertEqual(requirementElement("password_req_symbol").value as? String, "neutral")
    }

    @MainActor
    func testRequirements_validPassword_allMet() {
        typeInPasswordField("Test1!")
        waitForValue("met", element: requirementElement("password_req_length"))

        XCTAssertEqual(requirementElement("password_req_length").value as? String, "met")
        XCTAssertEqual(requirementElement("password_req_uppercase").value as? String, "met")
        XCTAssertEqual(requirementElement("password_req_number").value as? String, "met")
        XCTAssertEqual(requirementElement("password_req_symbol").value as? String, "met")
    }

    @MainActor
    func testRequirements_partialPassword_someUnmet() {
        // "abc" — 3 chars, sem maiúscula, número ou símbolo
        typeInPasswordField("abc")
        waitForValue("unmet", element: requirementElement("password_req_length"))

        XCTAssertEqual(requirementElement("password_req_length").value as? String, "unmet")
        XCTAssertEqual(requirementElement("password_req_uppercase").value as? String, "unmet")
        XCTAssertEqual(requirementElement("password_req_number").value as? String, "unmet")
        XCTAssertEqual(requirementElement("password_req_symbol").value as? String, "unmet")
    }

    @MainActor
    func testRequirements_clearPassword_returnsNeutral() {
        let text = "Test1!"
        typeInPasswordField(text)
        waitForValue("met", element: requirementElement("password_req_length"))

        deleteInPasswordField(count: text.count)
        waitForValue("neutral", element: requirementElement("password_req_length"))

        XCTAssertEqual(requirementElement("password_req_length").value as? String, "neutral")
        XCTAssertEqual(requirementElement("password_req_uppercase").value as? String, "neutral")
        XCTAssertEqual(requirementElement("password_req_number").value as? String, "neutral")
        XCTAssertEqual(requirementElement("password_req_symbol").value as? String, "neutral")
    }

    // MARK: - Helpers

    private func requirementElement(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func waitForValue(_ value: String, element: XCUIElement, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        wait(for: [expectation], timeout: timeout)
    }

    private func typeInPasswordField(_ text: String) {
        let field = app.secureTextFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(field.isHittable)
        field.tap()

        // Dismiss "Use Strong Password" autofill suggestion se aparecer
        let chooseOwn = app.buttons["Choose My Own Password"]
        if chooseOwn.waitForExistence(timeout: 2) {
            chooseOwn.tap()
        }

        field.typeText(text)
    }

    private func deleteInPasswordField(count: Int) {
        let field = app.secureTextFields.firstMatch
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count))
    }
}
