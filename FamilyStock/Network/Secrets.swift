//
//  Secrets.swift
//  FamilyStock
//
//  Created by Claude on 2025/10/20.
//

import Foundation

struct Secrets {
    let baseURL: URL
    let anonKey: String

    static let shared: Secrets = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let base = (dict["SUPABASE_URL"] as? String).flatMap(URL.init(string:)),
            let key  = dict["SUPABASE_ANON_KEY"] as? String
        else { fatalError("Missing or invalid Secrets.plist") }
        return Secrets(baseURL: base, anonKey: key)
    }()
}
