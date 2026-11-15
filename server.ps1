$port = 8080
$dir = "C:\Users\info\.gemini\antigravity\scratch\real-estate-assessment-app"
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
$listener.Start()
Write-Output "HTTP Server started on http://192.168.0.84:$port/"

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $requestLine = $reader.ReadLine()
        
        if ($requestLine) {
            $urlPath = $requestLine.Split(" ")[1]
            if ($urlPath -eq "/" -or [string]::IsNullOrEmpty($urlPath)) {
                $urlPath = "/index.html"
            }
            $cleanPath = $urlPath.Split("?")[0].TrimStart("/")
            $targetFile = Join-Path $dir $cleanPath

            if (Test-Path $targetFile -PathType Leaf) {
                $fileBytes = [System.IO.File]::ReadAllBytes($targetFile)
                $mimeType = "text/html; charset=utf-8"
                if ($targetFile.EndsWith(".svg")) { $mimeType = "image/svg+xml" }
                if ($targetFile.EndsWith(".json")) { $mimeType = "application/json" }
                
                $header = "HTTP/1.1 200 OK`r`nContent-Type: $mimeType`r`nContent-Length: $($fileBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nConnection: close`r`n`r`n"
                $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
                $stream.Write($headerBytes, 0, $headerBytes.Length)
                $stream.Write($fileBytes, 0, $fileBytes.Length)
            } else {
                $notFound = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 404 Not Found`r`nContent-Length: 0`r`nConnection: close`r`n`r`n")
                $stream.Write($notFound, 0, $notFound.Length)
            }
        }
        $stream.Close()
        $client.Close()
    }
} finally {
    $listener.Stop()
}
