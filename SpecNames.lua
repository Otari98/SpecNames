local _G = _G or getfenv(0)
SN_PLAYER_SPECS = SN_PLAYER_SPECS or {}

local resetCost = nil
local selectedGossip = nil
local selectedSpecIndex = nil
local specToRename = nil
local specToRenameIndex = nil
local BLUE = "|cff0070de"
local WHITE = HIGHLIGHT_FONT_COLOR_CODE

local function strtrim(s)
    return (string.gsub(s or "", "^%s*(.-)%s*$", "%1"))
end

local f = CreateFrame("Frame", "SpecNamesFrame")
f:RegisterEvent("GOSSIP_CLOSED")
f:SetScript("OnEvent", function()
    selectedGossip = nil
    selectedSpecIndex = nil
	resetCost = nil
	StaticPopup_Hide("SPECNAMES_CONFIRM_TALENT_WIPE")
	StaticPopup_Hide("SPECNAMES_NEW")
end)

local old_GossipTitleButton_OnClick = GossipTitleButton_OnClick
function GossipTitleButton_OnClick()
    local text = this:GetText()
    _, _, selectedSpecIndex = strfind(text, "Save (%d).. Specialization.")
	_, _, resetCost = strfind(text, "^Reset my talents.%s*%((%d*g?%d*s?%d*c?)%)")
    if selectedSpecIndex then
        selectedGossip = this:GetID()
        selectedSpecIndex = tonumber(selectedSpecIndex)
        StaticPopup_Show("SPECNAMES_NEW")
        return
	elseif resetCost then
		local _, _, gold = strfind(resetCost, "(%d*)g")
		local _, _, silver = strfind(resetCost, "(%d*)s")
		local _, _, copper = strfind(resetCost, "(%d*)c")
		if copper then
			resetCost = tonumber(copper)
			if silver then
				resetCost = tonumber(silver * 100) + resetCost
				if gold then
					resetCost = tonumber(gold) * 10000 + resetCost
				end
			end
			selectedGossip = this:GetID()
			StaticPopup_Show("SPECNAMES_CONFIRM_TALENT_WIPE")
		end
    else
        return old_GossipTitleButton_OnClick()
    end
end

local old_GossipFrameOptionsUpdate = GossipFrameOptionsUpdate
function GossipFrameOptionsUpdate(...)
    old_GossipFrameOptionsUpdate(unpack(arg))
    for i = 1, NUMGOSSIPBUTTONS do
        local titleButton = _G["GossipTitleButton" .. i]
		local text = titleButton:GetText()
        local _, _, specIndex = strfind(text or "", "^Activate (%d)%a* Specialization")
        if specIndex then
            specIndex = tonumber(specIndex)
            if SN_PLAYER_SPECS[specIndex] then
                titleButton:SetText(text.."\n("..SN_PLAYER_SPECS[specIndex]..")")
				GossipResize(titleButton)
            end
        end
    end
end

SLASH_SPECNAMES1 = "/specnames"
SLASH_SPECNAMES2 = "/sn"
SlashCmdList["SPECNAMES"] = function(msg)
    SpecNames_SlashCommand(msg)
end

