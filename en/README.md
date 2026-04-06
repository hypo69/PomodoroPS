# Building Your Own Pomodoro Timer in the System Tray with Pure PowerShell

The **[Pomodoro Technique](https://en.wikipedia.org/wiki/Pomodoro_Technique)** is a popular time management method developed by Francesco Cirillo in the late 1980s. The concept is simple: you break your work into 25-minute intervals (called "pomodoros"), separated by short 5-minute breaks. After every four cycles, you take a longer break. This approach helps maintain focus, prevents burnout, and provides better control over your workflow.

In this article, I will show you how to write your own Pomodoro timer using pure PowerShell. It will run in the background, display a countdown in the window title, and be controlled via a system tray context menu—**all while keeping the script under 100 lines of code**.

We will leverage the **.NET Framework** (WinForms libraries), which allows us to:

1. **Create an icon in the notification area (system tray).**
2. **Implement a context menu.**
3. **Use a "Timer" object for background code execution.**

---

## Step 1: Preparing Libraries and Variables

To create the graphical interface, we need the `System.Windows.Forms` and `System.Drawing` assemblies. We will also define the time settings and use the `$script:` scope to ensure that event handlers (menu clicks) have direct access to the timer variables.

```powershell
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Time settings (in minutes)
$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60
$script:isWorking = $true
```

## Step 2: Creating the Tray Icon (NotifyIcon)

The `NotifyIcon` object is responsible for the icon appearing in the system tray (next to the clock). For maximum stability in Windows 10/11, we will use the standard "Information" system icon (a blue circle with an "i").

```powershell
$script:ni = New-Object System.Windows.Forms.NotifyIcon
$script:ni.Icon = [System.Drawing.SystemIcons]::Information
$script:ni.Visible = $true
$script:ni.Text = "Pomodoro: Right-click to start"
```

## Step 3: Timer Logic and Phase Automation

The timer functions as an event that triggers every second. This logic includes an automatic transition: when the work time reaches zero, the script automatically switches to break mode and begins a new countdown.

*Important Note:* In modern PowerShell versions (7+), you must explicitly cast numbers to `[int]` when formatting strings to avoid processing errors.

```powershell
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000

$script:timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
    } else {
        # Switch mode Work <-> Break
        $script:isWorking = -not $script:isWorking
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        
        # Windows balloon notification
        $msg = if ($script:isWorking) { "Time to work!" } else { "Time for a break!" }
        $script:ni.ShowBalloonTip(5000, "Pomodoro", $msg, "Info")
    }

    # Visual Updates (Tray, Window Title, Console)
    [int]$m = [Math]::Floor($script:timeLeft / 60)
    [int]$s = $script:timeLeft % 60
    $phase = if ($script:isWorking) { "WORK" } else { "BREAK" }
    $displayTime = "{0:D2}:{1:D2}" -f $m, $s
    
    $script:ni.Text = "Pomodoro [$phase]: $displayTime"
    $host.UI.RawUI.WindowTitle = "[$displayTime] - $phase"
    Write-Host "`r>>> Phase: $phase | Time left: $displayTime    " -NoNewline -ForegroundColor Cyan
})
```

## Step 4: Context Menu Management

To ensure that menu buttons trigger reliably in any PowerShell version, we create them as individual `ToolStripMenuItem` objects and subscribe to the `Click` event.

```powershell
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$btnStart = New-Object System.Windows.Forms.ToolStripMenuItem("Start / Pause")
$btnStart.add_Click({
    if ($script:timer.Enabled) { $script:timer.Stop() } else { $script:timer.Start() }
})

$btnExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$btnExit.add_Click({
    $script:ni.Visible = $false
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

[void]$menu.Items.Add($btnStart)
[void]$menu.Items.Add("-") # Separator
[void]$menu.Items.Add($btnExit)
$script:ni.ContextMenuStrip = $menu
```

## Step 5: Starting the Event Loop

Without this method, the script would terminate immediately after execution. The `Run()` command forces the application to "wait" for user actions and timer signals.

```powershell
[System.Windows.Forms.Application]::Run()
```

---

**The final full code**
can be found in the repository: [pomodoro.ps1](https://github.com/hypo69/PomodoroPS/blob/master/ru/pomodoro.ps1) (Russian version, but code is universal).