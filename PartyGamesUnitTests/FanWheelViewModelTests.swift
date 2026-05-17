import XCTest
@testable import PartyGames

@MainActor
final class FanWheelViewModelTests: XCTestCase {
    var vm: FanWheelViewModel!

    override func setUp() {
        super.setUp()
        vm = FanWheelViewModel()
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func test_initialState_notSpinning() {
        XCTAssertFalse(vm.isSpinning)
        XCTAssertEqual(vm.rotation, 0)
        XCTAssertNil(vm.resultSegment)
        XCTAssertFalse(vm.showResult)
        XCTAssertEqual(vm.selectedPreset, 0)
        XCTAssertTrue(vm.segments.isEmpty)
    }

    func test_presets_available() {
        XCTAssertEqual(vm.presets.count, 2)
        XCTAssertEqual(vm.presets[0].name, "Classic Prizes")
        XCTAssertEqual(vm.presets[1].name, "Challenges")
    }

    // MARK: - selectPreset

    func test_selectPreset_loadsSegments() {
        vm.selectPreset(0)
        XCTAssertEqual(vm.segments.count, 6)

        vm.selectPreset(1)
        XCTAssertEqual(vm.segments.count, 6)
    }

    func test_selectPreset_updatesSelectedIndex() {
        vm.selectPreset(1)
        XCTAssertEqual(vm.selectedPreset, 1)
    }

    // MARK: - segmentAngle

    func test_segmentAngle() {
        vm.selectPreset(0) // 6 segments
        XCTAssertEqual(vm.segmentAngle, 60.0, accuracy: 0.001)
    }

    // MARK: - spin

    func test_spin_setsSpinning() {
        vm.selectPreset(0)
        vm.spin()
        XCTAssertTrue(vm.isSpinning)
        XCTAssertFalse(vm.showResult)
        XCTAssertNil(vm.resultSegment)
    }

    func test_spin_cannotSpinWhileSpinning() {
        vm.selectPreset(0)
        vm.spin()
        let rot = vm.rotation
        vm.spin()
        // Rotation should not change from second spin call
        XCTAssertEqual(vm.rotation, rot)
    }
}
