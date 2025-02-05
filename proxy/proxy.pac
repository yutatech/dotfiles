function FindProxyForURL(url, host) {
    // プロキシを使用するホスト
    if (shExpMatch(host, "*.local") || isInNet(host, "192.168.2.0", "255.255.255.0") || shExpMatch(host, "captive.apple.com")) {
        return "SOCKS5 127.0.0.1:1080"; // プロキシ経由
    }
    
    return "DIRECT"; // それ以外は直接接続
}
