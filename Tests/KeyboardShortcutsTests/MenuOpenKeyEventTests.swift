import Testing
import AppKit
@testable import KeyboardShortcuts

@Suite("Menu-open key event Tests", .serialized)
struct MenuOpenKeyEventTests {
	private static let shortcut = KeyboardShortcuts.Shortcut(.f19, modifiers: [.command, .option, .control])

	private static func keyEvent(_ type: NSEvent.EventType, timestamp: TimeInterval) throws -> NSEvent {
		try #require(NSEvent.keyEvent(
			with: type,
			location: .zero,
			modifierFlags: [.command, .option, .control],
			timestamp: timestamp,
			windowNumber: 0,
			context: nil,
			characters: "",
			charactersIgnoringModifiers: "",
			isARepeat: false,
			keyCode: UInt16(shortcut.carbonKeyCode)
		))
	}

	@Test("The same key event delivered repeatedly fires the shortcut once")
	func repeatedDeliveryFiresOnce() throws {
		var keyDownCount = 0
		var keyUpCount = 0

		let hotKey = try #require(HotKey(
			carbonKeyCode: Self.shortcut.carbonKeyCode,
			carbonModifiers: Self.shortcut.carbonModifiers,
			onKeyDown: { keyDownCount += 1 },
			onKeyUp: { keyUpCount += 1 }
		))

		let keyDown = try Self.keyEvent(.keyDown, timestamp: 1000)
		let keyUp = try Self.keyEvent(.keyUp, timestamp: 1000.1)

		// e.g. run-loop monitor twice, then AppKit monitor
		for event in [keyDown, keyDown, keyDown, keyUp, keyUp] {
			#expect(HotKeyCenter.shared.handleKeyEvent(event) == nil)
		}

		#expect(keyDownCount == 1)
		#expect(keyUpCount == 1)

		// the next press is a new event
		_ = HotKeyCenter.shared.handleKeyEvent(try Self.keyEvent(.keyDown, timestamp: 1002))
		_ = HotKeyCenter.shared.handleKeyEvent(try Self.keyEvent(.keyUp, timestamp: 1002.1))

		#expect(keyDownCount == 2)
		#expect(keyUpCount == 2)

		withExtendedLifetime(hotKey) {}
	}

	@Test("Key events of other keys pass through")
	func unrelatedEventsPassThrough() throws {
		let event = try #require(NSEvent.keyEvent(
			with: .keyUp,
			location: .zero,
			modifierFlags: [],
			timestamp: 2000,
			windowNumber: 0,
			context: nil,
			characters: "a",
			charactersIgnoringModifiers: "a",
			isARepeat: false,
			keyCode: 0
		))

		#expect(HotKeyCenter.shared.handleKeyEvent(event) === event)
	}
}
