
import AppMetricaCore
import AppMetricaCoreExtension
import Foundation

/// Adapter for libraries that use AppMetrica.
///
/// This class provides a way to interact with AppMetrica functionality,
/// including activation and event reporting.
@objc(AMAAppMetricaLibraryAdapter)
public final class AppMetricaLibraryAdapter: NSObject {

    /// The shared instance of the `AppMetricaLibraryAdapter`.
    @objc(sharedInstance)
    public static let shared = AppMetricaLibraryAdapter()

    private let appMetrica: AppMetrica.Type
    private static let systemEventName = "appmetrica_system_event_42"

    /// Internal initializer for unit-testing
    /// - Parameter appMetrica: The AppMetrica type to use. Defaults to `AppMetrica.self`.
    init(appMetrica: AppMetrica.Type = AppMetrica.self) {
        self.appMetrica = appMetrica
        super.init()
    }

    /// Activates AppMetrica without `API_KEY` in anonymous mode.
    @objc public func activate() {
        activate(config: .init())
    }
    
    /// Activates AppMetrica without `API_KEY` in anonymous mode.
    @objc public func activate(configuration: LibraryAdapterConfiguration) {
        activate(config: configuration.config)
    }
    
    func activate(config: LibraryAdapterConfig) {
        appMetrica.activate(adIdentifierTrackingEnabled: config.advIdentifiersTrackingEnabled)
    }

    /// Sends a system report with provided data.
    ///
    /// This method allows you to report custom events to AppMetrica.
    ///
    /// - Parameters:
    ///   - sender: String representation of the sender.
    ///   - event: Name of the event.
    ///   - payload: Description of the event as a string.
    ///   - onFailure: A closure to be called if an error occurs during reporting.
    ///
    /// - Note: The payload must be a valid JSON object.
    @objc public func reportEvent(
        sender: String, event: String, payload: String, onFailure: ((Swift.Error) -> Void)?
    ) {
        let parameters: [String: Any] = [
            "sender": sender,
            "event": event,
            "payload": payload,
            "layer": "native",
            "source": "yandex",
        ]

        appMetrica.reportLibraryAdapterAdRevenueRelatedEvent(
            name: Self.systemEventName,
            parameters: parameters,
            onFailure: onFailure
        )
    }
}
