$root = "D:\Card_Game\age-of-guthology"
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 4601)
$listener.Start()
Write-Host "Serving $root on http://localhost:4601/"
$types = @{
  ".html"="text/html; charset=utf-8"; ".js"="text/javascript"; ".css"="text/css";
  ".webp"="image/webp"; ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg";
  ".svg"="image/svg+xml"; ".json"="application/json"
}
while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $requestLine = $reader.ReadLine()
    while ($true) {
      $line = $reader.ReadLine()
      if ($null -eq $line -or $line -eq '') { break }
    }
    $status = '404 Not Found'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes('404')
    $ctype = 'text/plain'
    if ($requestLine -match '^GET\s+(\S+)') {
      $path = [uri]::UnescapeDataString($matches[1].Split('?')[0])
      if ($path -eq '/') { $path = '/index.html' }
      $file = Join-Path $root ($path.TrimStart('/') -replace '/', '\')
      if (Test-Path $file -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $status = '200 OK'
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        if ($types.ContainsKey($ext)) { $ctype = $types[$ext] } else { $ctype = 'application/octet-stream' }
      }
    }
    $header = "HTTP/1.1 $status`r`nContent-Type: $ctype`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($hb, 0, $hb.Length)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
  } catch {}
  finally { $client.Close() }
}
