// Telegram Bot SDK for Swift (unofficial).
// This file is autogenerated by API/generate_wrappers.rb script.

import Foundation
import SwiftyJSON

/// Represents a result of an inline query that was chosen by the user and sent to their chat partner.
///
/// - SeeAlso: <https://core.telegram.org/bots/api#choseninlineresult>

public struct ChosenInlineResult: JsonConvertible {
    /// Original JSON for fields not yet added to Swift structures.
    public var json: JSON

    /// The unique identifier for the result that was chosen
    public var result_id: String {
        get { return json["result_id"].stringValue }
        set { json["result_id"].stringValue = newValue }
    }

    /// The user that chose the result
    public var from: User {
        get { return User(json: json["from"]) }
        set { json["from"] = newValue.json }
    }

    /// Optional. Sender location, only for bots that require user location
    public var location: Location? {
        get {
            let value = json["location"]
            return value.isNullOrUnknown ? nil : Location(json: value)
        }
        set {
            json["location"] = newValue?.json ?? JSON.null
        }
    }

    /// Optional. Identifier of the sent inline message. Available only if there is an inline keyboard attached to the message. Will be also received in callback queries and can be used to edit the message.
    public var inline_message_id: String? {
        get { return json["inline_message_id"].string }
        set { json["inline_message_id"].string = newValue }
    }

    /// The query that was used to obtain the result
    public var query: String {
        get { return json["query"].stringValue }
        set { json["query"].stringValue = newValue }
    }

    public init(json: JSON = [:]) {
        self.json = json
    }
}
