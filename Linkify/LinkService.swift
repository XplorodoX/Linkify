import Foundation
import SwiftSoup

class LinkService {
    enum LinkError: Error {
        case invalidURL
        case fetchFailed
        case parsingFailed
        case summaryFailed
    }
    
    func fetchContent(from urlString: String) async throws -> (String, String) {
        guard let url = URL(string: urlString) else {
            throw LinkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let htmlString = String(data: data, encoding: .utf8) else {
            throw LinkError.fetchFailed
        }
        
        // Parse HTML to get the title and content
        do {
            let doc = try SwiftSoup.parse(htmlString)
            let title = try doc.title()
            
            // Extract main content (this is a simplified approach - real implementation might be more complex)
            try doc.select("script, style, nav, footer, header, aside").remove() // Remove non-content elements
            let content = try doc.select("body").text()
            
            return (title, content)
        } catch {
            throw LinkError.parsingFailed
        }
    }
    
    func summarizeContent(_ content: String, title: String) async throws -> String {
        // Connect to Ollama running locally
        let ollamaURL = URL(string: "http://localhost:11434/api/generate")!
        var request = URLRequest(url: ollamaURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the prompt for the LLM
        let prompt = """
        Summarize the following webpage content in 3-5 sentences, highlighting the key points. 
        Title: \(title)
        
        Content:
        \(content.prefix(8000)) // Limit content to avoid token limits
        """
        
        let requestBody: [String: Any] = [
            "model": "deepseek-r1-7b", // Use deepseek model
            "prompt": prompt,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = responseJSON["response"] as? String else {
            throw LinkError.summaryFailed
        }
        
        return responseText
    }
}
