// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
   name: "GitDiffSwift",
   products: [
      .library(name: "GitDiffSwift", targets: ["GitDiffSwift"])
   ],
   dependencies: [ ],
   targets: [
      .target(name: "GitDiffSwift", dependencies: [], path: "Sources")
   ]
)
