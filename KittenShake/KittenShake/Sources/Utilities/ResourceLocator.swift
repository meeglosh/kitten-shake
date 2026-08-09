import UIKit

/// Locates loose resource files (images, fonts, sounds) inside the app
/// bundle even when they live under nested folder references, and caches
/// the results of the (slightly more expensive) recursive search.
enum ResourceLocator {
    private static var urlCache: [String: URL] = [:]

    static func url(forResource name: String, withExtension ext: String) -> URL? {
        let key = "\(name).\(ext)"
        if let cached = urlCache[key] { return cached }

        if let direct = Bundle.main.url(forResource: name, withExtension: ext) {
            urlCache[key] = direct
            return direct
        }

        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: resourcePath) else { return nil }

        for case let path as String in enumerator {
            if (path as NSString).lastPathComponent == key {
                let url = URL(fileURLWithPath: resourcePath).appendingPathComponent(path)
                urlCache[key] = url
                return url
            }
        }
        return nil
    }

    static func image(named name: String) -> UIImage? {
        guard let url = url(forResource: name, withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
