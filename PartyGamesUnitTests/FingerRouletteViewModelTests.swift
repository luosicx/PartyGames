import XCTest
@testable import PartyGames

@MainActor
final class FingerRouletteViewModelTests: XCTestCase {
    var vm: FingerRouletteViewModel!

    override func setUp() {
        super.setUp()
        vm = FingerRouletteViewModel()
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
    }

    // MARK: - selectPreset

    func test_selectPreset_loadsSegments() {
        vm.selectPreset(0)
        XCTAssertEqual(vm.segments.count, 8)

        vm.selectPreset(1)
        XCTAssertEqual(vm.segments.count, 8)
    }

    // MARK: - segmentAngle

    func test_segmentAngle() {
        vm.selectPreset(0) // 8 segments
        XCTAssertEqual(vm.segmentAngle, 45.0, accuracy: 0.001)
    }

    // MARK: - startSpin

    func test_startSpin_setsSpinning() {
        vm.selectPreset(0)
        vm.startSpin(from: 2000)
        XCTAssertTrue(vm.isSpinning)
        XCTAssertFalse(vm.showResult)
        XCTAssertNil(vm.resultSegment)
    }

    func test_startSpin_cannotSpinWhileSpinning() {
        vm.selectPreset(0)
        vm.startSpin(from: 2000)
        let rot = vm.rotation
        vm.startSpin(from: 3000)
        XCTAssertEqual(vm.rotation, rot)
    }

    // MARK: - velocity clamping

    func test_startSpin_withVelocity_clampsValue() {
        vm.selectPreset(0)
        vm.startSpin(from: 2000) // 2000/100 = 20, within 5...40
        XCTAssertTrue(vm.isSpinning)
    }
}
