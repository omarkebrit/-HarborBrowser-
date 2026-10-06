import Foundation
import WebKit

let path = CommandLine.arguments[1]
let json = try String(contentsOfFile: path, encoding: .utf8)
let rules = try JSONSerialization.jsonObject(with: Data(json.utf8)) as! [[String: Any]]
let exceptions = rules.filter { ($0["action"] as? [String: Any])?["type"] as? String == "ignore-previous-rules" }
guard rules.count > 1000, !exceptions.isEmpty else { fatalError("Expected broad filters and exceptions") }
var finished = false
var failure: Error?
WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "harbor-ci-validation", encodedContentRuleList: json) { list, error in
    failure = error
    if list == nil && error == nil { failure = NSError(domain: "Harbor", code: 1) }
    finished = true
}
let deadline = Date().addingTimeInterval(180)
while !finished && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.1)) }
guard finished else { fatalError("WebKit validation timed out") }
if let failure { fatalError("WebKit rejected filters: \(failure)") }
print("WebKit compiled \(rules.count) rules with \(exceptions.count) exceptions")
