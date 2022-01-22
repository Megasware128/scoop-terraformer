Get-ChildItem '.\bucket\terraformer-*' | Remove-Item

$release = Invoke-WebRequest 'https://api.github.com/repos/GoogleCloudPlatform/terraformer/releases/latest' | Select-Object -ExpandProperty Content -First 1 | ConvertFrom-Json
$providers = $release.assets | Where-Object name -Like 'terraformer-*-windows-amd64.exe' | Select-Object -ExpandProperty name | ForEach-Object { $_ -replace 'terraformer-' -replace '-windows-amd64.exe' }

foreach ($provider in $providers) {
    $template = Get-Content '.\bucket\terraformer.json' | ConvertFrom-Json
    $template.architecture.'64bit'.url = $template.architecture.'64bit'.url -replace 'all', $provider -replace '#/terraformer.exe', ".exe#/terraformer-$provider.exe"
    $template.autoupdate.architecture.'64bit'.url = $template.autoupdate.architecture.'64bit'.url -replace 'all', $provider -replace '#/terraformer.exe', ".exe#/terraformer-$provider.exe"
    $template.bin = "terraformer-$provider.exe"
    $result = Invoke-WebRequest $template.architecture.'64bit'.url
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($result.Content)
    $template.architecture.'64bit'.hash = [BitConverter]::ToString($hash).ToLowerInvariant() -replace '-'
    ConvertTo-Json $template -Depth 3 | Out-File ".\bucket\terraformer-$provider.json" -Encoding utf8
}
