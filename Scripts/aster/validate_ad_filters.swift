import Foundation
import WebKit

guard CommandLine.arguments.count == 2 else { fatalError("Pass the bundled ads.json path") }
let json = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
let rules = try JSONSerialization.jsonObject(with: Data(json.utf8)) as! [[String: Any]]
guard rules.count > 1000, rules.count < 150_000,
      rules.contains(where: { ($0["action"] as? [String: Any])?["type"] as? String == "ignore-previous-rules" }) else {
    fatalError("CI requires the generated broad ad pack with upstream exceptions, not the local starter pack")
}
var completed = false
var compileError: Error?
WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "aster-ci-ad-validation", encodedContentRuleList: json) { list, error in
    compileError = error
    if list == nil && error == nil { compileError = NSError(domain: "Aster.AdFilters", code: 1) }
    completed = true
}
let deadline = Date().addingTimeInterval(180)
while !completed && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.1)) }
guard completed else { fatalError("WebKit ad-pack compilation timed out") }
if let compileError { fatalError("WebKit rejected the ad pack: \(compileError)") }
print("WebKit compiled \(rules.count) ad rules including upstream exceptions")
