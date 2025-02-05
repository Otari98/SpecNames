SN_PLAYER_SPECS = SN_PLAYER_SPECS or {}

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
end)

function GossipTitleButton_OnClick()
    local text = this:GetText()
    _, _, selectedSpecIndex = strfind(text, "Save (%d).. Specialization.")
    if selectedSpecIndex then
        selectedGossip = this:GetID()
        selectedSpecIndex = tonumber(selectedSpecIndex)
        StaticPopup_Show("SPECNAMES_NEW")
        return
    end
    if ( this.type == "Available" ) then
		SelectGossipAvailableQuest(this:GetID());
	elseif ( this.type == "Active" ) then
		SelectGossipActiveQuest(this:GetID());
	else
		SelectGossipOption(this:GetID());
	end
end

function GossipFrameOptionsUpdate(...)
	local titleButton;
	local titleIndex = 1;
	for i=1, arg.n, 2 do
		if ( GossipFrame.buttonIndex > NUMGOSSIPBUTTONS ) then
			message("This NPC has too many quests and/or gossip options.");
		end
		titleButton = getglobal("GossipTitleButton" .. GossipFrame.buttonIndex);
		titleButton:SetText(arg[i]);
        local _, _, specIndex = strfind(arg[i], "Activate (%d).. Specialization %(%d+/%d+/%d+%)")
        if specIndex then
            specIndex = tonumber(specIndex)
            if SN_PLAYER_SPECS[specIndex] then
                titleButton:SetText(arg[i].." ("..SN_PLAYER_SPECS[specIndex]..")")
            end
        end
		GossipResize(titleButton);
		titleButton:SetID(titleIndex);
		titleButton.type="Gossip";
		getglobal(titleButton:GetName() .. "GossipIcon"):SetTexture("Interface\\GossipFrame\\" .. arg[i+1] .. "GossipIcon");
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
		titleIndex = titleIndex + 1;
		titleButton:Show();
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
        specToRename = SN_PLAYER_SPECS[tonumber(specToRenameIndex)]
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
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = 1,
    OnShow = function()
        getglobal(this:GetName().."EditBox"):SetFocus()
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEnterPressed", function()
            StaticPopup1Button1:Click()
        end)
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEscapePressed", function()
            getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
            StaticPopup1Button2:Click()
        end)
    end,
    OnAccept = function()
        local box = getglobal(this:GetParent():GetName() .. "EditBox")
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
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = 1,
    OnShow = function()
        if not specToRename then
            this:Hide()
            return
        end
        getglobal(this:GetName() .. "Text"):SetText("Rename " .. specToRename .. " into:")
        getglobal(this:GetName().."EditBox"):SetFocus()
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEnterPressed", function()
            StaticPopup1Button1:Click()
        end)
        getglobal(this:GetName() .. "EditBox"):SetScript("OnEscapePressed", function()
            getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
            StaticPopup1Button2:Click()
        end)
    end,
    OnAccept = function()
        local box = getglobal(this:GetParent():GetName() .. "EditBox")
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