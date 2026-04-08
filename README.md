[EN]

# Who said PowerShell is only for CLI? 🚀

I just built a lightweight Pomodoro Timer that lives in the Windows System Tray—using 100% pure PowerShell. No external dependencies, no heavy frameworks, and all in under 100 lines of code.
It was a fun weekend project to explore how PowerShell interacts with the .NET Framework to create native GUI tools.
Key Features:
🔹 System Tray Integration: Runs in the background with a persistent icon.
🔹 Live Updates: Displays the countdown in the window title and tray tooltip.
🔹 Native Notifications: Uses Windows balloon tips to signal phase changes.
🔹 Context Menu: Fully functional "Start/Pause/Reset" menu via right-click.
Why PowerShell?
It’s a great example of how powerful scripting can be for creating small, personal productivity tools. No need to install third-party apps when you can build a custom solution that fits your exact workflow.
I've written a step-by-step breakdown of how the NotifyIcon and Timer objects work together to make this happen.
👇 Check out the full article and the code here:

[LINK TO ARTICLE]