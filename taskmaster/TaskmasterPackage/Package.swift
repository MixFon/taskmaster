// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "taskmaster",
	products: [
		.executable(name: "taskmaster", targets: ["taskmaster"])
	],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/Kitura/Kitura", from: "2.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "taskmaster",
            dependencies: ["Kitura"]),
    ]
)
