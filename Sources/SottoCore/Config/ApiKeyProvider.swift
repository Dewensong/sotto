import Foundation

public struct ApiKeyProvider: Sendable {

    public struct Config: Sendable {
        public let apiKey: String
        public let model: String
        public let baseURL: String

        public init(apiKey: String, model: String = "deepseek-chat", baseURL: String = "https://api.deepseek.com/v1") {
            self.apiKey = apiKey
            self.model = model
            self.baseURL = baseURL
        }
    }

    public enum Error: Swift.Error, LocalizedError {
        case missingKey

        public var errorDescription: String? {
            switch self {
            case .missingKey:
                return "未找到 DeepSeek API Key。请设置环境变量 DEEPSEEK_API_KEY 或在 ~/.sotto/config.json 中配置。"
            }
        }
    }

    private let envKey: String
    private let configPath: String

    public init(envKey: String = "DEEPSEEK_API_KEY", configPath: String? = nil) {
        self.envKey = envKey
        self.configPath = configPath ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".sotto/config.json")
            .path
    }

    public func resolve() throws -> Config {
        if let envValue = ProcessInfo.processInfo.environment[envKey], !envValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Config(apiKey: envValue.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if let fileConfig = try? loadFromFile() {
            return fileConfig
        }

        throw Error.missingKey
    }

    public func hasKey() -> Bool {
        (try? resolve()) != nil
    }

    public func saveConfig(_ config: Config) throws {
        let json: [String: String] = [
            "deepseek_api_key": config.apiKey,
            "deepseek_model": config.model,
            "deepseek_base_url": config.baseURL
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let url = URL(fileURLWithPath: configPath)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func loadFromFile() throws -> Config {
        let url = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String] ?? [:]

        guard let key = json["deepseek_api_key"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else {
            throw Error.missingKey
        }

        let model = json["deepseek_model"] ?? "deepseek-chat"
        let baseURL = json["deepseek_base_url"] ?? "https://api.deepseek.com/v1"

        return Config(apiKey: key, model: model, baseURL: baseURL)
    }
}
