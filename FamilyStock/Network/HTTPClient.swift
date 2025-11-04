//
//  HTTPClient.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation

struct HTTPClient {
    let baseURL: URL
    let anonKey: String

    private var jsonDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private var jsonEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var req = URLRequest(url: components.url!)

        // Use access token if available, otherwise use anon key
        if let accessToken = await SupabaseClient.shared.getAccessToken() {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }

        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Check for JWT expiration
        if http.statusCode == 401, let responseString = String(data: data, encoding: .utf8), responseString.contains("JWT expired") {
            await SupabaseClient.shared.handleTokenExpiration()
            throw SupabaseClient.AuthError.tokenExpired
        }

        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try jsonDecoder.decode(T.self, from: data)
    }

    func post<T: Encodable, R: Decodable>(_ path: String, body: T) async throws -> R {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"

        // Use access token if available, otherwise use anon key
        if let accessToken = await SupabaseClient.shared.getAccessToken() {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }

        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")

        req.httpBody = try jsonEncoder.encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Debug logging
        print("POST \(path) - Status: \(http.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")

            // Check for JWT expiration
            if http.statusCode == 401 && responseString.contains("JWT expired") {
                await SupabaseClient.shared.handleTokenExpiration()
                throw SupabaseClient.AuthError.tokenExpired
            }
        }

        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try jsonDecoder.decode(R.self, from: data)
    }

    func patch<T: Encodable, R: Decodable>(_ path: String, body: T, query: [URLQueryItem] = []) async throws -> R {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var req = URLRequest(url: components.url!)
        req.httpMethod = "PATCH"

        // Use access token if available, otherwise use anon key
        if let accessToken = await SupabaseClient.shared.getAccessToken() {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }

        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")

        req.httpBody = try jsonEncoder.encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Debug logging
        print("PATCH \(path) - Status: \(http.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")

            // Check for JWT expiration
            if http.statusCode == 401 && responseString.contains("JWT expired") {
                await SupabaseClient.shared.handleTokenExpiration()
                throw SupabaseClient.AuthError.tokenExpired
            }
        }

        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try jsonDecoder.decode(R.self, from: data)
    }
}
