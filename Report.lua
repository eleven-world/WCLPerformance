local addon_name, Addon = ...
local Core = Addon.addon
local Report = Core:NewModule("Report")
Core.Report = Report
Report.addon_name = Core.addon_name

-- local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local _,i,j,k,v

function Report:OnInitialize()
	self.db = Core.db.profile.report
end


function Report:GenerateReport(combat, db)
	--check db available
	local difficulty = combat:GetDifficulty()
	--difficulty = 16
	local bossInfo = combat:GetBossInfo()
		--table members: name, zone, mapid, diff, diff_string, id, ej_instance_id, killed, index@
	local encounter = bossInfo.id
	local found, data = pcall(function () return db.data['dps'][encounter][difficulty] or db.data['hps'][encounter][difficulty] end)
	if not (found and data) then return nil end
		
	--generate dps
	local report_dps = {}
	--dps DETAILS_ATTRIBUTE_DAMAGE DETAILS_SUBATTRIBUTE_DPS
	local actorContainer = combat:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
	actorContainer:SortByKey("total")
	local metric = 'dps'
	for _, player in actorContainer:ListActors() do
	    if (player:IsPlayer()) then
	    	local player_report = self:GenerateReport_Player(player, combat, metric)
	    	if player_report then tinsert(report_dps, player_report) end
	    end
	end
	--generate hps
	local report_hps = {}
	--hps DETAILS_ATTRIBUTE_HEAL DETAILS_SUBATTRIBUTE_HPS
	actorContainer = combat:GetContainer(DETAILS_ATTRIBUTE_HEAL)
	actorContainer:SortByKey("total")
	metric = 'hps'
	for _, player in actorContainer:ListActors() do
	    if (player:IsPlayer()) then
	    	local player_report = self:GenerateReport_Player(player, combat, metric)
	    	if player_report then tinsert(report_hps, player_report) end
	    end
	end

	if #report_dps == 0 and #report_hps == 0 then return nil end

	--generate prefix
	local report = {}
	local combatTime = combat:GetCombatTime()
	local formatedCombatTime = combat:GetFormatedCombatTime()

	report_dps = self:ConcateReport(report_dps)
	report_hps = self:ConcateReport(report_hps)

	local report = {}
	tinsert(report, '-----WCL战斗报告-----')
	tinsert(report, '战斗名称：' .. bossInfo.name .. '[' .. bossInfo.diff_string .. ']')
	tinsert(report, '战斗时长：' .. date("%M:%S", combatTime))
	if db.update then tinsert(report, '评分数据库更新：' .. date("%Y-%m-%d", db.update)) end
	tinsert(report, '-----DPS评分-----')
	for _, line in ipairs(report_dps) do tinsert(report, line) end
	tinsert(report, '-----治疗评分-----')
	for _, line in ipairs(report_hps) do tinsert(report, line) end

	return report

end
--[[
WCL战斗报告:BOSS 
战斗时长：	比95%的团队更快！
数据库更新时间：
DPS评分: [惩戒98]XXXXX， [火焰94]XXXXX， [暗影87]XXXXX，  
HPS评分: [98神圣]XXXXX， [66恢复] XXXXX
]]


function Report:ConcateReport(report)
	local concated_report = {}
	local len = 0
	local temp = {}
	for _, line in ipairs(report) do
		if len + #line > 200 then
			tinsert(concated_report, strjoin("， ", unpack(temp)))
			wipe(temp)
			len = 0
		end
		len = len + #line
		tinsert(temp, line)
	end
	tinsert(concated_report, strjoin("， ", unpack(temp)))
	return concated_report
end


function Report:GenerateReport_Player(player, combat, metric)
	local guid = player:guid() or player.serial
	local spec = player.spec or Details:GetSpec(guid)
	if not spec then return nil end
    if not Core:IsSpecRole(spec, metric, true) then return nil end
    local player_amount
    if metric == 'dps' then
    	player_amount = math.floor(player.last_dps)
    elseif metric == 'hps' then
    	player_amount = math.floor(player.last_hps)
    end
	local difficulty = combat:GetDifficulty()
	-- difficulty = 16
	local bossInfo = combat:GetBossInfo()
		--table members: name, zone, mapid, diff, diff_string, id, ej_instance_id, killed, index@
	local encounter = bossInfo.id
	
	local performance = Core:GetPerf(player_amount, metric, encounter, difficulty, class_id, spec)
	if not performance then return nil end

	--spec_name = select(2, GetSpecializationInfoByID(spec))
	player_name = player:GetOnlyName()

	if player_name and performance then
		return '['..performance..'分]'..player_name
	end
	return nil
end


function Report:UseRaidChannel(combat, db)
	if not self.db.raid_channel then return false end
	local difficulty = combat:GetDifficulty()
	if not difficulty or difficulty ~= 16 then return false end
	local update = db.update_time  --timestamp
	if not update then return false end
	update = tonumber(update)
	local server_time = GetServerTime()
	if server_time > update + 7 * 24 * 3600 then return false end
	return true
end

function Report:SendReport(report, use_raid_channel)
	for _, line in ipairs(report) do
		if use_raid_channel then 
			SendChatMessage(line, 'RAID') 
		else 
			--SendChatMessage(line, 'SAY') 
			DEFAULT_CHAT_FRAME:AddMessage(line) 
		end
	end
end

function Report:ON_BOSS_KILL(event, encounterID)
	-- print(event, encounterID)
	--check disable
	local self = Report
	if self.db.disable then return nil end
	--check encounterID
	local zoneID = Core.encounter_to_zone[encounterID]
	if not zoneID then return nil end

	--check database
	local db = Core:GetZoneDB(zoneID)
	if not db then return nil end
	--get combat info
	local combat = Details:GetCurrentCombat()

	--GenerateReport
	local report = self:GenerateReport(combat, db)
	local use_raid_channel = self:UseRaidChannel(combat, db)
	--SendReport
	if report then self:SendReport(report, use_raid_channel) end
end


local tracker = CreateFrame("Frame")
tracker:RegisterEvent("BOSS_KILL")
tracker:SetScript("OnEvent", Report.ON_BOSS_KILL)
Report.tracker = trakcer