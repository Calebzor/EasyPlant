-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyPlant
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"

-----------------------------------------------------------------------------------------------
-- EasyPlant Module Definition
-----------------------------------------------------------------------------------------------
local EasyPlant = {} 
local eventsActive = false

local fnSortSeedsFirst = function(itemLeft, itemRight)
	
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end
	
	
	local strLeftItemType = itemLeft:GetItemType()
	local strRightItemType= itemRight:GetItemType()
	if strLeftItemType==213 then
		return -1
	end
	if strRightItemType == 213 and strLeftItemType ~= 213 then
		
		return 1
	end
	if strLeftItemType ~= 213 and strRightItemType ~= 213 then
		return -1
	end
	
	return 0
end


function EasyPlant:Events(activate)
	if(activate==true) then
		--Apollo.RegisterEventHandler("UnitCreated", 	"OnUnitCreated", self)
		Apollo.RegisterEventHandler("UnitDestroyed","OnUnitDestroyed",self)
		Apollo.RegisterEventHandler("UpdateInventory","OnUpdateInventory",self)
		self.eventsActive = true
	else
		Apollo.RemoveEventHandler("UpdateInventory",self)
		--Apollo.RemoveEventHandler("UnitCreated", self)
		Apollo.RemoveEventHandler("UnitDestroyed", self)
		self.eventsActive = false
	end
		

end

function EasyPlant:OnLoad()
	--Apollo.RegisterEventHandler("SubZoneChanged", "OnSubZoneChanged", self)
	self.watching = {}
	self.arPreloadUnits = {}
	Apollo.RegisterEventHandler("UnitCreated","OnPreloadUnitCreated",self)
	
	Apollo.RegisterEventHandler("SubZoneChanged", "OnSubZoneChanged", self)
	Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)
	self:Events(true)
	
	
	-- Array to store units encountered pre-load
	
		--Apollo.RegisterEventHandler("UnitDestroyed","OnUnitDestroyed",self)
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("EasyPlant.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end
-----------------------------------------------------------------------------------------------
-- EasyPlant OnDocLoaded
-----------------------------------------------------------------------------------------------
function EasyPlant:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "EasyPlantForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	    self.wndMain:Show(false, true)
		local x,y = Apollo.GetScreenSize()
		self.wndMain:SetAnchorOffsets((x/2),(y/2)-45,(x/2),(y/2))
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		self.lastZone = 0
		self.unit=0
		
		self.toplant = 0
		--self.eventsActive = true
		
		--self.unitplayer = GameLib.GetPlayerUnit()
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("ep", "OnEp2", self)
		
		local bagwindow = self.wndMain:FindChild("MainBagWindow")
		bagwindow:SetSort(true)
		bagwindow:SetItemSortComparer(fnSortSeedsFirst)
		
		--Apollo.RegisterEventHandler("UnitCreated","OnUnitCreated",self)
		--Apollo.RegisterEventHandler("UnitDestroyed","OnUnitDestroyed",self)
		--Apollo.RegisterEventHandler("UpdateInventory","OnUpdateInventory",self)
		--Apollo.RegisterEventHandler("UpdateInventory","OnUpdateInventory",self)
		
		self:CreateUnitsFromPreload()
		Apollo.RemoveEventHandler("UnitCreated", self)
		Apollo.RegisterEventHandler("UnitCreated", 	"OnUnitCreated", self)
		self.timer = ApolloTimer.Create(1.000, true, "OnTimer", self)
		--local zoneid = GameLib.GetCurrentZoneId()
		--if (zoneid == 0) then
		--	 ApolloTimer.Create(3.000, false, "OnLoginZoneCheck", self)
		--else
		--	self:OnSubZoneChanged(GameLib.GetCurrentZoneId())
		--end
	end
	
end


function EasyPlant:OnWindowManagementReady()
    Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "EasyPlant"})
	if(self.lastZone==0) then
		self:OnSubZoneChanged(GameLib.GetCurrentZoneId())	
	end
end

function EasyPlant:OnLoginZoneCheck()
	self:OnSubZoneChanged(GameLib.GetCurrentZoneId())
end

function EasyPlant:OnEp2()
	--Print(tostring(self.eventsActive))
	Print(self.lastZone)
	Print(tostring(self.eventsActive))
end

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function EasyPlant:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function EasyPlant:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
	
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- EasyPlant OnLoad
-----------------------------------------------------------------------------------------------









function EasyPlant:OnEp(override)
	
	if(self.wndMain:IsVisible() and override==false) then
		return
	end
	
	local seedcount=0
	local InvItems = GameLib.GetPlayerUnit():GetInventoryItems()
	for i, InvItem in ipairs(InvItems) do
		if InvItem then
			local item = InvItem.itemInBag
			if (item:GetItemType()==213) then
				seedcount=seedcount+1
			end
		end
		
	end
	if(seedcount<1) then
		self.wndMain:Close()
		return
	end	
		
	
	
	if (self.wndMain:IsVisible()==false) then
		self.wndMain:Invoke() 
	end
	
	local bagwindow = self.wndMain:FindChild("MainBagWindow")
	--Print("repainting")
	local multi = 40
	bagwindow:SetAnchorOffsets(0,0,seedcount*multi+multi,45)
	local x,_,_,y = self.wndMain:GetAnchorOffsets()
	--self.wndMain:SetAnchorOffsets((x/2)-((seedcount*multi+multi)/2),(y/2)-45,(x/2)+(seedcount*multi+multi)/2,(y/2))
	self.wndMain:SetAnchorOffsets((x),(y)-45,(x)+(seedcount*multi+multi),(y))
	
	bagwindow:SetSquareSize(40, 40)
	
	
