# Lấy IP IPv4 của card mạng Wi-Fi đang hoạt động
$ip = (Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
if (-not $ip) {
    # Nếu không tìm thấy Wi-Fi, lấy IP của interface đang có kết nối internet/default gateway
    $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($route) {
        $ip = (Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4).IPAddress
    }
}
if (-not $ip) {
    # Fallback lấy IP non-loopback đầu tiên tìm thấy
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.InterfaceAlias -notmatch "Loopback" } | Select-Object -First 1).IPAddress
}
if (-not $ip) {
    $ip = "10.0.2.2" # default emulator IP fallback
}

# Đường dẫn ghi file config.json ở thư mục gốc dự án
$outputPath = Join-Path $PSScriptRoot "..\config.json"

# Đọc cấu hình cũ nếu có để bảo toàn các thiết lập khác (như NGROK_URL, USE_NGROK)
$config = @{}
if (Test-Path $outputPath) {
    try {
        $raw = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
        foreach ($prop in $raw.PSObject.Properties) {
            $config[$prop.Name] = $prop.Value
        }
    } catch {
        Write-Host "Could not parse existing config.json, creating a new one."
    }
}

# Cập nhật LAPTOP_IP
$config["LAPTOP_IP"] = $ip

# Ghi lại file config.json dưới dạng JSON
$configJson = $config | ConvertTo-Json
$configJson | Out-File -FilePath $outputPath -Encoding utf8 -Force
Write-Host "Updated config.json with LAPTOP_IP: $ip"

