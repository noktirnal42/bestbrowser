import Foundation
import AuthenticationServices

@MainActor
final class BrowserAuthenticationService: NSObject, ObservableObject {
    static let shared = BrowserAuthenticationService()

    @Published private(set) var passkeyAccessStatus: String = "Checking support..."
    @Published private(set) var ssoStatus: String = "Browser sign-in handoff inactive."
    @Published private(set) var isPasskeyAccessAuthorized = false
    @Published private(set) var canRequestPasskeyAccess = false
    @Published private(set) var deviceConfiguredForPasskeys = false

    private var currentAuthenticationRequest: ASWebAuthenticationSessionRequest?
    private var sessionHandler: WebAuthenticationSessionHandler?

    private override init() {
        super.init()
    }

    func start() {
        configureWebAuthenticationSupport()
        refreshStatus()
    }

    func refreshStatus() {
        if #available(macOS 13.3, *) {
            let manager = ASAuthorizationWebBrowserPublicKeyCredentialManager()
            let authorizationState = manager.authorizationStateForPlatformCredentials

            canRequestPasskeyAccess = true
            isPasskeyAccessAuthorized = authorizationState == .authorized

            if #available(macOS 26.2, *) {
                deviceConfiguredForPasskeys = ASAuthorizationWebBrowserPublicKeyCredentialManager.isDeviceConfiguredForPasskeys
            } else {
                deviceConfiguredForPasskeys = true
            }

            switch authorizationState {
            case .authorized:
                passkeyAccessStatus = deviceConfiguredForPasskeys
                    ? "Apple Passwords and passkeys are available in BestBrowser."
                    : "BestBrowser has access, but this Mac still needs passkeys configured in Apple Passwords."
            case .denied:
                passkeyAccessStatus = "Access to Apple Passwords passkeys is denied for BestBrowser."
            case .notDetermined:
                passkeyAccessStatus = "BestBrowser can request access to Apple Passwords passkeys."
            @unknown default:
                passkeyAccessStatus = "Passkey access status is unknown."
            }
        } else {
            canRequestPasskeyAccess = false
            isPasskeyAccessAuthorized = false
            deviceConfiguredForPasskeys = false
            passkeyAccessStatus = "Apple Passwords passkey access requires macOS 13.3 or newer."
        }
    }

    func requestPasskeyAccess() {
        guard #available(macOS 13.3, *) else {
            refreshStatus()
            return
        }

        let manager = ASAuthorizationWebBrowserPublicKeyCredentialManager()
        manager.requestAuthorizationForPublicKeyCredentials { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatus()
            }
        }
    }

    func openPasswordsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Passwords-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }

    func completeAuthenticationIfNeeded(with url: URL, isMainFrame: Bool) -> Bool {
        guard isMainFrame, let request = currentAuthenticationRequest else { return false }

        if request.callback?.matchesURL(url) == true {
            request.complete(withCallbackURL: url)
            currentAuthenticationRequest = nil
            ssoStatus = "Browser sign-in handoff completed."
            return true
        }

        return false
    }

    private func configureWebAuthenticationSupport() {
        if #available(macOS 10.15, *) {
            let handler = WebAuthenticationSessionHandler(owner: self)
            sessionHandler = handler
            ASWebAuthenticationSessionWebBrowserSessionManager.shared.sessionHandler = handler

            if ASWebAuthenticationSessionWebBrowserSessionManager.shared.wasLaunchedByAuthenticationServices {
                ssoStatus = "Ready for app sign-in handoff."
            } else {
                ssoStatus = "Ready to receive app sign-in handoff."
            }
        } else {
            ssoStatus = "Browser sign-in handoff requires macOS 10.15 or newer."
        }
    }

    func beginAuthenticationRequest(_ request: ASWebAuthenticationSessionRequest) {
        currentAuthenticationRequest = request
        ssoStatus = "Opening sign-in flow in BestBrowser..."

        let additionalHeaders: [String: String]?
        if #available(macOS 14.4, *) {
            additionalHeaders = request.additionalHeaderFields
        } else {
            additionalHeaders = nil
        }

        BrowserViewModel.shared.openAuthenticationRequest(
            request.url,
            additionalHeaders: additionalHeaders
        )
    }

    func cancelAuthenticationRequest(_ request: ASWebAuthenticationSessionRequest) {
        guard currentAuthenticationRequest?.uuid == request.uuid else { return }
        currentAuthenticationRequest = nil
        ssoStatus = "Browser sign-in handoff canceled."
    }
}

@available(macOS 10.15, *)
@MainActor
private final class WebAuthenticationSessionHandler: NSObject, @preconcurrency ASWebAuthenticationSessionWebBrowserSessionHandling {
    unowned let owner: BrowserAuthenticationService

    init(owner: BrowserAuthenticationService) {
        self.owner = owner
    }

    func begin(_ request: ASWebAuthenticationSessionRequest) {
        owner.beginAuthenticationRequest(request)
    }

    func cancel(_ request: ASWebAuthenticationSessionRequest) {
        owner.cancelAuthenticationRequest(request)
    }
}
