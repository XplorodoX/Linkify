import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var links: [LinkItem]
    
    @State private var newLinkURL: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    let linkService = LinkService()
    
    var body: some View {
        NavigationSplitView {
            VStack {
                // Link input field
                HStack {
                    TextField("Enter URL", text: $newLinkURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addLink) {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(isProcessing || newLinkURL.isEmpty)
                }
                .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Links list
                List {
                    ForEach(links) { link in
                        NavigationLink {
                            LinkDetailView(link: link)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(link.title.isEmpty ? link.url : link.title)
                                        .fontWeight(.bold)
                                    Text(link.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if link.isProcessing {
                                    ProgressView()
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteLinks)
                }
            }
            .navigationTitle("Linkify")
            .toolbar {
                ToolbarItem {
                    Button(action: addLink) {
                        Label("Add Link", systemImage: "plus")
                    }
                    .disabled(isProcessing || newLinkURL.isEmpty)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        } detail: {
            Text("Select a link")
        }
    }
    
    private func addLink() {
        guard !newLinkURL.isEmpty else { return }
        
        // Add http:// if missing
        var urlString = newLinkURL
        if !urlString.contains("://") {
            urlString = "https://" + urlString
        }
        
        isProcessing = true
        errorMessage = nil
        
        let newLink = LinkItem(url: urlString, isProcessing: true)
        modelContext.insert(newLink)
        
        Task {
            do {
                let (title, content) = try await linkService.fetchContent(from: urlString)
                let summary = try await linkService.summarizeContent(content, title: title)
                
                await MainActor.run {
                    newLink.title = title
                    newLink.content = content
                    newLink.summary = summary
                    newLink.isProcessing = false
                    newLinkURL = ""
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    newLink.isProcessing = false
                    isProcessing = false
                    errorMessage = "Error: \(error.localizedDescription)"
                    
                    // Keep the link but mark as failed
                    newLink.title = "Failed to process"
                    newLink.summary = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteLinks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(links[index])
            }
        }
    }
}

struct LinkDetailView: View {
    let link: LinkItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(link.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Button(action: {
                    if let url = URL(string: link.url) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack {
                        Text(link.url)
                            .foregroundColor(.blue)
                        Image(systemName: "arrow.up.right.square")
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Summary")
                        .font(.headline)
                    
                    if link.isProcessing {
                        ProgressView("Generating summary...")
                    } else {
                        Text(link.summary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LinkItem.self, inMemory: true)
}
