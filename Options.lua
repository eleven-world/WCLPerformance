local addon_name, Addon = ...
local Core = Addon.addon
local Options = Core:NewModule("Options")
Core.Options = Options
Options.addon_name = Core.addon_name

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local _,i,j,k,v

local community_hidden = GetCurrentRegion() ~= 5

function Options:OnInitialize()
	self.db_defaults = {
		profile = {
			details = {
				show_left = false,
				show_right = true,
				color = true,
				bracket = true,
			}
		}
	}
	Core.db = LibStub("AceDB-3.0"):New("WCLPerformance_DB",self.db_defaults,"default")
	self.db = Core.db.profile
	self:Options_Create()
	self:Options_Register()
end

function Options:Options_Create()
	self.options = {
	    name = self.addon_name,
	    handler = self,
	    type = 'group',
	    childGroups = "tab",
	    args = {
	    	info = {
	    		type = 'group',
				name = "",
				inline = true,
				order = 1,
				args = {
					title = {
						type = "description",
						name = function () return "|cffffd100" .. select(2,GetAddOnInfo(self.addon_name)) .. "|r" end,
						fontSize = "large",
						order = 1,
						width = 2,
					},
					join = {
						type = "execute",
						hidden = function () return community_hidden end,
						name = "加入阳光插件社区",
						desc = "加入社区，交流使用问题",
						func = "JoinCommunity",
						order = 2,
					},
					-- note = {
					-- 	type = "description",
					-- 	name = function () return select(3,GetAddOnInfo(self.addon_name)) end,
					-- 	fontSize = "medium",
					-- 	order = 3,
					-- },
					author = {
						type = "description",
						name = "|cffffd100Author: |r" .. GetAddOnMetadata(self.addon_name, "Author"),
						order = 4,
						width = 2,
					},
					version = {
						type = "description",
						name = "|cffffd100Version: |r" .. GetAddOnMetadata(self.addon_name, "Version") .."\n",
						order = 5,
					},
				},
	    	},
	    },
	}
	self.options.args.details = self:Options_Create_Details()
	self.options.args.skada = self:Options_Create_Skada()
	self.options.args.database = self:Options_Create_Database()
end


