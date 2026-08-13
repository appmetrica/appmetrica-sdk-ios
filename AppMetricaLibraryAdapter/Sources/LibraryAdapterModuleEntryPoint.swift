
import AppMetricaCoreExtension
import Foundation

@objc(AMALibraryAdapterModuleEntryPoint)
public final class LibraryAdapterModuleEntryPoint: NSObject, ModuleEntryPoint {

    public var moduleName: String { "AppMetricaLibraryAdapter" }

    public func registerComponents(with registrar: any ModuleRegistrar) {}
}
