local _, core = ...; -- Namespace

local TDBMainFrame, textArea = nil, nil

local Backbone_Browser = {
	Entries = {}
}
local auctionRunning = false
local MAX_ENTRIES = 18
local MIN_SIZE = 96
local oldEntry = 0

local sortMethod = "asc"
local currSortIndex = 0

--------------------------------------
-- Defaults
--------------------------------------

local defaults = {
	theme = {
		r = 0, 
		g = 0.8, -- 204/255
		b = 1,
		hex = "00ccff"
	}
}

--------------------------------------
-- Backbone_Browser functions
--------------------------------------

function Backbone_Browser.printd(...)
    local hex = select(4, GetThemeColor())
    local prefix = string.format("|cff%s%s|r", hex:upper(), "TDB:")
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...))
end

function Backbone_Browser.initiateRoll()
	if auctionRunning==false then --If we have a consideration running, we can't start a new one
		Backbone_Frame:Show();
	end
end

function Backbone_Browser.newEntry(name, note, rank, roll)
	local additative = 0
	if rank == "Heroic Bwner" or name == "Neema-Turalyon" or name == "Nerubian-Turalyon" or name == "Qlin-Turalyon" or name == "Decisive-Turalyon" then 
		additative = 200
	end
	if rank == "The Bwnhead" or rank == "Raid Officer" or rank == "Officer" or rank == "Legacy Bwner" or rank == "Mythic Bwner" or rank == "Social Bwner" then 
		additative = 100
	end
	local fullName = name
	if rank == "Alt" then
		fullName = name .. " (".. note .. ")"
	end
	table.insert(Backbone_Browser.Entries, {fullName, rank, roll, (roll + additative)})
	Backbone_Browser.Update()
end

function Backbone_Browser.sortTable(id)
	if currSortIndex == id then -- if we're already sorting this one
		if sortMethod == "asc" then -- then switch the order
			sortMethod = "desc"
		else
			sortMethod = "asc"
		end
	elseif id then -- if we got a valid id
		currSortIndex = id -- then initialize our sort index
		sortMethod = "asc" -- and the order we're sorting in
	end

	if (id == 1) then -- Char Name sorting (alphabetically)
		table.sort(Backbone_Browser.Entries, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and v1[1] > v2[1]
			else
				return v1 and v1[1] < v2[1]
			end
		end)
	elseif (id == 2) then -- Guild Rank sorting (numerically)
		table.sort(Backbone_Browser.Entries, function(v1, v2)
			if sortMethod == "desc" then
				return (v1 and Backbone_Browser.getGuildRankNum(v1[1]) > Backbone_Browser.getGuildRankNum(v2[1]))
			else
				return (v1 and Backbone_Browser.getGuildRankNum(v1[1]) < Backbone_Browser.getGuildRankNum(v2[1]))
			end
		end)
	elseif (id == 3) then -- Dice rolls (numerically)
		table.sort(Backbone_Browser.Entries, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and (v2 == nil or v1[3] < v2[3])
			else
				return v1 and (v2 == nil or v1[3] > v2[3])
			end
		end)
	elseif (id == 4) then -- Prio rolls (numerically)
		table.sort(Backbone_Browser.Entries, function(v1, v2)
			if sortMethod == "desc" then
				return v1 and (v2 == nil or v1[4] < v2[4])
			else
				return v1 and (v2 == nil or v1[4] > v2[4])
			end
		end)
	end
	
	Backbone_Browser.Update()
end

function Backbone_Browser.Update()
	local totalEntry = 0;
	for ci = 1, MAX_ENTRIES do -- Loop through each row
		
		local entry = Backbone_Browser.Entries[ci] -- Pull the entry row
		local frame = _G["EntryFrameEntry"..ci] -- Get the physical row frame
		if entry and frame then -- if we found both of those, GREAT!
			totalEntry = totalEntry + 1;

			frame:Show() -- Make sure we're showing the frame (since nil entries were hidden)
			_G[frame:GetName().."CharName"]:SetText(entry[1]) -- Start setting data
			_G[frame:GetName().."GuildRank"]:SetText(entry[2])
			_G[frame:GetName().."DiceRoll"]:SetText(entry[3])
			_G[frame:GetName().."PriorityRoll"]:SetText(entry[4])

		else -- IF we couldn't find the entry or frame, hide it
			frame:Hide()
		end
	end -- End loop through entries
end

function Backbone_Browser.controlLootFrameSize(totalEntry)
	local proposed = (totalEntry+2) * 24;
	local move = totalEntry - oldEntry;
	if proposed > MIN_SIZE then
		Backbone_Frame:SetHeight(410+proposed);
		EntryFrame:SetHeight(proposed);
	else
		Backbone_Frame:SetHeight(410+MIN_SIZE);
		EntryFrame:SetHeight(MIN_SIZE);
	end

	oldEntry = totalEntry;
end

function Backbone_Browser.showMainFrame()
	Backbone_Frame:Show()
end

function Backbone_Browser.validInitiator(sender)	
	if sender == "player" then
		if UnitInRaid("player") then -- If the player is in a raid
			if UnitIsGroupAssistant("player") or UnitIsGroupLeader("player") then
				return 1
			else
				return 0
			end
		end
	end