--[[
配置 Details
显示位置：统计行左侧 统计行右侧
导入自定义文字	还原
配置显示天赋

显示排名颜色
排名加[]包围

]]
function Options:Options_Create_Details()
	local setting = self.db.details
	local options = {
	    name = "Details",
	    handler = self,
	    type = 'group',
	    -- inline = true,
	    disabled = function () if not Details then return true end end,
	    order = 11,
	    args = {
	    	show_setting = {
	    		type = "group",
	    		name = "必要设置",
	    		inline = true,
	    		order = 1,
	    		args = {
	    			-- header = {
	    			-- 	type = "header",
	    			-- 	name = "必要设置",
	    			-- 	order = 0,
	    			-- },
	    			show = {
	    				type = "description",
	    				name = "|cffffd1001. 选择显示位置：|r可以左右都显示，左侧刷新略慢一怕",
			    		order = 11,
	    			},
			    	show_left = {
			    		type = "toggle",
			    		name = "左侧显示",
			    		desc = "WCL分数显示在名字前面",
			    		get = function () return setting.show_left end,
			    		set = function (info, val) setting.show_left = val end,
			    		order = 12,
			    	},
			    	show_right = {
			    		type = "toggle",
			    		name = "右侧显示",
			    		desc = "WCL分数显示在DPS/HPS值后面",
			    		get = function () return setting.show_right end,
			    		set = function (info, val) setting.show_right = val end,
			    		order = 13,
			    	},
	    			custom_text_info = {
	    				type = "description",
	    				name = "\n|cffffd1002. 设置自定义文字：|r通过Details自定义文字显示WCL分数，更改上方选项之后，需要重新按一次设置按钮",
			    		order = 21,
	    			},
			    	custom_text = {
			    		type = "execute",
			    		name = "设置自定义文字",
			    		desc = "在自定义文字中显示WCL分数",
			    		func = "Details_SetCustomText",
			    		order = 22,
			    	},
			    	custom_text_reset = {
			    		type = "execute",
			    		name = "还原",
			    		desc = "不再显示WCL分数",
			    		func = "Details_SetCustomText_Reset",
			    		width = 0.5,
			    		order = 23,
			    	},
	    			custom_text_info2 = {
	    				type = "description",
	    				name = "也可以将下方文本框内的内容复制粘贴到Details自定义文字中，自行设置显示方式",
			    		order = 24,
	    			},
	    			custom_text_input = {
	    				type = "input",
	    				name = "",
	    				get = function () return [[{func return WCLPerf and WCLPerf:DetailsText(...) or ""}]] end,
	    				width = "full",
			    		order = 25,
	    			},
	    			show_spec_info = {
	    				type = "description",
	    				name = "\n|cffffd1003. 追踪天赋：|rWCL分数是分天赋计算的，必须追踪天赋，Details才会查询和记录天赋信息，才能显示分数。之后请谨慎使用Details自身的图标修改功能，可能会使追踪失效。",
			    		order = 31,
	    			},
			    	show_spec = {
			    		type = "execute",
			    		name = "追踪天赋",
			    		desc = "在统计条前面显示天赋图标",
			    		func = "Details_SetSpecShow",
			    		order = 32,
			    	},
			    	show_spec_hide_icon = {
			    		type = "execute",
			    		name = "隐藏图标",
			    		desc = "追踪仍然生效，仅隐藏图标",
			    		func = "Details_SetSpecShow_HideIcon",
			    		order = 33,
			    	},
			    	show_spec_reset = {
			    		type = "execute",
			    		name = "还原",
			    		desc = "不再显示天赋图标",
			    		func = "Details_SetSpecShow_Reset",
			    		width = 0.5,
			    		order = 34,
			    	},
	    		},
	    	},
	    	custom_setting = {
	    		type = "group",
	    		name = "自定义设置",
	    		inline = true,
	    		order = 2,
	    		args = {
	    			-- header = {
	    			-- 	type = "header",
	    			-- 	name = "自定义设置",
	    			-- 	order = 0,
	    			-- },
					color = {
						type = "toggle",
						name = "显示WCL分数颜色",
						desc = "例： |cffe6cc80100|r,|cffff800090|r,|cffa335ee75|r,|cff0070dd50|r,|cff1eff0025|r",
						get = function () return setting.color end,
						set = function (info, val) setting.color = val end,
						order = 1,
					},
					bracket = {
						type = "toggle",
						name = "数字加[]",
						desc = "例： [|cffff800090|r]",
						get = function () return setting.bracket end,
						set = function (info, val) setting.bracket = val end,
						order = 2,
					},
	    		},
	    	},
	    },
	}
	return options
end

function Options:Options_Create_Skada()
	local setting = self.db.skada
	local options = {
	    name = "Skada",
	    handler = self,
	    type = 'group',
	    disabled = function () if not Skada then return true end end,
	    -- inline = true,
	    order = 12,
	    args = {
	    	info = {
				type = "description",
				name = "Skada支持暂未完成，由于Skada不追踪和记录天赋，需要好好研究一下方法",
	    		order = 1,
			},
	    }

	}
	return options
end

function Options:Options_Create_Database()
	local options = {
	    name = "数据库信息",
	    handler = self,
	    type = 'group',
	    order = 21,
	    args = {
	    	info = {
				type = "description",
				name = "",
	    		order = 1,
			},
	    },
	}
	self:Options_Create_Database_All(options.args)
	return options
end

function Options:Options_Create_Database_All(database_tab)
	for addon_name,_ in pairs(Core.addon_to_zone) do
		database_tab[addon_name] = self:Options_Create_Database_Addon(addon_name)
	end
end

function Options:Options_Create_Database_Addon(addon_name)
	local options = {
		type = "group",
		name = addon_name,
		inline = true,
		args = {
			title = {
				type = "description",
				name = self:GetAddonInstances(addon_name),
	    		order = 1,
			},
			update = {
				type = "description",
				name = "更新时间: " .. date("%Y-%m-%d %H:%M:%S", tonumber(GetAddOnMetadata(addon_name, "X-Update-Date"))),
	    		order = 2,
			},
			status = {
				type = "description",
				name = function () if IsAddOnLoaded(addon_name) then return '状态：|cff00ff00已启用|r' else return '状态：|cffff0000未启用|r' end end,
				width = 1,
	    		order = 3,
			},
			load = {
				type = "execute",
				name = "加载",
				hidden = function () return IsAddOnLoaded(addon_name) end,
				func = function () return LoadAddOn(addon_name) end,
				width = 0.5,
	    		order = 4,
			},
		},
	}
	return options	
