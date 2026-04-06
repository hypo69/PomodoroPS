Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# הגדרות זמן (בדקות)
$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60
$script:isWorking = $true

# יצירת אובייקטים
$script:ni = New-Object System.Windows.Forms.NotifyIcon
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000

# לוגיקת הטיימר הראשית
$script:timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
    } else {
        # כשהזמן נגמר: מחליפים מצב (עבודה <-> הפסקה)
        $script:isWorking = -not $script:isWorking
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        
        # התראה למשתמש
        $status = if ($script:isWorking) { "עבודה" } else { "הפסקה" }
        $msg = if ($script:isWorking) { "הגיע הזמן לעבוד!" } else { "זמן לצאת להפסקה!" }
        $script:ni.ShowBalloonTip(5000, "Pomodoro: $status", $msg, "Info")
        Write-Host "`n[!] שינוי שלב: $msg" -ForegroundColor Yellow
    }

    # עדכון ממשק המשתמש (בכל שנייה)
    [int]$m = [Math]::Floor($script:timeLeft / 60)
    [int]$s = $script:timeLeft % 60
    $phase = if ($script:isWorking) { "עבודה" } else { "הפסקה" }
    $displayTime = "{0:D2}:{1:D2}" -f $m, $s
    
    # טקסט שיוצג במעבר עכבר על האייקון במגש המערכת
    $script:ni.Text = "פומודורו [$phase]: $displayTime"
    # כותרת החלון
    $host.UI.RawUI.WindowTitle = "[$displayTime] - $phase"
    # פלט לקונסולה
    $color = if ($script:isWorking) { "Cyan" } else { "Green" }
    Write-Host "`r>>> שלב נוכחי: $phase | זמן נותר: $displayTime    " -NoNewline -ForegroundColor $color
})

# הגדרת האייקון
$script:ni.Icon = [System.Drawing.SystemIcons]::Information
$script:ni.Visible = $true

# תפריט הקשר (לחיצה ימנית)
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$btnStart = New-Object System.Windows.Forms.ToolStripMenuItem("הפעלה / השהייה")
$btnReset = New-Object System.Windows.Forms.ToolStripMenuItem("איפוס לתחילת עבודה")
$btnExit = New-Object System.Windows.Forms.ToolStripMenuItem("יציאה")

$btnStart.add_Click({
    if ($script:timer.Enabled) {
        $script:timer.Stop()
        Write-Host "`n>>> השהייה" -ForegroundColor Yellow
    } else {
        $script:timer.Start()
        Write-Host "`n>>> הטיימר הופעל" -ForegroundColor Green
    }
})

$btnReset.add_Click({
    $script:timer.Stop()
    $script:isWorking = $true
    $script:timeLeft = $workTime * 60
    Write-Host "`n>>> איפוס לתחילת עבודה" -ForegroundColor Gray
})

$btnExit.add_Click({
    $script:ni.Visible = $false
    $script:timer.Stop()
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

[void]$menu.Items.Add($btnStart)
[void]$menu.Items.Add($btnReset)
[void]$menu.Items.Add("-") # קו מפריד
[void]$menu.Items.Add($btnExit)
$script:ni.ContextMenuStrip = $menu

Write-Host ">>> טיימר פומודורו הופעל." -ForegroundColor White
Write-Host ">>> זמן עבודה: $workTime דקות, זמן הפסקה: $breakTime דקות." -ForegroundColor Gray
Write-Host ">>> לחץ לחיצה ימנית על האייקון 'i' במגש המערכת -> הפעלה." -ForegroundColor Cyan

# הרצת לולאת האירועים של הממשק
[System.Windows.Forms.Application]::Run()