
local inicfg = require "inicfg"
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local memory = require "memory"

------------ [cfg] -----------------
local directIni = "RECOLORERv2.ini"
local ini = inicfg.load(inicfg.load({
    HEALTH = {
        R = "255",
        G = "2.3",
        B = "2.3",
    },
    ARMOUR = {
        R = "214.8",
        G = "214.8",
        B = "214.8",
    },
    PLAYERHEALTH = {
        R = "255",
        G = "0",
        B = "0",
        HP1 = "0xFFFF0000",
        HP2 = "2",
    },
    PLAYERHEALTH2 = {
        R = "50",
        G = "50",
        B = "50",
    },
    MONEY = {
        R = "0",
        G = "129.8",
        B = "10.8",
    },
    STARS = {
        R = "255",
        G = "189.3",
        B = "86.1",
    },
    PATRONS = {
        R = "187.0",
        G = "210.0",
        B = "222.0",
    },
}, directIni))
inicfg.save(ini, directIni)


function save()
    inicfg.save(ini, directIni)
end
---------------------------------------

----------------------- color edit -----------------
local color_money = imgui.ImFloat3(ini.MONEY.R/255, ini.MONEY.G/255, ini.MONEY.B/255)
local color_health = imgui.ImFloat3(ini.HEALTH.R/255, ini.HEALTH.G/255, ini.HEALTH.B/255)
local color_stars = imgui.ImFloat3(ini.STARS.R/255, ini.STARS.G/255, ini.STARS.B/255)
local color_patron = imgui.ImFloat3(ini.PATRONS.R/255, ini.PATRONS.G/255, ini.PATRONS.B/255)
local color_armour = imgui.ImFloat3(ini.ARMOUR.R/255, ini.ARMOUR.G/255, ini.ARMOUR.B/255)
local color_phealth = imgui.ImFloat3(ini.PLAYERHEALTH.R/255, ini.PLAYERHEALTH.G/255, ini.PLAYERHEALTH.B/255)
local color_phealth2 = imgui.ImFloat3(ini.PLAYERHEALTH2.R/255, ini.PLAYERHEALTH2.G/255, ini.PLAYERHEALTH2.B/255)
-----------------------------------------------------

local sw, sh = getScreenResolution()

local main_menu = imgui.ImBool(false)

function main()
	repeat wait(100) until isSampAvailable()
    sampAddChatMessage("[RECOLORER] {FFFFFF}by Gorskin loaded! use cmd: {FFDEAD}/recolorer", 0xFFDEAD)
	sampRegisterChatCommand("recolorer", cmd_imgui)
    memory.write(0xBAB230, ("0xFF%06X"):format(join_argb(0, color_money.v[1] * 255, color_money.v[2] * 255, color_money.v[3] * 255)), 4, false)
    memory.write(0xBAB22C, ("0xFF%06X"):format(join_argb(0, color_health.v[1] * 255, color_health.v[2] * 255, color_health.v[3] * 255)), 4, false)
    memory.write(0xBAB244, ("0xFF%06X"):format(join_argb(0, color_stars.v[1] * 255, color_stars.v[2] * 255, color_stars.v[3] * 255)), 4, false)
    memory.write(0xBAB23C, ("0xFF%06X"):format(join_argb(0, color_armour.v[1] * 255, color_armour.v[2] * 255, color_armour.v[3] * 255)), 4, false)
    memory.write(0xBAB238, ("0xFF%06X"):format(join_argb(0, color_patron.v[1] * 255, color_patron.v[2] * 255, color_patron.v[3] * 255)), 4, false)
    setHealthColor(ini.PLAYERHEALTH.HP1, ini.PLAYERHEALTH.HP2)
    wait(-1)
end

function cmd_imgui()
	main_menu.v = not main_menu.v
	imgui.Process = main_menu.v
end

function setHealthColor(hpHigh, hpLow)
    local samp = getModuleHandle("samp.dll")
    memory.setuint32(samp + 0x68B0C, ini.PLAYERHEALTH.HP1, true) -- полная полоска хп
    memory.setuint32(samp + 0x68B33, ini.PLAYERHEALTH.HP2, true) -- задний фон
