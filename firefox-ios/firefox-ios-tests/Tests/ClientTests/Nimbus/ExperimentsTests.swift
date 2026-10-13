// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
import struct MozillaAppServices.EnrolledExperiment
@testable import Client

final class ExperimentsTests: XCTestCase {
    func testShouldFetchRemoteExperiments_whenConsentIsUnset_staysDisabled() {
        let prefs = MockProfilePrefs()

        XCTAssertFalse(Experiments.shouldFetchRemoteExperiments(prefs: prefs))
        XCTAssertNil(prefs.boolForKey(AppConstants.prefStudiesToggle))
        XCTAssertNil(prefs.boolForKey(AppConstants.prefRolloutsToggle))
    }

    func testShouldFetchRemoteExperiments_whenBothConsentSettingsAreDisabled_staysDisabled() {
        let prefs = MockProfilePrefs()
        prefs.setBool(false, forKey: AppConstants.prefStudiesToggle)
        prefs.setBool(false, forKey: AppConstants.prefRolloutsToggle)

        XCTAssertFalse(Experiments.shouldFetchRemoteExperiments(prefs: prefs))
    }

    func testShouldFetchRemoteExperiments_whenStudiesAreExplicitlyEnabled_isEnabled() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: AppConstants.prefStudiesToggle)
        prefs.setBool(false, forKey: AppConstants.prefRolloutsToggle)

        XCTAssertTrue(Experiments.shouldFetchRemoteExperiments(prefs: prefs))
    }

    func testShouldFetchRemoteExperiments_whenRolloutsAreExplicitlyEnabled_isEnabled() {
        let prefs = MockProfilePrefs()
        prefs.setBool(false, forKey: AppConstants.prefStudiesToggle)
        prefs.setBool(true, forKey: AppConstants.prefRolloutsToggle)

        XCTAssertTrue(Experiments.shouldFetchRemoteExperiments(prefs: prefs))
    }

    func testShouldFetchRemoteExperiments_whenOnlyTechnicalTelemetryIsEnabled_staysDisabled() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: AppConstants.prefSendUsageData)

        XCTAssertFalse(Experiments.shouldFetchRemoteExperiments(prefs: prefs))
    }

    func testFeatureBranches_noActiveExperiments_isEmpty() {
        XCTAssertEqual(Experiments.featureBranches(from: []), [:])
    }

    func testFeatureBranches_mapsEachFeatureToItsBranch() {
        let experiments = [
            makeEnrollment(slug: "homepage-test", featureIds: ["homepage"], branch: "control"),
            makeEnrollment(slug: "tab-tray-test", featureIds: ["tab-tray"], branch: "treatment-a")
        ]

        XCTAssertEqual(Experiments.featureBranches(from: experiments),
                       ["homepage": "control", "tab-tray": "treatment-a"])
    }

    func testFeatureBranches_multiFeatureExperiment_mapsEveryFeature() {
        let experiments = [
            makeEnrollment(slug: "onboarding-test", featureIds: ["onboarding", "homepage"], branch: "treatment-a")
        ]

        XCTAssertEqual(Experiments.featureBranches(from: experiments),
                       ["onboarding": "treatment-a", "homepage": "treatment-a"])
    }

    func testFeatureBranches_rolloutOnly_isIncluded() {
        let experiments = [
            makeEnrollment(slug: "homepage-rollout", featureIds: ["homepage"], branch: "rollout", isRollout: true)
        ]

        XCTAssertEqual(Experiments.featureBranches(from: experiments), ["homepage": "rollout"])
    }

    func testFeatureBranches_experimentAndRolloutOnSameFeature_experimentWins() {
        let experiment = makeEnrollment(slug: "homepage-test", featureIds: ["homepage"], branch: "treatment-a")
        let rollout = makeEnrollment(slug: "homepage-rollout", featureIds: ["homepage"], branch: "rollout", isRollout: true)

        XCTAssertEqual(Experiments.featureBranches(from: [experiment, rollout]), ["homepage": "treatment-a"])
        XCTAssertEqual(Experiments.featureBranches(from: [rollout, experiment]), ["homepage": "treatment-a"])
    }

    private func makeEnrollment(slug: String,
                                featureIds: [String],
                                branch: String,
                                isRollout: Bool = false) -> EnrolledExperiment {
        return EnrolledExperiment(
            featureIds: featureIds,
            slug: slug,
            userFacingName: slug,
            userFacingDescription: slug,
            branchSlug: branch,
            isRollout: isRollout
        )
    }
}
