import MapKit

@MainActor
final class MapSearchModel: NSObject, ObservableObject {
    @Published private(set) var completions: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter
    private var queryDebounceTask: Task<Void, Never>?
    private let queryDebounceNanoseconds: UInt64 = 180_000_000
    private let maxCompletionCount = 12

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    deinit {
        queryDebounceTask?.cancel()
    }

    func updateQuery(_ query: String) {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        queryDebounceTask?.cancel()
        guard keyword.isEmpty == false else {
            completions = []
            completer.queryFragment = ""
            return
        }

        queryDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: self?.queryDebounceNanoseconds ?? 0)
            guard let self else { return }
            guard Task.isCancelled == false else { return }
            self.completer.queryFragment = keyword
        }
    }

    func search(query: String, fallbackTitle: String) async -> SearchPlace? {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return nil }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else { return nil }
            return SearchPlace(mapItem: item, fallbackTitle: fallbackTitle)
        } catch {
            return nil
        }
    }
}

extension MapSearchModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.completions = self.deduplicatedResults(from: results)
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.completions = []
        }
    }

    private func deduplicatedResults(
        from results: [MKLocalSearchCompletion]
    ) -> [MKLocalSearchCompletion] {
        var seenKeys = Set<String>()
        var uniqueResults: [MKLocalSearchCompletion] = []
        uniqueResults.reserveCapacity(min(results.count, maxCompletionCount))

        for result in results {
            let title = result.title
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let subtitle = result.subtitle
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let key = "\(title)|\(subtitle)"
            if seenKeys.insert(key).inserted {
                uniqueResults.append(result)
                if uniqueResults.count >= maxCompletionCount {
                    break
                }
            }
        }
        return uniqueResults
    }
}

struct SearchPlace {
    let annotationTitle: String
    let coordinate: CLLocationCoordinate2D

    init?(mapItem: MKMapItem, fallbackTitle: String) {
        guard CLLocationCoordinate2DIsValid(mapItem.placemark.coordinate) else {
            return nil
        }

        let title = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let placemarkTitle = mapItem.placemark.title?
            .replacingOccurrences(of: "\n", with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let resolvedTitle: String
        if title.isEmpty == false {
            resolvedTitle = title
        } else if placemarkTitle.isEmpty == false {
            resolvedTitle = placemarkTitle
        } else {
            resolvedTitle = fallbackTitle
        }

        self.annotationTitle = resolvedTitle
        self.coordinate = mapItem.placemark.coordinate
    }
}
