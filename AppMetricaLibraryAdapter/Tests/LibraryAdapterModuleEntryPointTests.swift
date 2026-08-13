import XCTest
import AppMetricaCoreExtension
import AppMetricaTestUtils
@testable import AppMetricaLibraryAdapter

final class LibraryAdapterModuleEntryPointTests: XCTestCase {

    private var registrar: AMAModuleRegistrarMock!
    private var entryPoint: LibraryAdapterModuleEntryPoint!

    override func setUp() {
        super.setUp()
        registrar = AMAModuleRegistrarMock(testCase: self)
        entryPoint = LibraryAdapterModuleEntryPoint()
    }

    override func tearDown() {
        entryPoint = nil
        registrar = nil
        super.tearDown()
    }

    func testRegisterComponentsDoesNotRegisterAnything() {
        entryPoint.registerComponents(with: registrar)

        XCTAssertEqual(registrar.preActivationHandlers.count, 0)
        XCTAssertEqual(registrar.activationDelegates.count, 0)
        XCTAssertEqual(registrar.serviceConfigurations.count, 0)
    }

    func testModuleName() {
        XCTAssertEqual(entryPoint.moduleName, "AppMetricaLibraryAdapter")
    }
}
