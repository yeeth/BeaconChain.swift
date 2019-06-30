.PHONY: documentation test link xcode

test:
	swift test

lint:
	swiftlint

documentation:
	jazzy --author "yeeth" --author_url https://yeeth.af  --github_url https://github.com/yeeth/BeaconChain.swift
	rm -rf build/

xcode:
	swift package generate-xcodeproj

