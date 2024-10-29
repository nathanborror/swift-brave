import Foundation
import ArgumentParser
import Brave

@main
struct Command: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "A utility for interacting with the Brave API.",
        version: "0.0.1",
        subcommands: [
            Search.self,
        ],
        defaultSubcommand: Search.self
    )
}

struct GlobalOptions: ParsableCommand {
    @Option(name: .shortAndLong, help: "Your API token.")
    var token: String
}

struct Search: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Returns search results."
    )
    
    @OptionGroup
    var global: GlobalOptions
    
    @Argument(help: "Your search query.")
    var query: String
    
    func run() async throws {
        let client = Client(token: global.token)
        let result = try await client.search(query: query)
        print(result)
    }
}