function SpecNames_SlashCommand(msg)
    strtrim(msg)
    if msg == "" then
        local version = GetAddOnMetadata("SpecNames", "Version")
        DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE.."Version "..version..FONT_COLOR_CODE_CLOSE)
        if next(SN_PLAYER_SPECS) then
            DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE.."Your saved specialization names are:"..FONT_COLOR_CODE_CLOSE)
        else
            DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE.."Your don't have any specialization names yet. Save one spec inside Brainwashing device."..FONT_COLOR_CODE_CLOSE)
            return
        end
        for i in pairs(SN_PLAYER_SPECS) do
            DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE..'['..i..'] = "'..SN_PLAYER_SPECS[i]..'"'..FONT_COLOR_CODE_CLOSE)
        end
        DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE.."Type '/specnames rename' or '/sn rename' followed by spec number to rename it."..FONT_COLOR_CODE_CLOSE)
        DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE.."Type '/specnames delete' or '/sn delete' followed by spec number to delete it."..FONT_COLOR_CODE_CLOSE)
    elseif strfind(strlower(msg), "rename [1-4]") then
        _,_, specToRenameIndex = strfind(strlower(msg), "rename (%d)")
        specToRenameIndex = tonumber(specToRenameIndex)
        specToRename = SN_PLAYER_SPECS[specToRenameIndex]
        if not specToRename then
            if specToRenameIndex == 1 then
                specToRename = "1st Specialization"
            elseif specToRenameIndex == 2 then
                specToRename = "2nd Specialization"
            elseif specToRenameIndex == 3 then
                specToRename = "3rd Specialization"
            elseif specToRenameIndex == 4 then
                specToRename = "4th Specialization"
            end
            SN_PLAYER_SPECS[specToRenameIndex] = specToRename
        end
        StaticPopup_Show("SPECNAMES_RENAME")
    elseif strfind(strlower(msg), "delete [1-4]") then
        local _,_, index = strfind(strlower(msg), "delete (%d)")
        if SN_PLAYER_SPECS[tonumber(index)] then
            DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE..SN_PLAYER_SPECS[tonumber(index)].." deleted successfully."..FONT_COLOR_CODE_CLOSE)
            SN_PLAYER_SPECS[tonumber(index)] = nil
        end
    end
end

StaticPopupDialogs["SPECNAMES_NEW"] = {
    text = "Enter Specialization Name:",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = 1,
    OnShow = function()
        _G[this:GetName().."EditBox"]:SetFocus()
        _G[this:GetName() .. "EditBox"]:SetScript("OnEnterPressed", function()
            StaticPopup1Button1:Click()
        end)
        _G[this:GetName() .. "EditBox"]:SetScript("OnEscapePressed", function()
            _G[this:GetParent():GetName() .. "EditBox"]:SetText("")
            StaticPopup1Button2:Click()
        end)
    end,
    OnAccept = function()
        local box = _G[this:GetParent():GetName() .. "EditBox"]
        local text = strtrim(box:GetText())
        if selectedSpecIndex and text ~= "" then
            SN_PLAYER_SPECS[selectedSpecIndex] = text
            SelectGossipOption(selectedGossip)
            box:SetText("")
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["SPECNAMES_RENAME"] = {
    text = "",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = 1,
    OnShow = function()
        if not specToRename then
            this:Hide()
            return
        end
        _G[this:GetName() .. "Text"]:SetText("Rename " .. specToRename .. " into:")
        _G[this:GetName().."EditBox"]:SetFocus()
        _G[this:GetName() .. "EditBox"]:SetScript("OnEnterPressed", function()
            StaticPopup1Button1:Click()
        end)
        _G[this:GetName() .. "EditBox"]:SetScript("OnEscapePressed", function()
            _G[this:GetParent():GetName() .. "EditBox"]:SetText("")
            StaticPopup1Button2:Click()
        end)
    end,
    OnAccept = function()
        local box = _G[this:GetParent():GetName() .. "EditBox"]
        local text = strtrim(box:GetText())
        if specToRenameIndex and text ~= "" then
            SN_PLAYER_SPECS[tonumber(specToRenameIndex)] = text
            DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[SpecNames]"..WHITE.."Renamed "..specToRename.." into "..text.. " successfully."..FONT_COLOR_CODE_CLOSE)
            box:SetText("")
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["SPECNAMES_CONFIRM_TALENT_WIPE"] = {
	text = CONFIRM_TALENT_WIPE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		SelectGossipOption(selectedGossip);
	end,
	OnShow = function()
		MoneyFrame_Update(this:GetName().."MoneyFrame", resetCost or 0)
    end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};