end

function Options:Options_Register()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(self.addon_name, self.options)
	AceConfigDialog:AddToBlizOptions(self.addon_name, self.addon_name)
	LibStub("AceConsole-3.0"):RegisterChatCommand("wcl", function() AceConfigDialog:Open(self.addon_name) end)
	AceConfigDialog:SetDefaultSize(self.addon_name, 858, 660)
end

function Options:JoinCommunity()
	local club_link = GetClubTicketLink("eaa30RMfp05", "阳光插件", 0)
	if club_link then
		DEFAULT_CHAT_FRAME:AddMessage("社区链接已生成，请点击 "..club_link)
	end
end

function Options:Details_SetCustomText()
	local setting = self.db.details
	local show_left = setting.show_left
	local show_right = setting.show_right
	local left_text = [[{func return WCLPerf and WCLPerf:DetailsText(...) or ""}{data3}{data2}]]
	local right_text = [[{data1} ({data2}) {func return WCLPerf and WCLPerf:DetailsText(...) or ""}]]
	for i = 1, 10 do
		local instance = Details:GetInstance(i)
		if instance then
			--instance:SetBarTextSettings (size, font, fixedcolor, leftcolorbyclass, rightcolorbyclass, leftoutline, rightoutline, customrighttextenabled, customrighttext, percentage_type, showposition, customlefttextenabled, customlefttext, translittest)
			instance:SetBarTextSettings (nil, nil, nil, nil, nil, nil, nil, show_right, right_text, nil, nil, show_left, left_text, nil)
	   end
	end
end

function Options:Details_SetCustomText_Reset()
	local show_left = false
	local show_right = false
	local left_text = [[{data1}. {data3}{data2}]]
	local right_text = [[{data1} ({data2}, {data3}%)]]

	for i = 1, 10 do
		local instance = Details:GetInstance(i)
		if instance then
			instance:SetBarTextSettings (nil, nil, nil, nil, nil, nil, nil, show_right, right_text, nil, nil, show_left, left_text, nil)
		end
	end
end

function Options:Details_SetSpecShow()
	local iconpath = [[Interface\AddOns\Details\images\spec_icons_normal]]
	for _, instance in ipairs (Details.tabela_instancias) do
		instance:SetBarSettings (nil, nil, nil, nil, nil, nil, nil, nil, iconpath)
		instance:SetBarSpecIconSettings (true, iconpath, true)
	end
	if DetailsOptionsWindow4 then _G.DetailsOptionsWindow4.iconFileEntry:SetText (iconpath) end
	_detalhes:SendOptionsModifiedEvent (DetailsOptionsWindow.instance)
end

function Options:Details_SetSpecShow_HideIcon()
	local iconpath = [[]]
	for _, instance in ipairs (Details.tabela_instancias) do
		instance:SetBarSettings (nil, nil, nil, nil, nil, nil, nil, nil, iconpath)
	end
	if DetailsOptionsWindow4 then _G.DetailsOptionsWindow4.iconFileEntry:SetText (iconpath) end
	_detalhes:SendOptionsModifiedEvent (DetailsOptionsWindow.instance)
end

function Options:Details_SetSpecShow_Reset()
	local iconpath = [[]]
	for _, instance in ipairs (Details.tabela_instancias) do
		instance:SetBarSettings (nil, nil, nil, nil, nil, nil, nil, nil, iconpath)
		instance:SetBarSpecIconSettings (false)
	end
	if DetailsOptionsWindow4 then _G.DetailsOptionsWindow4.iconFileEntry:SetText (iconpath) end
	_detalhes:SendOptionsModifiedEvent (DetailsOptionsWindow.instance)
end

function Options:GetAddonInstances(addon_name)
	local InstanceIDs = {strsplit(",", GetAddOnMetadata(addon_name, "X-InstanceID"))}
	local all = "数据库包含："
	for _, InstanceID in ipairs(InstanceIDs) do
		local link = select(8,EJ_GetInstanceInfo(InstanceID))
		if link then all = all .. link end
	end
	return all
end