end

function join_argb(a, b, g, r)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.OnDrawFrame()
    if not main_menu.v then
		imgui.Process = false
	end
    if main_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(290, 290), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8"RECOLORER", main_menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
                imgui.CenterTextColoredRGB("{008000}HUD")
                imgui.Separator()
                imgui.Text(u8"Деньги:")
                imgui.SameLine()
                imgui.SetCursorPosX(255)
                if imgui.ColorEdit3('##money', color_money, imgui.ColorEditFlags.NoInputs) then
                    local clr = join_argb(0, color_money.v[1] * 255, color_money.v[2] * 255, color_money.v[3] * 255)
                    local r, g, b = color_money.v[1] * 255, color_money.v[2] * 255, color_money.v[3] * 255
                    ini.MONEY.R = r
                    ini.MONEY.G = g
                    ini.MONEY.B = b
                    save()
                    memory.write(0xBAB230, ("0xFF%06X"):format(join_argb(0, color_money.v[1] * 255, color_money.v[2] * 255, color_money.v[3] * 255)), 4, false)
                end
                imgui.Text(u8"ХП:")
                imgui.SameLine()
                imgui.SetCursorPosX(255)
                if imgui.ColorEdit3('##health', color_health, imgui.ColorEditFlags.NoInputs) then
                    local clr = join_argb(0, color_health.v[1] * 255, color_health.v[2] * 255, color_health.v[3] * 255)
                    local r, g, b = color_health.v[1] * 255, color_health.v[2] * 255, color_health.v[3] * 255
                    ini.HEALTH.R = r
                    ini.HEALTH.G = g
                    ini.HEALTH.B = b
                    save()
                    memory.write(0xBAB22C, ("0xFF%06X"):format(join_argb(0, color_health.v[1] * 255, color_health.v[2] * 255, color_health.v[3] * 255)), 4, false)
                end
                imgui.Text(u8"Звёзды:")
                imgui.SameLine()
                imgui.SetCursorPosX(255)
                if imgui.ColorEdit3('##stars', color_stars, imgui.ColorEditFlags.NoInputs) then
                    local clr = join_argb(0, color_stars.v[1] * 255, color_stars.v[2] * 255, color_stars.v[3] * 255)
                    local r, g, b = color_stars.v[1] * 255, color_stars.v[2] * 255, color_stars.v[3] * 255
                    ini.STARS.R = r
                    ini.STARS.G = g
                    ini.STARS.B = b
                    save()
                    memory.write(0xBAB244, ("0xFF%06X"):format(join_argb(0, color_stars.v[1] * 255, color_stars.v[2] * 255, color_stars.v[3] * 255)), 4, false)
                end
                imgui.Text(u8"Патроны, заголовок меню и кислород:")
                imgui.SameLine()
                imgui.SetCursorPosX(255)
                if imgui.ColorEdit3('##patron', color_patron, imgui.ColorEditFlags.NoInputs) then
                    local clr = join_argb(0, color_patron.v[1] * 255, color_patron.v[2] * 255, color_patron.v[3] * 255)
                    local r, g, b = color_patron.v[1] * 255, color_patron.v[2] * 255, color_patron.v[3] * 255
                    ini.PATRONS.R = r
                    ini.PATRONS.G = g
                    ini.PATRONS.B = b
                    save()
                    memory.write(0xBAB238, ("0xFF%06X"):format(join_argb(0, color_patron.v[1] * 255, color_patron.v[2] * 255, color_patron.v[3] * 255)), 4, false)
                end
                imgui.Text(u8"Броня:")
                imgui.SameLine()
                imgui.SetCursorPosX(255)
                if imgui.ColorEdit3('##armour', color_armour, imgui.ColorEditFlags.NoInputs) then
                    local clr = join_argb(0, color_armour.v[1] * 255, color_armour.v[2] * 255, color_armour.v[3] * 255)
                    local r, g, b = color_armour.v[1] * 255, color_armour.v[2] * 255, color_armour.v[3] * 255
                    ini.ARMOUR.R = r
                    ini.ARMOUR.G = g
                    ini.ARMOUR.B = b
                    save()
                    memory.write(0xBAB23C, ("0xFF%06X"):format(join_argb(0, color_armour.v[1] * 255, color_armour.v[2] * 255, color_armour.v[3] * 255)), 4, false)
                end
                imgui.CenterTextColoredRGB("{008000}SA-MP")
                imgui.Separator()
                imgui.CenterTextColoredRGB("ХП игроков")
                imgui.Text(u8"Передний фон:")
                imgui.SameLine()
                imgui.SetCursorPosX(255)
                if imgui.ColorEdit3('##hpHigh', color_phealth, imgui.ColorEditFlags.NoInputs) then
                    local clr = join_argb(0, color_phealth.v[3] * 255, color_phealth.v[2] * 255, color_phealth.v[1] * 255)
                    local r, g, b = color_phealth.v[1] * 255, color_phealth.v[2] * 255, color_phealth.v[3] * 255
                    ini.PLAYERHEALTH.R = r
                    ini.PLAYERHEALTH.G = g
                    ini.PLAYERHEALTH.B = b
                    ini.PLAYERHEALTH.HP1 = ("0xFF%06X"):format(clr)
                    save()
                    setHealthColor(ini.PLAYERHEALTH2.HP1, ini.PLAYERHEALTH2.HP2)
                end
                imgui.Text(u8"Задний фон:")
                imgui.SameLine()
                imgui.SetCursorPosX(255)
                if imgui.ColorEdit3('##hpLow', color_phealth2, imgui.ColorEditFlags.NoInputs) then
                    local clr = join_argb(0, color_phealth2.v[3] * 255, color_phealth2.v[2] * 255, color_phealth2.v[1] * 255)
                    local r, g, b = color_phealth2.v[1] * 255, color_phealth2.v[2] * 255, color_phealth2.v[3] * 255
                    ini.PLAYERHEALTH2.R = r
                    ini.PLAYERHEALTH2.G = g
                    ini.PLAYERHEALTH2.B = b
                    ini.PLAYERHEALTH.HP2 = ("0xFF%06X"):format(clr)
                    save()
                    setHealthColor(ini.PLAYERHEALTH2.HP1, ini.PLAYERHEALTH2.HP2)
                end
		imgui.End()
	end
