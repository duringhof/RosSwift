//
//  network.swift
//  RosSwift
//
//  Created by Thomas Gustafsson on 2018-03-03.
//

import Foundation
import NIO
import Logging

fileprivate let logger = Logger(label: "network")

public struct Network {
    public let gHost: String
    public let gTcprosServerPort: UInt16

    public init(remappings: [String:String]) {
        var host = ""
        if let it = remappings["__hostname"] {
            host = it
        } else if let it = remappings["__ip"] {
            host = it
        }
        if let it = remappings["__tcpros_server_port"] {
            guard let tcprosServerPort = UInt16(it) else {
                fatalError("__tcpros_server_port [\(it)] was not specified as a number within the 0-65535 range")
            }
            gTcprosServerPort = tcprosServerPort
        } else {
            gTcprosServerPort = 0
        }

        if host.isEmpty {
            host = Network.determineHost()
        }
        gHost = host
    }

    static func splitURI(uri: String, host: inout String, port: inout UInt16) -> Bool {
        var uri = uri
        if uri.hasPrefix("http://") {
            uri = String(uri.dropFirst(7))
        } else if uri.hasPrefix("rosrpc://") {
            uri = String(uri.dropFirst(9))
        }

        let parts = uri.components(separatedBy: ":")
        guard parts.count == 2 else {
            return false
        }
        var portString = parts[1]

        let segs = portString.components(separatedBy: "/")
        portString = segs[0]

        guard let portNr = UInt16(portString) else {
            return false
        }

        port = portNr
        host = parts[0]
        return true
    }

    static func determineHost() -> String {

        if let hostname = ProcessInfo.processInfo.environment["ROS_HOSTNAME"] {
            logger.debug("determineIP: using value of ROS_HOSTNAME:\(hostname)")
            if hostname.isEmpty {
                logger.warning("invalid ROS_HOSTNAME (an empty string)")
            }
            return hostname
        }

        if let rosIP = ProcessInfo.processInfo.environment["ROS_IP"] {
            logger.debug("determineIP: using value of ROS_IP:\(rosIP)")
            if rosIP.isEmpty {
                logger.warning("invalid ROS_IP (an empty string)")
            }
            return rosIP
        }

        let host = ProcessInfo.processInfo.hostName
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        // We don't want localhost to be our ip
        if !trimmedHost.isEmpty && host != "localhost" && trimmedHost.contains(".") {
            return trimmedHost
        }

        do {
            for i in try System.enumerateInterfaces() {
                let host = i.address.host
                if host != "127.0.0.1" && i.address.protocolFamily == PF_INET {
                    return host
                }
            }
        } catch {
            logger.error("\(error)")
        }

        return "127.0.0.1"
    }
}
