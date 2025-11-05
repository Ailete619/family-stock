//
//  SupabaseClient.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation
import Combine

/// Wrapper around Supabase client for authentication and data access
/// This will be enhanced once we add the Supabase Swift SDK
@MainActor
class SupabaseClient: ObservableObject {
    static let shared = SupabaseClient()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLocalOnly = false

    private let baseURL: URL
    private let anonKey: String
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?

    struct User: Codable, Identifiable {
        let id: String
        let email: String
        let isLocal: Bool

        init(id: String, email: String, isLocal: Bool = false) {
            self.id = id
            self.email = email
            self.isLocal = isLocal
        }
    }

    private init() {
        self.baseURL = Secrets.shared.baseURL
        self.anonKey = Secrets.shared.anonKey

        // Check if user chose local-only mode
        if UserDefaults.standard.bool(forKey: "local_only_mode") {
            let localUserId = UserDefaults.standard.string(forKey: "local_user_id") ?? UUID().uuidString.lowercased()
            UserDefaults.standard.set(localUserId, forKey: "local_user_id")
            self.currentUser = User(id: localUserId, email: "local@device", isLocal: true)
            self.isAuthenticated = true
            self.isLocalOnly = true
            print("📱 Running in local-only mode with ID: \(localUserId)")
            return
        }

        // Try to restore session from UserDefaults
        if let savedToken = UserDefaults.standard.string(forKey: "supabase_access_token"),
           let savedUserData = UserDefaults.standard.data(forKey: "supabase_user"),
           let savedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
            self.accessToken = savedToken
            self.refreshToken = UserDefaults.standard.string(forKey: "supabase_refresh_token")
            self.tokenExpiresAt = UserDefaults.standard.object(forKey: "supabase_token_expires_at") as? Date
            self.currentUser = savedUser
            self.isAuthenticated = true
            self.isLocalOnly = savedUser.isLocal
        }
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        var urlComponents = URLComponents(url: baseURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("auth/v1/token"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        let url = urlComponents.url!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidCredentials
        }

        // Log the response for debugging
        print("Sign in response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Sign in response body: \(responseString)")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AuthError.invalidCredentials
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Ensure we have both access_token and user
        guard let accessToken = authResponse.access_token, let user = authResponse.user else {
            throw AuthError.invalidCredentials
        }

        // Save session with refresh token
        self.accessToken = accessToken
        self.refreshToken = authResponse.refresh_token
        self.tokenExpiresAt = authResponse.expires_at.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        self.currentUser = User(id: user.id, email: user.email, isLocal: false)
        self.isAuthenticated = true
        self.isLocalOnly = false

        // Persist session
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        if let refreshToken = authResponse.refresh_token {
            UserDefaults.standard.set(refreshToken, forKey: "supabase_refresh_token")
        }
        if let expiresAt = tokenExpiresAt {
            UserDefaults.standard.set(expiresAt, forKey: "supabase_token_expires_at")
        }
        if let userData = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(userData, forKey: "supabase_user")
        }
        // Clear local-only flag
        UserDefaults.standard.set(false, forKey: "local_only_mode")
    }

    func signUp(email: String, password: String) async throws {
        let url = baseURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("auth/v1/signup")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.signUpFailed
        }

        // Log the response for debugging
        print("Sign up response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Sign up response body: \(responseString)")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AuthError.signUpFailed
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Check if email confirmation is required
        guard let accessToken = authResponse.access_token, let user = authResponse.user else {
            // Email confirmation required - the user was created but needs to verify email
            throw AuthError.emailConfirmationRequired
        }

        // Save session with refresh token
        self.accessToken = accessToken
        self.refreshToken = authResponse.refresh_token
        self.tokenExpiresAt = authResponse.expires_at.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        self.currentUser = User(id: user.id, email: user.email, isLocal: false)
        self.isAuthenticated = true
        self.isLocalOnly = false

        // Persist session
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        if let refreshToken = authResponse.refresh_token {
            UserDefaults.standard.set(refreshToken, forKey: "supabase_refresh_token")
        }
        if let expiresAt = tokenExpiresAt {
            UserDefaults.standard.set(expiresAt, forKey: "supabase_token_expires_at")
        }
        if let userData = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(userData, forKey: "supabase_user")
        }
        // Clear local-only flag
        UserDefaults.standard.set(false, forKey: "local_only_mode")
    }

    func continueAsLocalOnly() {
        let localUserId = UUID().uuidString.lowercased()
        self.currentUser = User(id: localUserId, email: "local@device", isLocal: true)
        self.isAuthenticated = true
        self.isLocalOnly = true

        // Persist local-only mode
        UserDefaults.standard.set(true, forKey: "local_only_mode")
        UserDefaults.standard.set(localUserId, forKey: "local_user_id")
        if let userData = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(userData, forKey: "supabase_user")
        }

        print("📱 Continuing in local-only mode with ID: \(localUserId)")
    }

    func signOut() {
        self.accessToken = nil
        self.refreshToken = nil
        self.tokenExpiresAt = nil
        self.currentUser = nil
        self.isAuthenticated = false
        self.isLocalOnly = false

        // Clear persisted session
        UserDefaults.standard.removeObject(forKey: "supabase_access_token")
        UserDefaults.standard.removeObject(forKey: "supabase_refresh_token")
        UserDefaults.standard.removeObject(forKey: "supabase_token_expires_at")
        UserDefaults.standard.removeObject(forKey: "supabase_user")
        UserDefaults.standard.removeObject(forKey: "local_only_mode")
        UserDefaults.standard.removeObject(forKey: "local_user_id")

        // Clear sync timestamps
        UserDefaults.standard.removeObject(forKey: "lastPullItems")
        UserDefaults.standard.removeObject(forKey: "lastPullShopping")
        UserDefaults.standard.removeObject(forKey: "lastPullReceipts")
    }

    func getAccessToken() async throws -> String? {
        // Check if token is about to expire (within 5 minutes)
        if let expiresAt = tokenExpiresAt, Date().addingTimeInterval(300) >= expiresAt {
            // Token is expired or about to expire, try to refresh it
            try await refreshAccessToken()
        }
        return accessToken
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw AuthError.tokenExpired
        }

        var urlComponents = URLComponents(url: baseURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("auth/v1/token"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        let url = urlComponents.url!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.tokenRefreshFailed
        }

        print("Refresh token response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Refresh token response: \(responseString)")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            // Refresh token is invalid or expired, need to re-authenticate
            handleTokenExpiration()
            throw AuthError.tokenExpired
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        guard let newAccessToken = authResponse.access_token else {
            throw AuthError.tokenRefreshFailed
        }

        // Update tokens
        self.accessToken = newAccessToken
        self.refreshToken = authResponse.refresh_token ?? refreshToken
        self.tokenExpiresAt = authResponse.expires_at.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }

        // Persist new tokens
        UserDefaults.standard.set(newAccessToken, forKey: "supabase_access_token")
        if let newRefreshToken = authResponse.refresh_token {
            UserDefaults.standard.set(newRefreshToken, forKey: "supabase_refresh_token")
        }
        if let expiresAt = tokenExpiresAt {
            UserDefaults.standard.set(expiresAt, forKey: "supabase_token_expires_at")
        }

        print("✅ Token refreshed successfully")
    }

    // MARK: - Helper Types

    private struct AuthResponse: Codable {
        let access_token: String?
        let refresh_token: String?
        let expires_at: Int?
        let user: UserResponse?
    }

    private struct UserResponse: Codable {
        let id: String
        let email: String
    }

    func handleTokenExpiration() {
        // Clear the expired token and force re-authentication
        self.accessToken = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "supabase_access_token")
        // Keep the user info so they can easily sign in again
    }

    enum AuthError: LocalizedError {
        case invalidCredentials
        case signUpFailed
        case notAuthenticated
        case emailConfirmationRequired
        case tokenExpired
        case tokenRefreshFailed

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password"
            case .signUpFailed:
                return "Failed to create account"
            case .notAuthenticated:
                return "You must be logged in"
            case .emailConfirmationRequired:
                return "Please check your email to confirm your account before signing in"
            case .tokenExpired:
                return "Your session has expired. Please sign in again"
            case .tokenRefreshFailed:
                return "Failed to refresh session. Please sign in again"
            }
        }
    }
}
