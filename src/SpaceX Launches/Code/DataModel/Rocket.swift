//

import Foundation

// MARK: - Rocket

struct Rocket: Decodable {
    var id: String
    var name: String
    var type: String
    var payload: [Payload]
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case rocket_id
        case rocket_name
        case rocket_type
        case second_stage
    }
    
    enum SecondStageCodingKeys: String, CodingKey, CaseIterable {
        case payloads
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .rocket_id)
        name = try container.decode(String.self, forKey: .rocket_name)
        type = try container.decode(String.self, forKey: .rocket_type)

        payload = []
        if let secondStageContainer = try? container.nestedContainer(keyedBy: SecondStageCodingKeys.self, forKey: .second_stage) {
            payload = try secondStageContainer.decodeIfPresent([Payload].self, forKey: .payloads) ?? []
        }
    }
}

extension Rocket: MaskedModel {
    static var codingKeys: [CodingKey] {
        return CodingKeys.allCases
    }
    
    static func childrenCodingKeys(for key: CodingKey) -> [CodingKey]? {
        switch key {
            
        case CodingKeys.second_stage:
            return SecondStageCodingKeys.allCases
            
        case SecondStageCodingKeys.payloads:
            return Payload.codingKeys
            
        default:
            return Payload.childrenCodingKeys(for: key)
        }
    }
}

// MARK: - Payload

struct Payload: Decodable {
    var id: String
    var type: String
    var mass: Int
    var orbitType: String
    var customers: [String]

    enum CodingKeys: String, CodingKey, CaseIterable {
        case payload_id
        case payload_type
        case payload_mass_kg
        case orbit
        case customers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .payload_id)
        type = try container.decode(String.self, forKey: .payload_type)
        mass = try container.decode(Int.self, forKey: .payload_mass_kg)
        orbitType = try container.decode(String.self, forKey: .orbit)
        customers = try container.decode([String].self, forKey: .customers)
    }
}

extension Payload: MaskedModel {
    static var codingKeys: [CodingKey] {
        return CodingKeys.allCases
    }
    
    static func childrenCodingKeys(for key: CodingKey) -> [CodingKey]? {
        return nil
    }
}
