local addon_name, Addon = ...
local Core = Addon.addon
local Update = Core:NewModule("Update")
Core.Update = Update
Update.addon_name = Core.addon_name

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

--Embed AceComm
LibStub:GetLibrary("AceComm-3.0"):Embed(Update)



local _,i,j,k,v

function Update:OnInitialize()
	self.db = Core.db.global.update
	if GetCurrentRegion() ~= 5 then
		self.disable = true
	elseif UnitFactionGroup("player") == "Horde" then --部落
		self.author_sender = "陽光-死亡之翼"
		self.invite_message = "组我更新WCL数据库"
	else
		self.disable = true
	end
	self:RegisterUpdateChannels()
end

function Update:GetCurrentDate()
	return date("%y%m%d", GetServerTime() - 4 * 3600)	--update at 4:00 am
end

-- function Update:GetCurrentVersion(database)
-- 	local addon_name = Core.zone_to_addon[zoneID]
-- 	if addon_name then addon_version = string.match(GetAddOnMetadata(addon_name, "Version"),"%d+") end
-- end

function Update:IsUpdateNeed()
	if self.disable or Core.db.profile.update.disable then return false end

	local db_version = self.db.date
	if db_version and db_version >= self:GetCurrentDate() then return false end
	local addon_min_version = self:GetAddonMinVersion()
	if addon_min_version and addon_min_version >= self:GetCurrentDate() then return false end

	return true
end


function Update:GetAddonMinVersion()
	local addon_min_version
    for zoneID, _ in pairs(Core.zone_to_addon) do
    	local addon_version
		local addon_name = Core.zone_to_addon[zoneID]
		if addon_name then addon_version = Core:GetAddonVersion(addon_name) end
		if addon_min_version and addon_version then 
			addon_min_version = (addon_min_version > addon_version) and addon_version
		elseif not addon_min_version then 
			addon_min_version = addon_version
		end
    end
    return addon_min_version
end


function Update:RegisterUpdateChannels()
	if self.disable or Core.db.profile.update.disable then
		self:UnregisterAllComm()
		return nil 
	end
	if not self:IsUpdateNeed() then return nil end
	local prefix = self:GetUpdataPrefix()
	self:RegisterComm(prefix, self.UpdateMessageReceived)
end

function Update:GetUpdataPrefix()
	local prefix = "WCLPUR" --WCLP, Update, Raid
	prefix = prefix .. self:GetCurrentDate()
	return prefix
end

function Update.UpdateMessageReceived(prefix, message, distribution, sender)
	local self = Update
	if self:SenderFullname(sender) ~= self.author_sender then return nil end
	if message == "START_UPDATE" then
		print("开始更新WCL数据库，数据传输中，预计2-3分钟完成")
		return nil
	end
    local decoded_string = LibDeflate:DecodeForWoWAddonChannel(message)
    local decompressed_string = LibDeflate:DecompressDeflate(decoded_string)
    local success,message_data =  AceSerializer:Deserialize(decompressed_string)
    if not success or type(message_data) ~= "table" then 
        return nil 
    end
    wipe(self.db)
    self.db.data = message_data.data
    self.db.date = message_data.date
    for zoneID, _ in pairs(Core.zone_to_addon) do
        Core:ZoneDBRefresh(zoneID)
    end
    print("WCL数据库更新完成，版本："..message_data.date)
    -- self:SendCommMessage("WCLPUR", "COMPLETE", distribution, sender)
    C_PartyInfo.LeaveParty()
    self:UnregisterAllComm()
end

function Update:SenderFullname(sender)
	if select(2,strsplit('-', sender)) then 
		return sender
	else
		return sender .. '-' .. GetNormalizedRealmName()
	end
end

-- local tracker = CreateFrame("Frame")
-- tracker:RegisterEvent("PLAYER_ENTERING_WORLD")
-- tracker:SetScript("OnEvent", function(self, event, addon_name)
-- 	Update:RegisterUpdateChannels()
-- end)
-- Update.tracker = trakcer