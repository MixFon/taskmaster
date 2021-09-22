// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let namePac = "Taskmaster"

let package = Package(
    name: namePac,
	products: [
		.executable(name: namePac, targets: [namePac])
	],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/Kitura/Kitura", from: "2.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Taskmaster",
			dependencies: ["Kitura"]),
    ]
)
