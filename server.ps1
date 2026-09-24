$port = 8080
$folder = "c:\Users\orischen\Documents\lethal calculator"

# Get local IPv4
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^127\.' -and $_.IPAddress -notmatch '^169\.254\.' } | Select-Object -ExpandProperty IPAddress

Clear-Host
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "       OPTCG 斬殺計算機 - 手機連線與安裝伺服器" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "請確保您的手機與這台電腦連接在【同一個 Wi-Fi 網絡】下。" -ForegroundColor White
Write-Host "在您的 iPhone (Safari) 或 Android (Chrome) 瀏覽器中輸入以下任一網址：" -ForegroundColor White
Write-Host ""

foreach ($ip in $ips) {
    Write-Host "   👉  http://${ip}:${port}/" -ForegroundColor Green
}

Write-Host ""
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "📱 手機安裝為 App 步驟：" -ForegroundColor Yellow
Write-Host "  【iOS iPhone】: 用 Safari 開啟網址 -> 點底部「分享」圖示 -> 選「加入主畫面」" -ForegroundColor White
Write-Host "  【Android】  : 用 Chrome 開啟網址 -> 點右上角選單 -> 選「安裝應用程式」或「新增至主畫面」" -ForegroundColor White
Write-Host "  安裝後具備離線快取，之後隨時在手機桌面像原生 App 一樣打開！" -ForegroundColor Green
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "伺服器運行中... (按 Ctrl+C 可停止伺服器)" -ForegroundColor Gray
Write-Host ""

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")
try {
    $listener.Start()
} catch {
    # If wildcard binding fails due to permissions, bind to specific IP or localhost
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://*:$port/")
    try {
        $listener.Start()
    } catch {
        $listener = New-Object System.Net.HttpListener
        foreach ($ip in $ips) {
            $listener.Prefixes.Add("http://${ip}:${port}/")
        }
        $listener.Prefixes.Add("http://localhost:${port}/")
        $listener.Start()
    }
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $urlPath = $request.Url.LocalPath.TrimStart('/')
    if ([string]::IsNullOrEmpty($urlPath) -or $urlPath -eq "/") {
        $urlPath = "index.html"
    }

    $filePath = Join-Path $folder $urlPath

    if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $contentType = "application/octet-stream"
        switch ($ext) {
            ".html" { $contentType = "text/html; charset=utf-8" }
            ".js"   { $contentType = "application/javascript; charset=utf-8" }
            ".json" { $contentType = "application/json; charset=utf-8" }
            ".png"  { $contentType = "image/png" }
            ".ico"  { $contentType = "image/x-icon" }
            ".css"  { $contentType = "text/css; charset=utf-8" }
            ".webmanifest" { $contentType = "application/manifest+json; charset=utf-8" }
        }

        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.AddHeader("Cache-Control", "no-cache")
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $response.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $response.OutputStream.Write($msg, 0, $msg.Length)
    }
    $response.Close()
}
