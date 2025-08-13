//
//  OpenfortEIP1193Provider.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-13.
//

import Foundation
import WebKit
import Web3

/// Bridges Openfort’s JS EIP-1193 provider to Boilertalk/Web3.swift's `Web3Provider`.
/// It forwards JSON-RPC calls through the WKWebView using `provider.request({ method, params })`.
public final class OpenfortEIP1193Web3Provider: Web3Provider {

    // MARK: - Web3Provider conformance hooks (not used by this protocol directly, but Web3 may inspect them elsewhere)
    public typealias Web3ResponseCompletion<Result: Codable> = (_ resp: Web3Response<Result>) -> Void

    // MARK: - Internals
    private weak var webView: WKWebView?
    private let callbackQueue: DispatchQueue

    /// - Parameters:
    ///   - webView: The WKWebView hosting the Openfort page where `openfort.getEthereumProvider()` is available.
    ///   - callbackQueue: Queue used to deliver `Web3Response` callbacks (defaults to `.main`).
    public init(webView: WKWebView, callbackQueue: DispatchQueue = .main) {
        self.webView = webView
        self.callbackQueue = callbackQueue
    }

    // MARK: - Web3Provider requirement

    public func send<Params, Result>(
        request: RPCRequest<Params>,
        response: @escaping Web3ResponseCompletion<Result>
    ) {
        guard let webView else {
            callbackQueue.async { response(Web3Response<Result>(error: Web3Response<Result>.Error.connectionFailed(nil))) }
            return
        }

        // 1) Build JSON for `params`
        let paramsJSONString = makeParamsJSONString(request.params) ?? "[]"

        // 2) Build JS that lazily caches the provider and forwards the request
        let js = """
        (async function(){
          try {
            if (!window.__ofProvider) {
              if (!window.openfort || !window.openfort.getEthereumProvider) {
                throw new Error('Openfort provider not available in page');
              }
              window.__ofProvider = await window.openfort.getEthereumProvider();
            }
            const result = await window.__ofProvider.request({
              method: "\(request.method)",
              params: \(paramsJSONString)
            });
            return { ok: true, result };
          } catch (e) {
            return { ok: false, error: (e && (e.message || String(e))) };
          }
        })();
        """

        // 3) Evaluate and map back to Web3Response<Result>
        webView.evaluateJavaScript(js) { value, jsError in
            if let jsError {
                self.callbackQueue.async {
                    response(Web3Response<Result>(error: Web3Response<Result>.Error.requestFailed(jsError)))
                }
                return
            }

            guard let dict = value as? [String: Any] else {
                self.callbackQueue.async {
                    response(Web3Response<Result>(error: Web3Response<Result>.Error.emptyResponse))
                }
                return
            }

            if (dict["ok"] as? Bool) == true {
                let resultAny = dict["result"]
                // Try to decode into Result
                if let decoded: Result = self.decodeResult(resultAny) {
                    self.callbackQueue.async {
                        response(Web3Response<Result>(status: .success(decoded)))
                    }
                } else {
                    // If we fail to decode, surface a decoding error
                    self.callbackQueue.async {
                        response(Web3Response<Result>(error: Web3Response<Result>.Error.decodingError(nil)))
                    }
                }
            } else {
                let message = (dict["error"] as? String) ?? "Unknown JS bridge error"
                let err = NSError(domain: "OpenfortEIP1193Web3Provider", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: message])
                self.callbackQueue.async {
                    response(Web3Response<Result>(error: Web3Response<Result>.Error.serverError(err)))
                }
            }
        }
    }

    // MARK: - Encoding helpers

    /// Turns generic `Params?` into a JSON string literal suitable to embed into JS.
    private func makeParamsJSONString<Params>(_ params: Params?) -> String? {
        guard let params else { return "[]" }

        // First, try direct JSON encoding (works for Encodable arrays/dicts/primitives).
        if let encodable = params as? Encodable {
            do {
                let data = try encodeEncodableToJSON(encodable)
                return String(data: data, encoding: .utf8)
            } catch {
                // fallthrough
            }
        }

        // Next, try to convert common Foundation shapes
        if JSONSerialization.isValidJSONObject(params) {
            if let data = try? JSONSerialization.data(withJSONObject: params, options: []) {
                return String(data: data, encoding: .utf8)
            }
        }

        // As a last resort: wrap single items into an array
        if let data = try? JSONSerialization.data(withJSONObject: [params], options: []) {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    private func encodeEncodableToJSON(_ value: Encodable) throws -> Data {
        struct AnyEncodable: Encodable {
            let wrapped: Encodable
            func encode(to encoder: Encoder) throws { try wrapped.encode(to: encoder) }
        }
        return try JSONEncoder().encode(AnyEncodable(wrapped: value))
    }

    // MARK: - Decoding helpers

    /// Attempts to coerce the JS `result` into `Result`.
    private func decodeResult<Result: Codable>(_ any: Any?) -> Result? {
        guard let any else { return nil }

        // Fast-path for common primitives
        if Result.self == String.self, let s = any as? String { return s as? Result }
        if Result.self == Bool.self,   let b = any as? Bool   { return b as? Result }
        if Result.self == Int.self,    let i = any as? Int    { return i as? Result }
        if Result.self == Double.self, let d = any as? Double { return d as? Result }

        // If the result is already the right type (rare), just cast
        if let casted = any as? Result {
            return casted
        }

        // Otherwise, try JSON round‑trip:
        // - If it's JSON-serializable (dict/array/primitive), serialize then decode
        if JSONSerialization.isValidJSONObject(any),
           let data = try? JSONSerialization.data(withJSONObject: any, options: []) {
            if let decoded = try? JSONDecoder().decode(Result.self, from: data) {
                return decoded
            }
        }

        // If it’s a primitive (e.g., string) but Result is Codable (e.g., String),
        // encode that primitive alone to JSON data and decode it into Result.
        if let s = any as? String, let data = try? JSONEncoder().encode(s),
           let decoded = try? JSONDecoder().decode(Result.self, from: data) {
            return decoded
        }
        if let b = any as? Bool, let data = try? JSONEncoder().encode(b),
           let decoded = try? JSONDecoder().decode(Result.self, from: data) {
            return decoded
        }
        if let n = any as? NSNumber,
           let data = try? JSONEncoder().encode(n.stringValue),
           let decoded = try? JSONDecoder().decode(Result.self, from: data) {
            return decoded
        }

        return nil
    }
}
