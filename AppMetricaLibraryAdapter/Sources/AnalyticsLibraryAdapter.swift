
import AppMetricaCore
import AppMetricaCoreExtension
import Foundation

/// Adapter for libraries that use AppMetrica.
///
/// This class provides a way to interact with AppMetrica functionality,
/// including activation and event reporting.
@objc(AMAAnalyticsLibraryAdapter)
public final class AnalyticsLibraryAdapter: NSObject, @unchecked Sendable {

    /// The shared instance of the `LibraryAdapter`.
    @objc(sharedInstance)
    public static let shared = AnalyticsLibraryAdapter()

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

    /// Activates AppMetrica without `API_KEY` in anonymous mode with configuration
    @objc public func activate(configuration: AnalyticsLibraryAdapterConfiguration) {
        activate(config: configuration.config)
    }
    
    /// Enables or disables using IDFA. This options can be overriden by ``AppMetrica/setAdProviderEnabled`
    @objc public func setAdvertisingTracking(_ enabled: Bool) {
        appMetrica.setLibraryAdapterAdvertisingIdentifierTracking(enabled)
    }
    
    /// Enables or disables location tracking. This option can be overriden by ``AppMetrica/setLocationTrackingEnabled``
    @objc public func setLocationTracking(_ enabled: Bool) {
        appMetrica.setLibraryAdapterLocationTracking(enabled)
    }
    
    @objc(subscribeForAutocollectedDataForApiKey:)
    public func subscribeForAutocollectedData(apiKey: String) {
        appMetrica.subscribeForAutocollectedData(apiKey: apiKey)
    }
    
    /// Activates AppMetrica without `API_KEY` in anonymous mode.
    public func activate(config: AnalyticsLibraryAdapterConfig) {
        let cfg = AppMetricaLibraryAdapterConfiguration()
        if let advertisingIdentifiersTrackingEnabled = config.advertisingIdentifiersTrackingEnabled {
            cfg.advertisingIdentifierTrackingEnabled = advertisingIdentifiersTrackingEnabled
        }
        if let locationTrackingEnabled = config.locationTrackingEnabled {
            cfg.locationTrackingEnabled = locationTrackingEnabled
        }
        appMetrica.setupLibraryAdapterConfiguration(cfg)
        appMetrica.activate()
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