end

function Backbone_Browser.getCharInfo(index)
	local name, rank, rankIndex, level, class, zone, note,officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(index);
	local NewName = name;
	return NewName, rank, rankIndex, level, class, zone, note,officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile
end

function Backbone_Browser.getRaidCharInfo(index)
	local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(index);
	local NewName = name;
	return NewName, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML
end

function Backbone_Browser.getGuildRankNum(playerName)
	GuildRoster();
	--print(playerName)
	if playerName then
		for ci=1, GetNumGuildMembers(true) do
			local name, rank, rankIndex = Backbone_Browser.getCharInfo(ci)
			if name == playerName then
				return rankIndex
			end
		end
	end
	
	return 11
end
--------------------------------------
-- UI functions
--------------------------------------

function GetThemeColor()
	local c = defaults.theme;
	return c.r, c.g, c.b, c.hex;
end

function TDBMainFrame_OnLoad()
	Backbone_Frame.Title:ClearAllPoints();
	Backbone_Frame.Title:SetFontObject("GameFontHighlight");
	Backbone_Frame.Title:SetPoint("LEFT", Backbone_FrameTitleBG, "LEFT", 6, 1);
	Backbone_Frame.Title:SetText("TDB - Roll Tracker");	
	Backbone_Frame:Hide();

	----------- Create Table Entries -----------
	-- Creates the Table Entries
	--------------------------------------------
	local entry = CreateFrame("Button", "$parentEntry1", EntryFrame, "TDB_Entry"); -- Creates the first entry
	entry:SetID(1); -- Sets its id
	entry:SetPoint("TOPLEFT", 4, -28) --Sets its anchor
	for ci = 2, MAX_ENTRIES do --Loops through to create more rows
		local entry = CreateFrame("Button", "$parentEntry"..ci, EntryFrame, "TDB_Entry");
		entry:SetID(ci);
		entry:SetPoint("TOP", "$parentEntry"..(ci-1), "BOTTOM") -- sets the anchor to the row above
	end
end

function CloseButton_OnClick()
	Backbone_Frame:Hide()
end

function ResetButton_OnClick()
	Backbone_Browser.Entries = {}
	Backbone_Browser.Update()
	Backbone_Frame:ClearAllPoints()
end

function ColSort_OnClick(id)
	Backbone_Browser.sortTable(id)
end

--------------------------------------
-- Custom Slash Command
--------------------------------------

local function HandleSlashCommands(msg)	
	local cmd, arg = string.split(" ", msg, 2); -- Separates the command from the rest
	cmd = cmd:lower(); -- Lower case command
	
	if cmd == "show" or cmd == "start" then -- try to start a new session
		Backbone_Browser.initiateRoll()
	elseif cmd == "" then
		print(" ")
		Backbone_Browser.printd("List of slash commands:")
		Backbone_Browser.printd("|cff00cc66/tdb show|r - Shows the roll tracker")
		Backbone_Browser.printd("|cff00cc66/tdb|r - shows this help info")
		print(" ")
	end
end

--------------------------------------
-- Local functions
--------------------------------------
function Backbone_SendChatMessage(msg, chatType, language, channel)
	if string.lower(chatType) == "officer" or string.lower(chatType) == "raid" or string.lower(chatType) == "whisper" or string.lower(chatType) == "raid_warning" or string.lower(chatType) == "guild" then
		-- Send message
		SendChatMessage(msg, chatType, nil, channel);
	end
end

-- The addon will receive rolls from chat, then sort them automatically in a separate message box
-- It will assume the rank of the members based on their current guild rank and calculate loot priority based on it
-- If any overwrites are needed, this is configured in a separate tab - where the appropriate loot priority is added to the raiders

local BackboneEvents = CreateFrame("Frame");
BackboneEvents:RegisterEvent("ADDON_LOADED");
BackboneEvents:RegisterEvent("CHAT_MSG_SYSTEM");
BackboneEvents:SetScript("OnEvent", function(self, event, msg)
    if event == "ADDON_LOADED" then
		-- Register Slash Commands after addon is loaded
		SLASH_Backbone1 = "/tdb"
		SlashCmdList.Backbone = HandleSlashCommands

		if TdbOverrides == nil then
			TdbOverrides = ""
		end
	end

    -- Listen for roll event
    if event == "CHAT_MSG_SYSTEM" then
		-- Extract variables from the message
		local author, rollResult, rollMin, rollMax = string.match(msg, "(.+) rolls (%d+) %((%d+)-(%d+)%)")
		-- Check if legal roll
		if rollMin == "1" and rollMax == "100" then
			-- Loop through online guild members
			for i = 1, GetNumGuildMembers() do
				-- Extract the values we need
				local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
				-- If the person that rolled is the current guildie, remove realm name
				local guildie = strsub(name, 0, (strfind(name, "-")-1))
				if guildie == author then
					-- Send message to the UI Window
					Backbone_Browser.newEntry(name, note, rank, rollResult)
					break
				end
			end
		end
    end
end)