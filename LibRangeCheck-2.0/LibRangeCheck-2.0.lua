--[[
Name: LibRangeCheck-2.0
Revision: $Revision$
Author(s): mitch0
Website: http://www.wowace.com/projects/librangecheck-2-0/
Description: A range checking library based on interact distances and spell ranges
Dependencies: LibStub
License: Public Domain
]]

local MAJOR_VERSION = "LibRangeCheck-2.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) + 100000

local RangeCheck = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not RangeCheck) then
	return
end

-- << STATIC CONFIG

local ItemRequestTimeout = 2.0

-- interact distance based checks. ranges are based on my own measurements (thanks for all the folks who helped me with this)
local DefaultInteractList = {
	[3] = 8,
	[2] = 9,
	[4] = 28,
}

-- interact list overrides for races
local InteractLists = {
	["Tauren"] = {
		[3] = 6,
		[2] = 7,
		[4] = 25,
	},
	["Scourge"] = {
		[3] = 7,
		[2] = 8,
		[4] = 27,
	},
}

local MeleeRange = 5
local VisibleRange = 100

-- list of friendly spells that have different ranges
local FriendSpells = {}
-- list of harmful spells that have different ranges, spells with DeadZone must come first!
local HarmSpells = {}

FriendSpells["DRUID"] = {
	5185, -- ["Healing Touch"], -- 40
	1126, -- ["Mark of the Wild"], -- 30
}
HarmSpells["DRUID"] = {
	16979, -- ["Feral Charge"], -- 8-25
	5176, -- ["Wrath"], -- 30 (Nature's Reach: 33, 36)
	6795, -- ["Growl"], -- 5, 20 in wotlk
	6807, -- ["Maul"], -- 5
}

FriendSpells["HUNTER"] = {}
HarmSpells["HUNTER"] = {
	75, -- ["Auto Shot"], -- 8-35 (Hawk Eye: 37, 39, 41)
	2764, -- ["Throw"], -- 30
	19503, -- ["Scatter Shot"], -- 15 (Hawk Eye: 17, 19, 21)
	2974, -- ["Wing Clip"], -- 5
}

FriendSpells["MAGE"] = {
	23028, -- ["Arcane Brilliance"], -- 40
	1459, -- ["Arcane Intellect"], -- 30
}
HarmSpells["MAGE"] = {
	-- R.I.P ["Detect Magic"], -- 40
	133, -- ["Fireball"], -- 35 ( Flame Throwing: 38, 41 )
	116, -- ["Frostbolt"], -- 30 ( Arctic Reach: 33, 36 )
	2948, -- ["Scorch"], -- 30 (Flame Throwing: 33, 36 )
	5019, -- ["Shoot"], -- 30
	2136, -- ["Fire Blast"], -- 20 (Flame Throwing: 23, 26; Gladiator Gloves: +5)
}

FriendSpells["PALADIN"] = {
	635, -- ["Holy Light"], -- 40
	19740, -- ["Blessing of Might"], -- 30
	20473, -- ["Holy Shock"], -- 20
}
HarmSpells["PALADIN"] = {
	24275, -- ["Hammer of Wrath"],  -- 30
	20473, -- ["Holy Shock"], -- 20
	20271, -- ["Judgement"], -- 10
	35395, -- ["Crusader Strike"], -- 5
} 

FriendSpells["PRIEST"] = {
	2050, -- ["Lesser Heal"], -- 40
	1243, -- ["Power Word: Fortitude"], -- 30
}
HarmSpells["PRIEST"] = {
	585, -- ["Smite"], -- 30 (Holy Reach: 33, 36)
	589, -- ["Shadow Word: Pain"], -- 30 (Shadow Reach: 33, 36)
	5019, -- ["Shoot"], -- 30
	15407, -- ["Mind Flay"], -- 20 (Shadow Reach: 22, 24)
}

FriendSpells["ROGUE"] = {}
HarmSpells["ROGUE"] = {
	2764, -- ["Throw"], -- 30
	2094, -- ["Blind"], -- 10 (Dirty Tricks: 12, 15)
	2098, -- ["Eviscerate"], -- 5
}

FriendSpells["SHAMAN"] = {
	331, -- ["Healing Wave"], -- 40
	526, -- ["Cure Poison"], -- 30
}
HarmSpells["SHAMAN"] = {
	403, -- ["Lightning Bolt"], -- 30 (Storm Reach: 33, 36)
	370, -- ["Purge"], -- 30
	8042, -- ["Earth Shock"], -- 20 (Gladiator Gloves: +5)
}

FriendSpells["WARRIOR"] = {}
HarmSpells["WARRIOR"] = {
	100, -- ["Charge"], -- 8-25
	3018, -- ["Shoot"], -- 8-30
	2764, -- ["Throw"], -- 30
	355, -- ["Taunt"], -- 5, 20 in wotlk
	5246, -- ["Intimidating Shout"], -- 10
	772, -- ["Rend"], -- 5
}

FriendSpells["WARLOCK"] = {
	5697, -- ["Unending Breath"], -- 30 (demo)
}
HarmSpells["WARLOCK"] = {
	5019, -- ["Shoot"], -- 30
	348, -- ["Immolate"], -- 30 (Destructive Reach: 33, 36)
	172, -- ["Corruption"], -- 30 (Grim Reach: 33, 36)
	5782, -- ["Fear"], -- 20 (Grim Reach: 22, 24)
	17877, -- ["Shadowburn"], -- 20 (Destructive Reach: 22, 24)
}

FriendSpells["DEATHKNIGHT"] = {
}
HarmSpells["DEATHKNIGHT"] = {
	47541, -- ["Death Coil"], -- 30
	45477, -- ["Icy Touch"], -- 20 (Icy Reach: 25, 30)
	56222, -- ["Dark Command"], -- 20
	50842, -- ["Pestilence"], -- 5
	45902, -- ["Blood Strike"], -- 5, but requires weapon, use Pestilence if possible, so keep it after Pestilence in this list
}

local DeadZoneSpells = {
	["DRUID"] = 16979, -- ["Feral Charge"], -- 8-25
	["HUNTER"] = 75, -- ["Auto Shot"], -- 8-35 (Hawk Eye: 37, 39, 41)
	["WARRIOR"] = 100, -- ["Charge"], -- 8-25
}

-- Items [Special thanks to Maldivia for the nice list]

FriendItems  = {
	[5] = {
--WOTLK		37727, -- Ruby Acorn ### BOTH
	},
	[8] = {
--WOTLK		33278, -- Burning Torch ### BOTH
	},
	[10] = {
		32321, -- Sparrowhawk Net ### BOTH
	},
	[15] = {
		1251, -- Linen Bandage
		2581, -- Heavy Linen Bandage
		3530, -- Wool Bandage
		3531, -- Heavy Wool Bandage
		6450, -- Silk Bandage
		6451, -- Heavy Silk Bandage
		8544, -- Mageweave Bandage
		8545, -- Heavy Mageweave Bandage
		14529, -- Runecloth Bandage
		14530, -- Heavy Runecloth Bandage
		21990, -- Netherweave Bandage
		21991, -- Heavy Netherweave Bandage
--WOTLK		34721, -- Frostweave Bandage
--WOTLK		34722, -- Heavy Frostweave Bandage
--WOTLK		38643, -- Thick Frostweave Bandage
--WOTLK		38640, -- Dense Frostweave Bandage
	},
	[20] = {
		21519, -- Mistletoe
	},
	[25] = {
		31463, -- Zezzak's Shard ### BOTH
	},
	[30] = {
		1180, -- Scroll of Stamina
		1478, -- Scroll of Protection II
		3012, -- Scroll of Agility
		1712, -- Scroll of Spirit II
		2290, -- Scroll of Intellect II
		1711, -- Scroll of Stamina II
	},
	[40] = {
		34471, -- Vial of the Sunwell
	},
	[45] = {
		32698, -- Wrangling Rope ### BOTH
	},
	[60] = {
--WOTLK		37887, -- Seeds of Nature's Wrath ### BOTH
	},
	[80] = {
--WOTLK		35278, -- Reinforced Net ### BOTH
	},
}

HarmItems = {
	[5] = {
--WOTLK		37727, -- Ruby Acorn ### BOTH
	},
	[8] = {
--WOTLK		33278, -- Burning Torch ### BOTH
	},
	[10] = {
		32321, -- Sparrowhawk Net ### BOTH
	},
	[15] = {
		33069, -- Sturdy Rope
	},
	[20] = {
		10645, -- Gnomish Death Ray
	},
	[25] = {
		24268, -- Netherweave Net
--WOTLK		41509, -- Frostweave Net
		31463, -- Zezzak's Shard ### BOTH
	},
	[30] = {
		835, -- Large Rope Net
		7734, -- Six Demon Bag
	},
	[35] = {
		24269, -- Heavy Netherweave Net ### not in game ???
	},
	[40] = {
		28767, -- The Decapitator
	},
	[45] = {
		32698, -- Wrangling Rope ### BOTH
	},
	[60] = {
--WOTLK		37887, -- Seeds of Nature's Wrath ### BOTH
	},
	[80] = {
--WOTLK		35278, -- Reinforced Net ### BOTH
	},
}

MiscItems = {
}

-- This could've been done by checking player race as well and creating tables for those, but it's easier like this
for k, v in pairs(FriendSpells) do
	tinsert(v, 28880) -- ["Gift of the Naaru"]
end
for k, v in pairs(HarmSpells) do
	tinsert(v, 28734) -- ["Mana Tap"]
end

-- >> END OF STATIC CONFIG

-- cache

local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local GetSpellInfo = GetSpellInfo
local GetItemInfo = GetItemInfo
local UnitCanAttack = UnitCanAttack
local UnitCanAssist = UnitCanAssist
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local tonumber = tonumber
local CheckInteractDistance = CheckInteractDistance
local IsSpellInRange = IsSpellInRange
local IsItemInRange = IsItemInRange
local UnitIsVisible = UnitIsVisible
local tinsert = tinsert
local GetInventoryItemLink = GetInventoryItemLink
local GetTime = GetTime
local HandSlotId = GetInventorySlotInfo("HandsSlot")
local TT = ItemRefTooltip

-- temporary stuff

local itemRequests = nil
local itemRequestTimeoutAt = nil

-- helper functions

local function print(text)
	if (DEFAULT_CHAT_FRAME) then 
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

local function requestItemInfo(itemId)
	itemRequestTimeoutAt = GetTime() + ItemRequestTimeout
	if (itemId == nil or GetItemInfo(itemId)) then return end
	TT:SetHyperlink(string.format("item:%d", itemId))
end

-- minRangeCheck is a function to check if spells with minimum range are really out of range, or fail due to range < minRange. See :init() for its setup
local minRangeCheck = function(unit) return CheckInteractDistance(unit, 2) end

local deadZoneCheck = nil

local function isTargetValid(unit)
	return UnitExists(unit) and (not UnitIsDeadOrGhost(unit))
end

-- return the spellIndex of the given spell by scanning the spellbook
local function findSpellIdx(spellName)
	local i = 1
	while true do
	    local spell, rank = GetSpellName(i, BOOKTYPE_SPELL)
	    if (not spell) then return nil end
	    if (spell == spellName) then return i end
	    i = i + 1
	end
	return nil
end

-- minRange should be nil if there's no minRange, not 0
local function addChecker(t, range, minRange, checker)
	local rc = { ["range"] = range, ["minRange"] = minRange, ["checker"] = checker }
	for i, v in ipairs(t) do
		if (rc.range == v.range) then return end
        if (rc.range > v.range) then
        	tinsert(t, i, rc)
        	return
    	end
	end
	tinsert(t, rc)
end

local function addItemRequest(item)
	if (itemRequests == nil) then
		itemRequests = { item }
	else
		tinsert(itemRequests, item)
	end
end

local function createCheckerList(spellList, interactList, itemList, doItemReq)
	local res = {}
	local ranges = {}
    if (spellList) then
	    for i, sid in ipairs(spellList) do
			local name, _, _, _, _, _, _, minRange, range = GetSpellInfo(sid)
	    	local spellIdx = findSpellIdx(name)
	    	if (spellIdx and range) then
				if (minRange == 0) then -- getRange() expects minRange to be nil in this case
					minRange = nil
				end
				if (range == 0) then
					range = MeleeRange
				end
				if (not ranges[range]) then
					ranges[range] = true
					addChecker(res, range, minRange, function(unit)
						if (IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1) then return true end
					end)
				end
			end
	    end
    end
	
	if (itemList) then
		for range, items in pairs(itemList) do
			if ((not ranges[range]) and (#(items) > 0)) then
				local itemReq = nil
				for i, item in ipairs(items) do
					if (GetItemInfo(item)) then
						itemReq = nil
						ranges[range] = true
						addChecker(res, range, nil, function(unit)
							if (IsItemInRange(item, unit) == 1) then return true end
						end)
						break
					end
					if (itemReq == nil) then
						itemReq = item -- we will request caching of the first item from the list if we can't find any of them in the cache
					end
				end
				if (doItemReq and itemReq ~= nil) then
					addItemRequest(itemReq)
				end
			end
		end
	end
	
	if (not interactList) then interactList = DefaultInteractList end
	for index, range in pairs(interactList) do
		if (not ranges[range]) then
			ranges[range] = true
			addChecker(res, range, nil, function(unit)
				if (CheckInteractDistance(unit, index)) then return true end
			end)
		end
    end

    return res
end

-- returns minRange, maxRange, isInDeadZone or nil
local function getRange(unit, checkerList, checkVisible)
	local min, max, isInDeadZone = 0, nil, nil
    if (checkVisible) then
    	if (UnitIsVisible(unit)) then
    		max = VisibleRange
    	else
    		return VisibleRange, nil
    	end
    end
    for i, rc in ipairs(checkerList) do
		if (not max or max > rc.range) then
			if (rc.checker(unit)) then
				max = rc.range
				if (rc.minRange) then
					min = rc.minRange
				end
			elseif (rc.minRange and minRangeCheck(unit)) then
				isInDeadZone = true
				max = rc.minRange
			elseif (min > rc.range) then
				return min, max, nil
			else
				return rc.range, max, isInDeadZone
			end
		end
    end
    return min, max, isInDeadZone and (max > 5)
end

-- OK, here comes the actual lib

-- pre-initialize the checkerLists here so that we can return some meaningful result even if
-- someone manages to call us before we're properly initialized. miscRC should be independent of
-- race/class/talents, so it's safe to initialize it here
-- friendRC and harmRC will be properly initialized later when we have all the necessary data for them
RangeCheck.miscRC = createCheckerList()
RangeCheck.friendRC = RangeCheck.miscRC
RangeCheck.harmRC = RangeCheck.miscRC

-- << Public API

-- "export" it, maybe someone will need it for formatting
RangeCheck.MeleeRange = MeleeRange
RangeCheck.VisibleRange = VisibleRange

-- returns if the unit (default="player") has a deadZone (or will have one later)
function RangeCheck:hasDeadZone(unit)
	unit = unit or "player"
	local _, playerClass = UnitClass(unit)
	return (DeadZoneSpells[playerClass] ~= nil)
end

-- returns if the player is in deadZone regarding unit
function RangeCheck:isInDeadZone(unit)
	return (deadZoneCheck and deadZoneCheck(unit))
end

-- returns minRange, maxRange or nil
function RangeCheck:getRange(unit, checkVisible)
	if (not isTargetValid(unit)) then return nil end
	if (UnitCanAttack("player", unit)) then
	    return getRange(unit, self.harmRC, checkVisible)
	elseif (UnitCanAssist("player", unit)) then
	    return getRange(unit, self.friendRC, checkVisible)
	else
		return getRange(unit, self.miscRC, checkVisible)
	end
end

-- returns the range estimate as a string
function RangeCheck:getRangeAsString(unit, checkVisible, showOutOfRange)
	local minRange, maxRange = self:getRange(unit, checkVisible)
	if (not minRange) then return nil end
	if (not maxRange) then
		return showOutOfRange and minRange .. " +" or nil
	end
	return minRange .. " - " .. maxRange
end

-- initialize RangeCheck if not yet initialized or if "forced"
function RangeCheck:init(forced)
	if (self.initialized and (not forced)) then return end
	local doItemReq = not self.initialized
	self.initialized = true
	local _, playerClass = UnitClass("player")
	local _, playerRace = UnitRace("player")

	minRangeCheck = nil
	-- first try to find a nice item we can use for minRangeCheck
	if (HarmItems[15]) then
		local items = HarmItems[15]
		for _, item in ipairs(items) do
			if (GetItemInfo(item)) then
				minRangeCheck = function(unit)
					return (IsItemInRange(item, unit) == 1)
				end
				break
			end
		end
	end
	if (not minRangeCheck) then
		-- ok, then try to find some class specific spell
		if (playerClass == "WARRIOR") then
			-- for warriors, use Intimidating Shout if available
			local name = GetSpellInfo(5246) -- ["Intimidating Shout"]
			local spellIdx = findSpellIdx(name)
			if (spellIdx) then
				minRangeCheck = function(unit)
					return (IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1)
				end
			end
		elseif (playerClass == "ROGUE") then
			-- for rogues, use Blind if available
			local name = GetSpellInfo(2094) -- ["Blind"]
			local spellIdx = findSpellIdx(name)
			if (spellIdx) then
				minRangeCheck = function(unit)
					return (IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 1)
				end
			end
		end
	end
	if (not minRangeCheck) then
		-- fall back to interact distance checks
		if  (playerClass == "HUNTER" or playerRace == "Tauren") then
			-- for hunters, use interact4 as it's safer
			-- for Taurens interact4 is actually closer than 25yd and interact2 is closer than 8yd, so we can't use that
			minRangeCheck = function(unit) return CheckInteractDistance(unit, 4) end
		else
			minRangeCheck = function(unit) return CheckInteractDistance(unit, 2) end
		end
	end

	local interactList = InteractLists[playerRace]
	self.friendRC = createCheckerList(FriendSpells[playerClass], interactList, FriendItems, doItemReq)
	self.harmRC = createCheckerList(HarmSpells[playerClass], interactList, HarmItems, doItemReq)
	self.miscRC = createCheckerList(nil, interactList, MiscItems, doItemReq)
	self.handSlotItem = GetInventoryItemLink("player", HandSlotId)

	deadZoneCheck = nil
	local deadZoneSpell = DeadZoneSpells[playerClass]
	if (deadZoneSpell) then
		local name = GetSpellInfo(deadZoneSpell)
		local spellIdx = findSpellIdx(name)
		if (spellIdx) then
			deadZoneCheck = function(unit)
				return (IsSpellInRange(spellIdx, BOOKTYPE_SPELL, unit) == 0 and minRangeCheck(unit))
			end
		end
	end
end

-- >> Public API

function RangeCheck:OnEvent(event, ...)
	if (type(self[event]) == 'function') then
		self[event](self, event, ...)
	end
end

function RangeCheck:LEARNED_SPELL_IN_TAB()
	self:init(true)
end

function RangeCheck:CHARACTER_POINTS_CHANGED()
	self:init(true)
end

function RangeCheck:UNIT_INVENTORY_CHANGED(event, unit)
	if (self.initialized and unit == "player" and self.handSlotItem ~= GetInventoryItemLink("player", HandSlotId)) then
		self:init(true)
	end
end

function RangeCheck:initialOnUpdate()
		self:init()
		if (itemRequests ~= nil) then
			local item = itemRequests[#(itemRequests)]
			if (itemRequestTimeoutAt == nil) then
				requestItemInfo(item)
				return
			end
			if (GetItemInfo(item) or (GetTime() > itemRequestTimeoutAt)) then
				tremove(itemRequests)
				if (#(itemRequests) > 0) then
					item = itemRequests[#(itemRequests)]
					requestItemInfo(item)
					return
				else -- clean up, and force a reinit
					itemRequests = nil
					itemRequestTimeoutAt = nil
					self:init(true)
				end
			else
				return -- still waiting for the answer
			end
		end
		self.frame:SetScript("OnUpdate", nil)
		self.frame:Hide()
end

-- << DEBUG STUFF

local function addItemRequests(itemList)
	if (itemList == nil)  then return end
	for _, items in pairs(itemList) do
		for _, item in ipairs(items) do
			addItemRequest(item)
		end
	end
end

function RangeCheck:cacheAllItems()
	if ((not self.initialized) or (itemRequests ~= nil)) then
		print(MAJOR_VERSION .. ": init hasn't finished yet")
		return
	end
	addItemRequests(FriendItems)
	addItemRequests(HarmItems)
	addItemRequests(MiscItems)
	if (itemRequests == nil) then return end
	print(MAJOR_VERSION .. ": starting item cache")
	self.frame:SetScript("OnUpdate", function(frame, elapsed) self:initialOnUpdate() end)
	self.frame:Show()
end

function RangeCheck:startMeasurement(unit, resultTable)
	if ((not self.initialized) or (itemRequests ~= nil)) then
		print(MAJOR_VERSION .. ": init hasn't finished yet")
		return
	end
	if (self.measurements) then
		print(MAJOR_VERSION .. ": measurements already running")
		return
	end
	print(MAJOR_VERSION .. ": starting measurements")
	local _, playerClass = UnitClass("player")
	local spellList
	if (UnitCanAttack("player", unit)) then
		spellList = HarmSpells[playerClass]
	elseif (UnitCanAssist("player", unit)) then
		spellList = FriendSpells[playerClass]
	end
	self.spellsToMeasure = {}
	if (spellList) then
		for _, sid in ipairs(spellList) do
			local name = GetSpellInfo(sid)
			local spellIdx = findSpellIdx(name)
			if (spellIdx) then
				self.spellsToMeasure[name] = spellIdx
			end
		end
	end
	self.measurements = resultTable
	self.measurementUnit = unit
	self.measurementStart = GetTime()
	self.lastMeasurements = {}
	self:updateMeasurements()
	self.frame:SetScript("OnUpdate", function(frame, elapsed) self:updateMeasurements() end)
	self.frame:Show()
end

function RangeCheck:stopMeasurement()
	print(MAJOR_VERSION .. ": stopping measurements")
	self.frame:Hide()
	self.frame:SetScript("OnUpdate", nil)
	self.measurements = nil
end

function RangeCheck:checkItems(itemList)
	if (itemList == nil) then return end
	for range, items in pairs(itemList) do
		for _, item in ipairs(items) do
			local name = GetItemInfo(item)
			if (name == nil) then
				print(MAJOR_VERSION .. ": " .. tostring(item) .. ": not in cache")
			else
				print(MAJOR_VERSION .. ": " .. tostring(item) .. ": " .. tostring(name) .. ": " .. tostring(range) .. "yd: " .. tostring(IsItemInRange(item, "target")))
			end
		end
	end
end

function RangeCheck:checkAllItems()
	print(MAJOR_VERSION .. ": Checking FriendItems...")
	self:checkItems(FriendItems)
	print(MAJOR_VERSION .. ": Checking HarmItems...")
	self:checkItems(HarmItems)
	print(MAJOR_VERSION .. ": Checking MiscItems...")
	self:checkItems(MiscItems)
end

local GetPlayerMapPosition = GetPlayerMapPosition
function RangeCheck:updateMeasurements()
	local now = GetTime() - self.measurementStart
	local x, y = GetPlayerMapPosition("player")
	local t = self.measurements[now]
	local unit = self.measurementUnit
	for name, id in pairs(self.spellsToMeasure) do
		local last = self.lastMeasurements[name]
		local curr = (IsSpellInRange(id, BOOKTYPE_SPELL, unit) == 1) and true or false
		if (last == nil or last ~= curr) then
			print("### " .. tostring(name) .. ": " .. tostring(last) .. " ->  " .. tostring(curr))
			if (t == nil) then
				t = {}
				t.x, t.y, t.stamp, t.states = x, y, now, {}
				self.measurements[now] = t
			end
			t.states[name]= curr
			self.lastMeasurements[name] = curr
		end
	end
	for i, v in pairs(DefaultInteractList) do
		local name = "interact" .. i
		local last = self.lastMeasurements[name]
		local curr = CheckInteractDistance(unit, i) and true or false
		if (last == nil or last ~= curr) then
			print("### " .. tostring(name) .. ": " .. tostring(last) .. " ->  " .. tostring(curr))
			if (t == nil) then
				t = {}
				t.x, t.y, t.stamp, t.states = x, y, now, {}
				self.measurements[now] = t
			end
			t.states[name] = curr
			self.lastMeasurements[name] = curr
		end
	end
end

-- >> DEBUG STUFF

-- << load-time initialization 

function RangeCheck:activate()
	if (not self.frame) then
    	local frame = CreateFrame("Frame")
    	self.frame = frame
		frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
		frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
		local _, playerClass = UnitClass("player")
		if (playerClass == "MAGE" or playerClass == "SHAMAN") then
			-- Mage and Shaman gladiator gloves modify spell ranges
			frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
		end
    end
	self.frame:SetScript("OnEvent", function(frame, ...) self:OnEvent(...) end)
	self.frame:SetScript("OnUpdate", function(frame, ...) self:initialOnUpdate() end)
end

RangeCheck:activate()
RangeCheck = nil
