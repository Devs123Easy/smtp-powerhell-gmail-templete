$startPath = Join-Path -Path $PSScriptRoot -ChildPath "log.txt"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# WICHTIG! Führe dieses Skript mit PowerShell 7.5.0 oder neuer aus.

###############################
##                           ##
##  📦 KONFIGURATION 🇩🇪   ##
##                           ##
###############################
$logPath = $startPath                         # Pfad zur Log-Datei ("none" um Logging zu deaktivieren)
$gmailUser = "deingmail@gmail.com"            # Deine Gmail-Adresse
$gmailAppPassword = "deinAppPasswort"         # 16-stelliges Gmail-App-Passwort (siehe Anleitung unten)

# 👉 Anleitung zum Erstellen eines Gmail-App-Passworts:
# 1. Zwei-Faktor-Authentifizierung aktivieren: https://myaccount.google.com/security
# 2. Gehe zu: https://myaccount.google.com/apppasswords
#    - Wähle "Mail", dann "Sonstige", gib z.B. "PowerShell" ein
#    - Klicke auf "Generieren" und kopiere das Passwort oben ein (ohne Leerzeichen)

$thresholdGB = @(50, 40, 30, 20)              # Warnschwellen in absteigender Reihenfolge
$criticalThresholdGB = 10                     # Kritischer Schwellenwert (nur eine Zahl)

# Zeitstempel und Anmeldedaten
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$securePass = ConvertTo-SecureString $gmailAppPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($gmailUser, $securePass)

# 🖼️ Logo als Base64 (przytnij dla przykładu)
$logoBase64 = "<DEIN_BASE64_LOGO_HIER>"

# Festplatten prüfen
$alerts = @()
$subject = $null
$drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"

foreach ($drive in $drives) {
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $deviceID = $drive.DeviceID

    if ($freeGB -lt $criticalThresholdGB) {
        $notHTMLformat = "🔥 KRITISCH: Laufwerk $deviceID hat nur $freeGB GB von $totalGB GB frei (Grenze: 10 GB)"
        $alerts += "🔥 <strong>KRITISCH</strong>: Laufwerk <strong>$deviceID</strong> hat <strong>$freeGB GB</strong> von $totalGB GB frei (Grenze: 10 GB)"
        $subject = "🔥🚨 KRITISCHE WARNUNG: Wenig Speicherplatz!"
        continue
    }

    foreach ($threshold in $thresholdGB) {
        if ($freeGB -lt $threshold) {
            $notHTMLformat = "⚠️ WARNUNG: Laufwerk $deviceID hat nur $freeGB GB von $totalGB GB frei (Grenze: $threshold GB)"
            $alerts += "⚠️ <strong>WARNUNG</strong>: Laufwerk <strong>$deviceID</strong> hat <strong>$freeGB GB</strong> von $totalGB GB frei (Grenze: $threshold GB)"
            if (-not $subject) {
                $subject = "🚨 WARNUNG: Speicherplatz wird knapp!"
            }
            break
        }
    }
}

# E-Mail senden
if ($alerts.Count -gt 0 -and $subject) {
    $bodyInner = ($alerts -join "<br>")

    $bodyHtml = @"
<!DOCTYPE html>
<html lang="de">
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
  <p class="timestamp">Erstellt am: $timestamp</p>
  <hr class="custom">
  <div class="footer">
    <a href="https://github.com/Devs123Easy" target="_blank" style="text-decoration: none; color: inherit;">
      Powered by Devs123Easy
      <img src="cid:logo123" style="height:30px; vertical-align:middle; margin-left:6px;" alt="Logo" />
    </a>
  </div>
</body>
</html>
"@

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

    # Logging
    if ($logPath -ne "none") {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -Path $logPath -ItemType File -Force | Out-Null
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                Logdatei Beginn                                                ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "" -Encoding UTF8
        }
        $logEntry = @"
[$timestamp]: E-Mail an $gmailUser gesendet mit Betreff: "$subject" und Inhalt: "$notHTMLformat".
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
}
else {
    if ($logPath -ne "none") {
        if (-not (Test-Path -Path $logPath)) {
            New-Item -Path $logPath -ItemType File -Force | Out-Null
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "##                                                Logdatei Beginn                                                ##" -Encoding UTF8
            Add-Content -Path $logPath -Value "#############################################################" -Encoding UTF8
            Add-Content -Path $logPath -Value "" -Encoding UTF8
        }
        $logEntry = @"
[$timestamp]: Keine E-Mail gesendet. Es sind noch $freeGB GB von insgesamt $totalGB GB verfügbar.
----------------------------------------
"@
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    }
}
