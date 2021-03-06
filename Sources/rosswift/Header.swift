//
//  Header.swift
//  RosSwift
//
//  Created by Thomas Gustafsson on 2018-03-06.
//

import BinaryCoder

struct Header {
    var headers = StringStringMap()

    subscript(key: String) -> String? {
        return headers[key]
    }

    init(headers: StringStringMap) {
        self.headers = headers
    }

    init?(buffer: [UInt8]) {
        var indx = 0
        while indx < buffer.count {
            let len = UInt32(buffer[indx]) |
                UInt32(buffer[indx + 1]) << 8 |
                UInt32(buffer[indx + 2]) << 16 |
                UInt32(buffer[indx + 3]) << 24
            indx += 4
            if len > 1_000_000 {
                ROS_DEBUG("Received an invalid TCPROS header.  Each element must be prepended by a 4-byte length.")
                return nil
            }

            let buf = buffer[indx..<indx + Int(len)]

            guard let line = String(bytes: buf, encoding: .utf8) else {
                ROS_DEBUG("Received an invalid TCPROS header.  invalid string")
                return nil
            }
            indx += Int(len)
            guard let eqs = line.firstIndex(of: "=") else {
                ROS_DEBUG("Received an invalid TCPROS header.  Each line must have an equals sign.")
                return nil
            }
            let key = String(line.prefix(upTo: eqs))
            let value = String(line.suffix(from: eqs).dropFirst())
            headers[key] = value
        }
    }

    static func write(keyVals: StringStringMap) -> [UInt8] {
        var data = [UInt8]()
        for (key, val) in keyVals {
            let str = "\(key)=\(val)"
            do {
                data.append(contentsOf: try BinaryEncoder.encode(str))
            } catch {
                ROS_ERROR("encoding \(str) failed with error: \(error)")
            }
        }
        return data
    }
}
