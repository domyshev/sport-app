import Foundation
import zlib

struct GarminOfficialExportImporter {
    enum ImportError: Error {
        case bundledResourceNotFound
        case invalidZIP
        case unsupportedZIPCompression(UInt16)
        case corruptedZIPEntry
        case decompressionFailed
    }

    var bundle: Bundle = .main
    var resourceName = "garmin_summarized_activities"

    func importBundledActivities() throws -> [TrainingActivity] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw ImportError.bundledResourceNotFound
        }

        return try importActivities(from: Data(contentsOf: url), source: .bundledGarminExport)
    }

    func importFolder(at rootURL: URL) throws -> [TrainingActivity] {
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var activities: [TrainingActivity] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let decoded = try? importActivities(from: data, source: .garminOfficialExport)
            else {
                continue
            }
            activities.append(contentsOf: decoded)
        }
        return activities
    }

    func importZip(at zipURL: URL) throws -> [TrainingActivity] {
        let entries = try GarminZIPJSONReader().jsonEntries(in: Data(contentsOf: zipURL))
        return entries.flatMap { data in
            (try? importActivities(from: data, source: .garminOfficialExport)) ?? []
        }
    }

    func importActivities(from data: Data, source: TrainingActivitySource) throws -> [TrainingActivity] {
        try GarminActivitiesLoader.decodeActivities(from: data).map {
            $0.trainingActivity(source: source)
        }
    }
}

private extension GarminActivity {
    func trainingActivity(source: TrainingActivitySource) -> TrainingActivity {
        TrainingActivity(
            id: UUID(),
            name: name,
            activityType: activityType,
            sportType: sportType,
            startDate: Date(timeIntervalSince1970: startTimeLocal / 1_000),
            durationSeconds: duration.map { $0 / 1_000 },
            caloriesKilocalories: calories,
            distanceMeters: distance.map { $0 / 100 },
            primarySource: source,
            sourceReferences: [
                TrainingActivitySourceReference(source: source, id: "\(activityId)")
            ]
        )
    }
}

private struct GarminZIPJSONReader {
    func jsonEntries(in data: Data) throws -> [Data] {
        let directory = try centralDirectory(in: data)
        var entries: [Data] = []

        for entry in directory where entry.name.lowercased().hasSuffix(".json") {
            let compressedData = try compressedEntryData(for: entry, in: data)
            switch entry.compressionMethod {
            case 0:
                entries.append(compressedData)
            case 8:
                entries.append(try inflateRawDeflate(compressedData, uncompressedSize: entry.uncompressedSize))
            default:
                throw GarminOfficialExportImporter.ImportError.unsupportedZIPCompression(entry.compressionMethod)
            }
        }

        return entries
    }

    private func centralDirectory(in data: Data) throws -> [ZIPEntry] {
        guard let endOffset = endOfCentralDirectoryOffset(in: data) else {
            throw GarminOfficialExportImporter.ImportError.invalidZIP
        }

        let entryCount = Int(data.uint16(at: endOffset + 10))
        var offset = Int(data.uint32(at: endOffset + 16))
        var entries: [ZIPEntry] = []

        for _ in 0..<entryCount {
            guard data.uint32(at: offset) == 0x0201_4B50 else {
                throw GarminOfficialExportImporter.ImportError.invalidZIP
            }

            let compressionMethod = data.uint16(at: offset + 10)
            let compressedSize = Int(data.uint32(at: offset + 20))
            let uncompressedSize = Int(data.uint32(at: offset + 24))
            let nameLength = Int(data.uint16(at: offset + 28))
            let extraLength = Int(data.uint16(at: offset + 30))
            let commentLength = Int(data.uint16(at: offset + 32))
            let localHeaderOffset = Int(data.uint32(at: offset + 42))
            let nameStart = offset + 46
            let nameEnd = nameStart + nameLength

            guard nameEnd <= data.count,
                  let name = String(data: data[nameStart..<nameEnd], encoding: .utf8) else {
                throw GarminOfficialExportImporter.ImportError.invalidZIP
            }

            entries.append(
                ZIPEntry(
                    name: name,
                    compressionMethod: compressionMethod,
                    compressedSize: compressedSize,
                    uncompressedSize: uncompressedSize,
                    localHeaderOffset: localHeaderOffset
                )
            )
            offset = nameEnd + extraLength + commentLength
        }

        return entries
    }

    private func endOfCentralDirectoryOffset(in data: Data) -> Int? {
        let signature: UInt32 = 0x0605_4B50
        let minimumOffset = max(0, data.count - 65_557)
        guard data.count >= 22 else { return nil }

        var offset = data.count - 22
        while offset >= minimumOffset {
            if data.uint32(at: offset) == signature {
                return offset
            }
            offset -= 1
        }

        return nil
    }

    private func compressedEntryData(for entry: ZIPEntry, in data: Data) throws -> Data {
        let offset = entry.localHeaderOffset
        guard data.uint32(at: offset) == 0x0403_4B50 else {
            throw GarminOfficialExportImporter.ImportError.corruptedZIPEntry
        }

        let nameLength = Int(data.uint16(at: offset + 26))
        let extraLength = Int(data.uint16(at: offset + 28))
        let start = offset + 30 + nameLength + extraLength
        let end = start + entry.compressedSize
        guard start >= 0, end <= data.count else {
            throw GarminOfficialExportImporter.ImportError.corruptedZIPEntry
        }

        return data[start..<end]
    }

    private func inflateRawDeflate(_ data: Data, uncompressedSize: Int) throws -> Data {
        guard uncompressedSize >= 0 else {
            throw GarminOfficialExportImporter.ImportError.decompressionFailed
        }

        var stream = z_stream()
        let initResult = inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initResult == Z_OK else {
            throw GarminOfficialExportImporter.ImportError.decompressionFailed
        }
        defer { inflateEnd(&stream) }

        var output = Data(count: uncompressedSize)
        let outputCount = output.count
        let result: Int32 = data.withUnsafeBytes { inputBuffer in
            output.withUnsafeMutableBytes { outputBuffer in
                guard let inputBase = inputBuffer.bindMemory(to: Bytef.self).baseAddress,
                      let outputBase = outputBuffer.bindMemory(to: Bytef.self).baseAddress else {
                    return Z_DATA_ERROR
                }

                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputBase)
                stream.avail_in = uInt(data.count)
                stream.next_out = outputBase
                stream.avail_out = uInt(outputCount)
                return inflate(&stream, Z_FINISH)
            }
        }

        guard result == Z_STREAM_END else {
            throw GarminOfficialExportImporter.ImportError.decompressionFailed
        }

        return output
    }
}

private struct ZIPEntry {
    let name: String
    let compressionMethod: UInt16
    let compressedSize: Int
    let uncompressedSize: Int
    let localHeaderOffset: Int
}

private extension Data {
    func uint16(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func uint32(at offset: Int) -> UInt32 {
        UInt32(self[offset])
            | UInt32(self[offset + 1]) << 8
            | UInt32(self[offset + 2]) << 16
            | UInt32(self[offset + 3]) << 24
    }
}
