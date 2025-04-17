$startPath = Join-Path -Path $PSScriptRoot -ChildPath "log.txt"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ⚙️ Configuración
$logPath = $startPath                      # Ruta al archivo de registro (usa "none" para desactivar o $startPath si está en la misma carpeta)
$gmailUser = "tuemail@gmail.com"          # Tu dirección de Gmail
$gmailAppPassword = "tu-contraseña-app"   # Contraseña de aplicación generada por Gmail
$thresholdGB = @(50, 40, 30, 20)          # Umbrales de advertencia (orden descendente)
$criticalThresholdGB = 10                # Umbral crítico (solo un valor)

# 📅 Fecha y hora actual
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# 🔐 Credenciales
$securePass = ConvertTo-SecureString $gmailAppPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($gmailUser, $securePass)

# 📊 Verificación de espacio en disco
$alerts = @()
$subject = $null
$drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"

foreach ($drive in $drives) {
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $deviceID = $drive.DeviceID

    if ($freeGB -lt $criticalThresholdGB) {
        $notHTMLformat = "🔥 CRÍTICO: El disco $deviceID tiene solo $freeGB GB libres de $totalGB GB (umbral: 10 GB)"
        $alerts += "🔥 <strong>CRÍTICO</strong>: El disco <strong>$deviceID</strong> tiene <strong>$freeGB GB</strong> libres de $totalGB GB (umbral: 10 GB)"
        $subject = "🔥🚨 ALERTA CRÍTICA: ¡Espacio en disco muy bajo!"
        continue
    }

    foreach ($threshold in $thresholdGB) {
        if ($freeGB -lt $threshold) {
            $notHTMLformat = "⚠️ ADVERTENCIA: El disco $deviceID tiene $freeGB GB libres de $totalGB GB (umbral: $threshold GB)"
            $alerts += "⚠️ <strong>ADVERTENCIA</strong>: El disco <strong>$deviceID</strong> tiene <strong>$freeGB GB</strong> libres de $totalGB GB (umbral: $threshold GB)"
            if (-not $subject) {
                $subject = "🚨 ALERTA: Espacio en disco bajo"
            }
            break
        }
    }
}

# ✉️ Envío de correo si hay alertas
if ($alerts.Count -gt 0 -and $subject) {
    $bodyInner = ($alerts -join "<br>")

    $bodyHtml = @"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: 'Segoe UI', sans-serif; font-size: 14px; }
    strong { color: #b30000; }
    .footer { font-size: 12px; color: gray; margin-top: 30px; }
    .timestamp { font-size: 12px; color: #666; }
    hr.custom { width: 50%; margin: 1px; border: 1px solid #ccc; opacity: 0.4; }
  </style>
</head>
<body>
  <h2>$subject</h2>
  <p>$bodyInner</p>
  <p class="timestamp">Fecha de generación: $timestamp</p>
  <hr class="custom">
  <div class="footer">
    <a href="https://github.com/Devs123Easy" target="_blank" style="text-decoration: none; color: inherit;">
      Desarrollado por Devs123Easy
      <img src="cid:logo123" style="height:30px; vertical-align:middle; margin-left:6px;" alt="Logo" />
    </a>
  </div>
</body>
</html>
"@

    # Logo en base64 (debes insertarlo tú mismo)
    $logoBase64 = "..." # Aquí va tu string base64
    $logoBytes = [Convert]::FromBase64String($logoBase64)
    $logoStream = New-Object System.IO.MemoryStream(,$logoBytes)
    $linkedLogo = New-Object System.Net.Mail.LinkedResource($logoStream, "image/png")
    $linkedLogo.ContentId = "logo123"
    $linkedLogo.TransferEncoding = [System.Net.Mime.TransferEncoding]::Base64

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $altView = [System.Net.Mail.AlternateView]::CreateAlternateViewFromString($bodyHtml, $utf8NoBom, "text/html")
    $altView.LinkedResources.Add($linkedLogo)

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = $gmailUser
    $mail.To.Add($gmailUser)
    $mail.Subject = $subject
    $mail.SubjectEncoding = $utf8NoBom
    $mail.BodyEncoding = $utf8NoBom
    $mail.IsBodyHtml = $true
    $mail.AlternateViews.Add($altView)

    $smtp = New-Object Net.Mail.SmtpClient("smtp.gmail.com", 587)
    $smtp.EnableSsl = $true
    $smtp.Credentials = $cred

    $smtp.Send($mail)

    if ($logPath -ne "none") {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -Path $logPath -ItemType File -Force | Out-Null
        }
        $logEntry = @"
[$timestamp]: Se envió un correo a $gmailUser con asunto "$subject" y contenido: "$notHTMLformat".
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
}
else {
    if ($logPath -ne "none") {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -Path $logPath -ItemType File -Force | Out-Null
        }
        $logEntry = @"
[$timestamp]: No se envió ningún correo porque hay suficiente espacio libre en el disco.
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
}
