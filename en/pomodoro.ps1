Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Time settings (in minutes)
$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60
$script:isWorking = $true

# Create objects
$script:ni = New-Object System.Windows.Forms.NotifyIcon
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000

# MAIN TIMER LOGIC
$script:timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
    } else {
        # When time is up: switch mode (Work <-> Break)
        $script:isWorking = -not $script:isWorking
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        
        # Notification
        $status = if ($script:isWorking) { "Work" } else { "Break" }
        $msg = if ($script:isWorking) { "Time to get to work!" } else { "Time for a break!" }
        $script:ni.ShowBalloonTip(5000, "Pomodoro: $status", $msg, "Info")
        Write-Host "`n[!] Phase change: $msg" -ForegroundColor Yellow
    }

    # UI UPDATE (every second)
    [int]$m = [Math]::Floor($script:timeLeft / 60)
    [int]$s = $script:timeLeft % 60
    $phase = if ($script:isWorking) { "WORK" } else { "BREAK" }
    $displayTime = "{0:D2}:{1:D2}" -f $m, $s
    
    # Tray icon tooltip text
    $script:ni.Text = "Pomodoro [$phase]: $displayTime"
    # Window title
    $host.UI.RawUI.WindowTitle = "[$displayTime] - $phase"
    # Console output
    $color = if ($script:isWorking) { "Cyan" } else { "Green" }
    Write-Host "`r>>> Current phase: $phase | Time left: $displayTime    " -NoNewline -ForegroundColor $color
})

# Icon Setup
$script:ni.Icon = [System.Drawing.SystemIcons]::Information
$script:ni.Visible = $true

# Context Menu
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$btnStart = New-Object System.Windows.Forms.ToolStripMenuItem("Start / Pause")
$btnReset = New-Object System.Windows.Forms.ToolStripMenuItem("Reset to Work Start")
$btnExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")

$btnStart.add_Click({
    if ($script:timer.Enabled) {
        $script:timer.Stop()
        Write-Host "`n>>> PAUSED" -ForegroundColor Yellow
    } else {
        $script:timer.Start()
        Write-Host "`n>>> TIMER STARTED" -ForegroundColor Green
    }
})

$btnReset.add_Click({
    $script:timer.Stop()
    $script:isWorking = $true
    $script:timeLeft = $workTime * 60
    Write-Host "`n>>> RESET TO WORK START" -ForegroundColor Gray
})

$btnExit.add_Click({
    $script:ni.Visible = $false
    $script:timer.Stop()
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

[void]$menu.Items.Add($btnStart)
[void]$menu.Items.Add($btnReset)
[void]$menu.Items.Add("-") # Separator
[void]$menu.Items.Add($btnExit)
$script:ni.ContextMenuStrip = $menu

Write-Host ">>> Pomodoro started." -ForegroundColor White
Write-Host ">>> Work duration: $workTime min, Break duration: $breakTime min." -ForegroundColor Gray
Write-Host ">>> RIGHT-CLICK the 'i' icon in the tray -> Start." -ForegroundColor Cyan

# Start the event loop
[System.Windows.Forms.Application]::Run()