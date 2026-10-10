# Aster privacy information

Aster is an independent browser built from Firefox for iOS. It is not operated by Mozilla or Brave. This document describes this fork's configured behavior; websites and optional service providers have their own policies.

## Browser data

Regular browsing can store history, bookmarks, saved logins, tabs, website cookies and local storage on the device. Downloads are saved in the application's Documents/Downloads directory. Browser controls let you clear supported categories of data. Files you export or share can remain outside the app.

Private tabs use separate nonpersistent website data and do not add their page titles to regular browsing history. Private browsing does not conceal your IP address from websites, your network or service providers. It does not erase files you intentionally download or export.

## Protection and network requests

Native tracking protection and the bundled advertising rules block matching requests. You may create an exception for a site. Lists cannot detect every tracker, block every advertisement or guarantee that a site will keep working. CI refreshes the advertising lists when building the application; there is no in-app advertising-list background updater.

Visiting a page sends requests to that page and its allowed resources. Search, suggestions, safe-browsing checks, images, remote configuration and other inherited browser functions may contact their configured providers. Usage collection being off does not make the browser offline. Search settings and site permissions affect some of these requests.

## Optional data and services

Technical/interaction collection, crash reports, daily usage, remote studies and rollouts are configured off by default. Missing consent remains off, including in the inherited Sync provider. Enabling technical collection does not automatically enable studies. Preferences can be revoked in settings.

Inherited collection and account code uses Mozilla's infrastructure; opting into those functions may send data to Mozilla rather than an Aster-operated service. Aster has no dedicated analytics or account server. Refer to [Mozilla's privacy notices](https://www.mozilla.org/privacy/) before using optional Mozilla services. Firefox Account integration is inherited and has not been certified end to end for Aster's independent application identifier.

Microphone, camera, location, photos and other device permissions are controlled by iOS and the browser's site-permission controls. A website's permissions do not remove its own privacy responsibilities.

## Reports and contributions

Opening the project support or feedback links does not submit a report automatically. If you submit a GitHub issue, its contents are governed by the repository visibility and GitHub's policies. Review screenshots, addresses and logs before sharing them.

This is an engineering description of the current fork, not a claim that all privacy behavior has been audited. Physical-device checks and a complete service/network audit remain outstanding.
