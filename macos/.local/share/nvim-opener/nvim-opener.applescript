on open theFiles
	set fileArgs to {}
	repeat with f in theFiles
		set end of fileArgs to quoted form of POSIX path of f
	end repeat
	set AppleScript's text item delimiters to " "
	set argsStr to fileArgs as text
	set AppleScript's text item delimiters to ""

	-- Write file paths into a temp script so they don't appear in Ghostty's argv,
	-- which would cause Ghostty to try running them as shell commands.
	set tmpScript to do shell script "mktemp /tmp/nvim-opener-XXXXXX"
	do shell script "printf '#!/bin/sh\\nexec /opt/homebrew/bin/nvim " & argsStr & "' > " & quoted form of tmpScript & " && chmod +x " & quoted form of tmpScript
	do shell script "open -na Ghostty.app --args -e " & quoted form of tmpScript
end open