end


--------------------------
function purple_style()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4

	style.WindowRounding = 10
	style.ChildWindowRounding = 10
	style.FrameRounding = 6.0
	style.ItemSpacing = imgui.ImVec2(9.0, 3.0)
	style.ItemInnerSpacing = imgui.ImVec2(3.0, 3.0)
	style.IndentSpacing = 21
	style.ScrollbarSize = 10.0
	style.ScrollbarRounding = 13
	style.GrabMinSize = 17.0
	style.GrabRounding = 16.0

	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.FrameBg]                = ImVec4(0.46, 0.11, 0.29, 1.00)
	colors[clr.FrameBgHovered]         = ImVec4(0.69, 0.16, 0.43, 1.00)
	colors[clr.FrameBgActive]          = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.61, 0.16, 0.39, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.94, 0.30, 0.63, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.85, 0.11, 0.49, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.89, 0.24, 0.58, 1.00)
	colors[clr.Button]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
	colors[clr.ButtonHovered]          = ImVec4(0.69, 0.17, 0.43, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.59, 0.10, 0.35, 1.00)
	colors[clr.Header]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
	colors[clr.HeaderHovered]          = ImVec4(0.69, 0.16, 0.43, 1.00)
	colors[clr.HeaderActive]           = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.Separator]              = ImVec4(0.69, 0.16, 0.43, 1.00)
	colors[clr.SeparatorHovered]       = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.SeparatorActive]        = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.46, 0.11, 0.29, 0.70)
	colors[clr.ResizeGripHovered]      = ImVec4(0.69, 0.16, 0.43, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.70, 0.13, 0.42, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.78, 0.90, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.60, 0.19, 0.40, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]                 = ImVec4(0.49, 0.14, 0.31, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.49, 0.14, 0.31, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.15, 0.15, 0.15, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CloseButton]            = ImVec4(0.20, 0.20, 0.20, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end
purple_style()