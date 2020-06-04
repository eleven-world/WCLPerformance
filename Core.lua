local addon_name, Addon = ...

WCLPerf = LibStub("AceAddon-3.0"):NewAddon("WCLPerformance")
Addon.addon = WCLPerf
local Core = WCLPerf
Core.addon_name = "WCLPerformance"
Core.title = GetAddOnMetadata(Core.addon_name, "Title")
Core.version = GetAddOnMetadata(Core.addon_name, "Version")


local function _secure_call (...)
	local success, result, result2 = pcall(...)
	if success then return result 
	-- else print(result,result2) 
	end
end


function Core:LoadDB()
	if WCLPerf_Database then
		self.db = WCLPerf_Database
	end
	return self.db
end

Core.zone_to_addon = {
	[24] = "WCLPerformance_Database_Nyalotha",
}

Core.addon_to_zone = {
	["WCLPerformance_Database_Nyalotha"] = {24},
}

Core.encounter_to_zone = {
	[2329] = 24, 
	[2327] = 24, 
	[2334] = 24, 
	[2328] = 24, 
	[2333] = 24, 
	[2335] = 24, 
	[2343] = 24, 
	[2336] = 24, 
	[2331] = 24, 
	[2345] = 24, 
	[2337] = 24, 
	[2344] = 24,
}


function Core:GetPerf_Raw(player_amount, metric, encounter, difficulty, class_id, spec)
	local player_amount = player_amount * 100
	local percentiles = {100,99,95,90,80,75,70,60,50,40,30,25,20,10,0}
	local zoneID = self.encounter_to_zone[encounter]
	local db = self:GetZoneDB(zoneID)
	if not db then return nil end
	local up, down, up_amount, down_amount
	for _,percentile in ipairs(percentiles) do
		amount = self:GetPercentileAmount(percentile, metric, encounter, difficulty, class_id, spec)
		if amount then
			if player_amount > amount then
				down = percentile
				down_amount = amount
				break
			else
				up = percentile
				up_amount = amount
			end
		-- else
		-- 	print("no amount", percentile, metric, encounter, difficulty, class_id, spec)
		end
	end

	if not up then 
		return 100
	elseif not down then 
		return up 
	else
		return math.floor(up - (up_amount - player_amount) / (up_amount - down_amount) * (up - down) + 0.5) 
	end
end

function Core:GetZoneDB(zoneID)
	if not zoneID then return nil end
	local addon_name = Core.zone_to_addon[zoneID]
	if IsAddOnLoaded(addon_name) then
		return WCLPerf_Database and WCLPerf_Database[zoneID]
	elseif select(5,GetAddOnInfo(addon_name)) ~= "MISSING" then
		LoadAddOn(addon_name)
	end
end

function Core:GetPercentileAmount(percentile, metric, encounter, difficulty, class_id, spec)
	local zoneID = self.encounter_to_zone[encounter]
	local db = self:GetZoneDB(zoneID)
	if not db then return nil end
	if zoneID == 24 then	--maybe different structure for other raids
		local found, amount = pcall(function () return db.data[metric][encounter][difficulty][percentile][class_id][spec][1] end)
		if found then return amount else return nil end
	end
end



function Core:GetPerf(...)
	return _secure_call(self.GetPerf_Raw, self, ...)
end

function Core:GetDatebaseVersion()
	for date,_ in pairs(WCLPerf_Database) do
		return date
	end
end

function Core:PerfColor(perf)
	if perf >= 99 then return ITEM_QUALITY_COLORS[6].hex --Artifact
	elseif perf >= 90 then return ITEM_QUALITY_COLORS[5].hex --Legendary
	elseif perf >= 75 then return ITEM_QUALITY_COLORS[4].hex --Epic
	elseif perf >= 50 then return ITEM_QUALITY_COLORS[3].hex --Rare
	elseif perf >= 25 then return ITEM_QUALITY_COLORS[2].hex --Uncommon
	else return	ITEM_QUALITY_COLORS[0].hex --Poor
	end
end

function Core:GetColoredPerf(...)
	local perf = self:GetPerf(...)
	if perf then return self:PerfColor(perf) .. perf .. '|r' end
end

Core.class_id_list = {
		WARRIOR = 1,
		PALADIN = 2,
		HUNTER = 3, 
		ROGUE = 4, 
		PRIEST = 5, 
		DEATHKNIGHT = 6, 
		SHAMAN = 7, 
		MAGE = 8, 
		WARLOCK = 9, 
		MONK = 10, 
		DRUID = 11, 
		DEMONHUNTER = 12
}

function Core:ClassFileToID(classFile)
	return self.class_id_list[classFile] or 0
end

function Core:DetailsText_Raw(...)
	local player, combat, instance = ...; 
    local player_amount, metric, encounter, difficulty, class, spec
    if not player:IsGroupPlayer() then return "" end
    if instance.atributo and instance.atributo == 1 and instance.sub_atributo and (instance.sub_atributo == 1 or instance.sub_atributo == 2) then  --dps
        metric = 'dps'
        player_amount = math.floor(player.last_dps)
    elseif instance.atributo and instance.atributo == 2 and instance.sub_atributo and (instance.sub_atributo == 1 or instance.sub_atributo == 2) then  --hps
        metric = 'hps'
        player_amount = math.floor(player.last_hps)
    else
        return ""
    end
    if combat.is_boss then
        encounter = combat.is_boss.id
        difficulty = combat.is_boss.diff
    else
        return ""
    end
    local guid = player:guid() or playe.serial
    class = player:class()
    local class_id = self:ClassFileToID(class)
    spec = player.spec or Details:GetSpec(guid)
    if not (class and spec) then return "" end
    -- encounter = 2333
    -- difficulty = 5
    -- print("DetailsText_Raw", player_amount, metric, encounter, difficulty, class_id, spec)
    local text 
    local setting = self.db.profile.details
    if setting.color then
    	text = self:GetColoredPerf(player_amount, metric, encounter, difficulty, class_id, spec)
    else
    	text = self:GetPerf(player_amount, metric, encounter, difficulty, class_id, spec)
    end
    if setting.bracket then
    	text = text and '[' .. text .. ']'
    end
    return text or ""
end

function Core:DetailsText(...)
	return _secure_call(self.DetailsText_Raw, self, ...) or ""
end

-- local frame = CreateFrame("Frame")
-- frame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- frame:RegisterEvent("ENCOUNTER_START")
-- frame:SetScript("OnEvent", function(self, event, addon_name)
-- 	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
-- 	if Details then Details:TrackSpecsNow (true) end
-- end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon_name)
	if event == "ADDON_LOADED" then
		local zones = Core.addon_to_zone[addon_name]
		if zones then
			Core:CheckDataBaseUpdate(addon_name)
		end
	end
end)

function Core:CheckDataBaseUpdate(addon_name)
	local server_time = GetServerTime()
	local reminder_time = tonumber(GetAddOnMetadata(addon_name, "X-Update-Date-Reminder"))
	if reminder_time and reminder_time < server_time then
		local update_time = date("%Y-%m-%d %H:%M:%S", tonumber(GetAddOnMetadata(addon_name, "X-Update-Date")))
		print(string.format("%s数据库更新时间：%s, 建议进行更新！", addon_name, update_time))
	end
end
