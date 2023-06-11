script_name('Dual Monitor Fix')
script_author('Albertio')
script_version('1.0')

require('lib.moonloader')
local ffi = require('ffi')
local wm  = require('lib.windows.message')

ffi.cdef [[
	typedef unsigned long HANDLE;
	typedef HANDLE HWND;
	typedef struct _RECT {
		long left;
		long top;
		long right;
		long bottom;
	} RECT, *PRECT;

	HWND GetActiveWindow(void);

	bool GetWindowRect(
		HWND   hWnd,
		PRECT lpRect
	);

	bool ClipCursor(
		const RECT *lpRect
	);

	bool GetClipCursor(
		PRECT lpRect
	);
]]

local rcClip, rcOldClip = ffi.new('RECT', {left, top, right, bottom})

function main()
  ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
  ffi.C.ClipCursor(rcClip);
  while true do
    wait(0)
  end
end

function onWindowMessage(msg, wparam, lparam)
  if msg == wm.WM_KILLFOCUS then
		ffi.C.GetClipCursor(rcOldClip);
		ffi.C.ClipCursor(rcOldClip);
	elseif msg == wm.WM_SETFOCUS then
		ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
		ffi.C.ClipCursor(rcClip);
	end
end