end

function EasyPlant:OnMouseButtonDown()
	--Apollo.GetString(65683) GetTargetUnit
	
	local curtarget = GameLib.GetTargetUnit()
	if(curtarget and curtarget:GetName()==Apollo.GetString(617068)) then
		self.toplant = curtarget:GetId()
	end
	
	if(self.toplant==0) then
		local toplant = self:GetToPlantUnitId()
		if(toplant>0) then
			self.toplant = toplant
		else
			return
		end
	end
	--Print(self.toplant)
	self.watching[self.toplant]["blocktime"] = GameLib.GetGameTime()
	GameLib.SetTargetUnit(self.watching[self.toplant]["unit"])
	self.toplant = 0
	
end

function EasyPlant:OnChangeWorld()
	if(self.eventsActive==false) then
		self:Events(true)
	end

end

function EasyPlant:OnSubZoneChanged(idZone,pszZoneName)
	
	if (idZone == 1136 and self.lastZone~=1136) then
		if(self.eventsActive==false) then
			self:Events(true)
		end
		self.timer:Start()
		--Apollo.RegisterEventHandler("UpdateInventory","OnUpdateInventory",self)
		--Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
		--Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	elseif (idZone ~= 1136) then
	
		self.watching = {}
		self:Events(false)
		self.timer:Stop()
	end
	self.lastZone = idZone

end


function EasyPlant:OnUpdateInventory()
	--Print("updateinv")
	if(self.toplant==0) then
		local toplant = self:GetToPlantUnitId()
		if(toplant>0) then
			self.toplant = toplant
		end
	end
	
	if(self.toplant>0) then
		--Print("execute")
		self:OnEp(true)
	end
end

function EasyPlant:OnPreloadUnitCreated(unitNew)
	
	self.arPreloadUnits[unitNew:GetId()] = unitNew
end

function EasyPlant:OnUnitCreated(unit)
	--Print("OnUnitCreated") --and 65683 old one
	if((unit) and (unit:GetName()==Apollo.GetString(617068)) and (unit:GetType()=="Simple")  and (self.watching[unit:GetId()] == nil)) then
		--Print("watching")
		self.watching[unit:GetId()] = {}
		self.watching[unit:GetId()]["unit"] = unit
		
	end

end

function EasyPlant:OnUnitDestroyed(unit)
	--Print("onunitdestroyed") and (unit:GetName()==Apollo.GetString(617068)) kinda not needed
	if((unit) and (self.watching[unit:GetId()])) then
		--Print("Destroying")
		self.watching[unit:GetId()] = nil
		--self.toplant = 0
		--self.wndMain:Close()
		--self:OnEp(true)
		--self:OnTimer()
		
	end

end



function EasyPlant:CreateUnitsFromPreload()
	for idUnit, unitNew in pairs(self.arPreloadUnits) do
	--Print("ar")
		self:OnUnitCreated(unitNew)
	end
	--self.arPreloadUnits = nil
end



function EasyPlant:DistanceToUnit(unit)
	
	local posPlayer = GameLib.GetPlayerUnit():GetPosition()
	if(posPlayer) then
		local posTarget = unit:GetPosition()
		if posTarget then
		
			local nDeltaX = posTarget.x - posPlayer.x
			local nDeltaY = posTarget.y - posPlayer.y
			local nDeltaZ = posTarget.z - posPlayer.z
			
			return math.sqrt(math.pow(nDeltaX, 2) + math.pow(nDeltaY, 2) + math.pow(nDeltaZ, 2))
		else
			return 5000
		end
	else
		return 5000
	end
end 

function EasyPlant:GetToPlantUnitId()
	for i,curunit in pairs(self.watching) do
		local distance = self:DistanceToUnit(curunit["unit"])
		local curtime = GameLib.GetGameTime()
		--Print (i)
		if(distance<30 and (curunit["blocktime"] == nil or curtime-curunit["blocktime"]>1)) then
			return i
			
			
		end
	end
	return 0

end

function EasyPlant:OnTimer()
	local toplant = self:GetToPlantUnitId()
	if(toplant>0) then
		self.toplant=toplant
		self:OnEp(false)
	else
		self.wndMain:Close()
	end

	--Print("timer")
end


-----------------------------------------------------------------------------------------------
-- EasyPlant Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here


-----------------------------------------------------------------------------------------------
-- EasyPlantForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked


function EasyPlant:OnGenerateTooltip(wndControl, wndHandler, tType, item)
	
	if wndControl ~= wndHandler then return end
	wndControl:SetTooltipDoc(nil)
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		-- Tooltip.GetItemTooltipForm(self, wndControl, itemEquipped, {bPrimary = false, bSelling = false, itemCompare = item})
	end
end

-----------------------------------------------------------------------------------------------
-- EasyPlant Instance
-----------------------------------------------------------------------------------------------
EasyPlantInst = EasyPlant:new()
EasyPlantInst:Init()
