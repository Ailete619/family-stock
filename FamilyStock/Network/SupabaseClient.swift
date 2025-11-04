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

    private let baseURL: URL
    private let anonKey: String
    private var accessToken: String?

    struct User: Codable, Identifiable {
        let id: String
        let email: String
    }

    private init() {
        self.baseURL = Secrets.shared.baseURL
        self.anonKey = Secrets.shared.anonKey

        // Try to restore session from UserDefaults
        if let savedToken = UserDefaults.standard.string(forKey: "supabase_access_token"),
           let savedUserData = UserDefaults.standard.data(forKey: "supabase_user"),
           let savedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
            self.accessToken = savedToken
            self.currentUser = savedUser
            self.isAuthenticated = true
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

        // Save session
        self.accessToken = accessToken
        self.currentUser = User(id: user.id, email: user.email)
        self.isAuthenticated = true

        // Persist session
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        if let userData = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(userData, forKey: "supabase_user")
        }
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

        // Save session
        self.accessToken = accessToken
        self.currentUser = User(id: user.id, email: user.email)
        self.isAuthenticated = true

        // Persist session
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        if let userData = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(userData, forKey: "supabase_user")
        }
    }

    func signOut() {
        self.accessToken = nil
        self.currentUser = nil
        self.isAuthenticated = false

        // Clear persisted session
        UserDefaults.standard.removeObject(forKey: "supabase_access_token")
        UserDefaults.standard.removeObject(forKey: "supabase_user")

        // Clear sync timestamps
        UserDefaults.standard.removeObject(forKey: "lastPullItems")
        UserDefaults.standard.removeObject(forKey: "lastPullShopping")
        UserDefaults.standard.removeObject(forKey: "lastPullReceipts")
    }

    func getAccessToken() -> String? {
        return accessToken
    }

    // MARK: - Helper Types

    private struct AuthResponse: Codable {
        let access_token: String?
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
            }
        }
    }
}
