## GitHub Copilot Chat

- Extension: 0.42.2 (prod)
- VS Code: 1.113.0 (cfbea10c5ffb233ea9177d34726e6056e89913dc)
- OS: win32 10.0.26200 x64
- GitHub Account: ermizamr

## Network

User Settings:

```json
  "http.systemCertificatesNode": true,
  "github.copilot.advanced.debug.useElectronFetcher": true,
  "github.copilot.advanced.debug.useNodeFetcher": false,
  "github.copilot.advanced.debug.useNodeFetchFetcher": true
```

Connecting to https://api.github.com:

- DNS ipv4 Lookup: Error (1 ms): getaddrinfo ENOTFOUND api.github.com
- DNS ipv6 Lookup: Error (1 ms): getaddrinfo ENOTFOUND api.github.com
- Proxy URL: None (1 ms)
- Electron fetch (configured): Error (3 ms): Error: net::ERR_INTERNET_DISCONNECTED
  at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
  at SimpleURLLoaderWrapper.emit (node:events:519:28)
  at SimpleURLLoaderWrapper.emit (node:domain:489:12)
  {"is_request_error":true,"network_process_crashed":false}
- Node.js https: Error (7 ms): Error: getaddrinfo ENOTFOUND api.github.com
  at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
- Node.js fetch: Error (13 ms): TypeError: fetch failed
  at node:internal/deps/undici/undici:14902:13
  at processTicksAndRejections (node:internal/process/task_queues:103:5)
  at t.\_fetch (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5171:5228)
  at t.fetch (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5171:4540)
  at u (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5203:186)
  at cg.\_executeContributedCommand (file:///c:/Users/admin/AppData/Local/Programs/Microsoft%20VS%20Code/cfbea10c5f/resources/app/out/vs/workbench/api/node/extensionHostProcess.js:501:48675)
  Error: getaddrinfo ENOTFOUND api.github.com
  at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Connecting to https://api.githubcopilot.com/_ping:

- DNS ipv4 Lookup: Error (1 ms): getaddrinfo ENOTFOUND api.githubcopilot.com
- DNS ipv6 Lookup: Error (1 ms): getaddrinfo ENOTFOUND api.githubcopilot.com
- Proxy URL: None (1 ms)
- Electron fetch (configured): Error (1 ms): Error: net::ERR_INTERNET_DISCONNECTED
  at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
  at SimpleURLLoaderWrapper.emit (node:events:519:28)
  at SimpleURLLoaderWrapper.emit (node:domain:489:12)
  {"is_request_error":true,"network_process_crashed":false}
- Node.js https: Error (7 ms): Error: getaddrinfo ENOTFOUND api.githubcopilot.com
  at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
- Node.js fetch: Error (11 ms): TypeError: fetch failed
  at node:internal/deps/undici/undici:14902:13
  at processTicksAndRejections (node:internal/process/task_queues:103:5)
  at t.\_fetch (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5171:5228)
  at t.fetch (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5171:4540)
  at u (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5203:186)
  at cg.\_executeContributedCommand (file:///c:/Users/admin/AppData/Local/Programs/Microsoft%20VS%20Code/cfbea10c5f/resources/app/out/vs/workbench/api/node/extensionHostProcess.js:501:48675)
  Error: getaddrinfo ENOTFOUND api.githubcopilot.com
  at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Connecting to https://copilot-proxy.githubusercontent.com/_ping:

- DNS ipv4 Lookup: Error (1 ms): getaddrinfo ENOTFOUND copilot-proxy.githubusercontent.com
- DNS ipv6 Lookup: Error (0 ms): getaddrinfo ENOTFOUND copilot-proxy.githubusercontent.com
- Proxy URL: None (1 ms)
- Electron fetch (configured): Error (1 ms): Error: net::ERR_INTERNET_DISCONNECTED
  at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
  at SimpleURLLoaderWrapper.emit (node:events:519:28)
  at SimpleURLLoaderWrapper.emit (node:domain:489:12)
  {"is_request_error":true,"network_process_crashed":false}
- Node.js https: Error (7 ms): Error: getaddrinfo ENOTFOUND copilot-proxy.githubusercontent.com
  at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
- Node.js fetch: Error (12 ms): TypeError: fetch failed
  at node:internal/deps/undici/undici:14902:13
  at processTicksAndRejections (node:internal/process/task_queues:103:5)
  at t.\_fetch (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5171:5228)
  at t.fetch (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5171:4540)
  at u (c:\Users\admin\.vscode\extensions\github.copilot-chat-0.42.2\dist\extension.js:5203:186)
  at cg.\_executeContributedCommand (file:///c:/Users/admin/AppData/Local/Programs/Microsoft%20VS%20Code/cfbea10c5f/resources/app/out/vs/workbench/api/node/extensionHostProcess.js:501:48675)
  Error: getaddrinfo ENOTFOUND copilot-proxy.githubusercontent.com
  at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Connecting to https://mobile.events.data.microsoft.com: Error (2 ms): Error: net::ERR_INTERNET_DISCONNECTED
at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
at SimpleURLLoaderWrapper.emit (node:events:519:28)
at SimpleURLLoaderWrapper.emit (node:domain:489:12)
{"is_request_error":true,"network_process_crashed":false}
Connecting to https://dc.services.visualstudio.com: Error (1 ms): Error: net::ERR_INTERNET_DISCONNECTED
at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
at SimpleURLLoaderWrapper.emit (node:events:519:28)
at SimpleURLLoaderWrapper.emit (node:domain:489:12)
{"is_request_error":true,"network_process_crashed":false}
Connecting to https://copilot-telemetry.githubusercontent.com/_ping: Error (7 ms): Error: getaddrinfo ENOTFOUND copilot-telemetry.githubusercontent.com
at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
Connecting to https://copilot-telemetry.githubusercontent.com/_ping: Error (7 ms): Error: getaddrinfo ENOTFOUND copilot-telemetry.githubusercontent.com
at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
Connecting to https://default.exp-tas.com: Error (6 ms): Error: getaddrinfo ENOTFOUND default.exp-tas.com
at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Number of system certificates: 80

## Documentation

In corporate networks: [Troubleshooting firewall settings for GitHub Copilot](https://docs.github.com/en/copilot/troubleshooting-github-copilot/troubleshooting-firewall-settings-for-github-copilot).
