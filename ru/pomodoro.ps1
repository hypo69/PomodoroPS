Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Настройки времени (в минутах)
$workTime = 25
$breakTime = 5
$script:timeLeft = $workTime * 60
$script:isWorking = $true

# Создаем объекты
$script:ni = New-Object System.Windows.Forms.NotifyIcon
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000

# ГЛАВНАЯ ЛОГИКА ТАЙМЕРА
$script:timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
    } else {
        # Когда время вышло: меняем режим (Работа <-> Отдых)
        $script:isWorking = -not $script:isWorking
        $script:timeLeft = ($script:isWorking ? $workTime : $breakTime) * 60
        
        # Уведомление
        $status = if ($script:isWorking) { "Работа" } else { "Отдых" }
        $msg = if ($script:isWorking) { "Пора за работу!" } else { "Время отдохнуть!" }
        $script:ni.ShowBalloonTip(5000, "Pomodoro: $status", $msg, "Info")
        Write-Host "`n[!] Смена фазы: $msg" -ForegroundColor Yellow
    }

    # ОБНОВЛЕНИЕ ЭКРАНА (каждую секунду)
    [int]$m = [Math]::Floor($script:timeLeft / 60)
    [int]$s = $script:timeLeft % 60
    $phase = if ($script:isWorking) { "РАБОТА" } else { "ОТДЫХ" }
    $displayTime = "{0:D2}:{1:D2}" -f $m, $s
    
    # Текст в трее
    $script:ni.Text = "Pomodoro [$phase]: $displayTime"
    # Заголовок окна
    $host.UI.RawUI.WindowTitle = "[$displayTime] - $phase"
    # Текст в консоли
    $color = if ($script:isWorking) { "Cyan" } else { "Green" }
    Write-Host "`r>>> Текущая фаза: $phase | Осталось: $displayTime    " -NoNewline -ForegroundColor $color
})

# Настройка иконки
$script:ni.Icon = [System.Drawing.SystemIcons]::Information
$script:ni.Visible = $true

# Меню
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$btnStart = New-Object System.Windows.Forms.ToolStripMenuItem("Старт / Пауза")
$btnReset = New-Object System.Windows.Forms.ToolStripMenuItem("Сбросить на начало работы")
$btnExit = New-Object System.Windows.Forms.ToolStripMenuItem("Выход")

$btnStart.add_Click({
    if ($script:timer.Enabled) {
        $script:timer.Stop()
        Write-Host "`n>>> ПАУЗА" -ForegroundColor Yellow
    } else {
        $script:timer.Start()
        Write-Host "`n>>> ТАЙМЕР ЗАПУЩЕН" -ForegroundColor Green
    }
})

$btnReset.add_Click({
    $script:timer.Stop()
    $script:isWorking = $true
    $script:timeLeft = $workTime * 60
    Write-Host "`n>>> СБРОС К НАЧАЛУ РАБОТЫ" -ForegroundColor Gray
})

$btnExit.add_Click({
    $script:ni.Visible = $false
    $script:timer.Stop()
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

[void]$menu.Items.Add($btnStart)
[void]$menu.Items.Add($btnReset)
[void]$menu.Items.Add("-")
[void]$menu.Items.Add($btnExit)
$script:ni.ContextMenuStrip = $menu

Write-Host ">>> Pomodoro запущен." -ForegroundColor White
Write-Host ">>> Режим работы: $workTime мин, Режим отдыха: $breakTime мин." -ForegroundColor Gray
Write-Host ">>> Нажмите ПРАВОЙ кнопкой на 'i' в трее -> Старт." -ForegroundColor Cyan

[System.Windows.Forms.Application]::Run()