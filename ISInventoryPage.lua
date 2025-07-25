-- THIS IS A MODDER'S CUSTOM FILE --
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "Definitions/ContainerButtonIcons"
require "defines"

ISInventoryPage = ISPanel:derive("ISInventoryPage")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
ISInventoryPage.bagSoundDelay = 0
ISInventoryPage.bagSoundTime = 0

local TurnOnOff = {
	ClothingDryer = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleClothingDryer:new(getPlayer(), object))
            end
		end
	},
	ClothingWasher = {
		isPowered = function(object)
			if object:getFluidAmount() <= 0 then return false end
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleClothingWasher:new(getPlayer(), object))
            end
		end
	},
	CombinationWasherDryer = {
		isPowered = function(object)
			if object:isModeWasher() and (object:getFluidAmount() <= 0) then return false end
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleComboWasherDryer:new(getPlayer(), object))
            end
		end
	},
	Stove = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:Activated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleStoveAction:new(getPlayer(), object))
            end
		end
	}
}

-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPage:initialise()
	ISPanel.initialise(self)
end

function ISInventoryPage:onChangeFilter(selected)

end

function ISInventoryPage:titleBarHeight(selected)
	return math.max(16, math.floor(self.titleFontHgt * 1.2))
end

function ISInventoryPage.loadWeight(inv)
    if inv == nil then return 0 end
	return inv:getCapacityWeight()
end

function ISInventoryPage:new (x, y, width, height, inventory, onCharacter, zoom)
	local o = {}
	o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:noBackground()
	o.x = x
	o.y = y
	o.width = width
	o.height = height
    o.padding = math.ceil(FONT_HGT_SMALL * 0.2)
    o.titleButtonHeight = math.floor(FONT_HGT_SMALL)
    o.backpackChoice = 1
    o.zoom = zoom
    o.isCollapsed = true
    if o.zoom == nil then o.zoom = 1 end

	o.inventory = inventory
    o.onCharacter = onCharacter
    o.titlebarbkg_CleanUI = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/CUI_TitleBarBG.png")
    o.mainbackground= {
        Left = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBackground_L.png"),
        Right = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBackground_R.png")
    }
    o.mainborder= {
        Left = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBorder_L.png"),
        Right = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBorder_R.png")
    }
    o.ContainerAreaBG = {
        Left = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/ContainerButtonArea_L.png"),
        Right = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/ContainerButtonArea_R.png")
    }
    o.containerBtnTex = {
        BG = getTexture("media/ui/CleanUI/Button/ContainerBtn_Normal.png"),
        Select = getTexture("media/ui/CleanUI/Button/ContainerBtn_Selected.png")
    }
    o.stoveIcon = {
        ON = getTexture("media/ui/CleanUI/ICON/Icon_StoveOn.png"),
        OFF = getTexture("media/ui/CleanUI/ICON/Icon_StoveOff.png")
    }
    o.removeAllIcon = getTexture("media/ui/CleanUI/ICON/Icon_RemoveAll.png")
    o.resizeimage = getTexture("media/ui/CleanUI/ResizeIcon.png")
    o.invbasic = getTexture("media/ui/CleanUI/ICON/Icon_BasicInventory.png")
    o.conDefault = getTexture("media/ui/Container_Shelf.png")
    o.highlightColors = {r=0.98,g=0.56,b=0.11}
    o.containerIconMaps = ContainerButtonIcons

    o.pin = true
    o.isCollapsed = false
    o.backpacks = {}
    o.collapseCounter = 0
	o.title = nil
	o.titleFontHgt = math.floor(FONT_HGT_SMALL)
    local sizes = { 32, 40, 48 }
    local baseButtonSize = sizes[getCore():getOptionInventoryContainerSize()]
    local scaleMultiplier = CleanUI_getContainerButtonScaleMultiplier()
    o.buttonSize = math.floor(baseButtonSize * scaleMultiplier)
    o.iconSize = math.floor(o.buttonSize * 0.8 / 2) * 2
    o.containerButtonAreaWid = math.floor(o.buttonSize + o.padding * 2)

	local font = getCore():getOptionInventoryFont()
	if font == "Large" then
		o.inventoryPanefont = UIFont.Large
	elseif font == "Small" then
		o.inventoryPanefont = UIFont.Small
	else
		o.inventoryPanefont = UIFont.Medium
	end
    if zoom > 1.5 then
        o.inventoryPanefont = UIFont.Large
    end
    o.inventoryPanefontHgt = getTextManager():getFontFromEnum(o.inventoryPanefont):getLineHeight()
    o.functionalPanelHeight = math.floor(o.inventoryPanefontHgt*1.6)

    o.visibleTarget = o
    o.visibleFunction = ISInventoryPage.onToggleVisible
    o.disableJoypadNavigation = true
   return o
end

-- ---------------------------------------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPage:createChildren()
    self.minimumHeight = self:titleBarHeight() + 1 + 100
    self.minimumWidth = 256 + self.containerButtonAreaWid
    local titleBarHeight = self:titleBarHeight()
    self.render3DItemRot = 0

    local inventoryPaneX = self:isPageLeft() and self.containerButtonAreaWid + 1 or 0
    local inventoryPaneWidth = self.width - self.containerButtonAreaWid - 1

    -- Inventorypane
    local inventoryPaneY = titleBarHeight + 1 + self.functionalPanelHeight
    local inventoryPaneHeight = self.height - titleBarHeight - 1 - self.functionalPanelHeight
    local panel2 = ISInventoryPane:new(inventoryPaneX, inventoryPaneY, inventoryPaneWidth, inventoryPaneHeight, self.inventory, self.zoom)
    panel2.anchorBottom = true
    panel2.anchorRight = true
    panel2.player = self.player
    panel2:initialise()
    panel2:setMode("details")
    panel2.inventoryPage = self
    self:addChild(panel2)
    self.inventoryPane = panel2

    -- FuctionalPanel
    self.fuctionalPanel = FuctionalPanel:new(inventoryPaneX, titleBarHeight + 1, inventoryPaneWidth, self.functionalPanelHeight, self)
    self.fuctionalPanel:initialise()
    self:addChild(self.fuctionalPanel)

    -- transferAll
    self.transferAll = CleanUI_LongButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonHeight) / 2), 50, self.titleButtonHeight, "", self, ISInventoryPage.transferAll)
    self.transferAll:initialise()
    self:addChild(self.transferAll)
    self.transferAll:setVisible(false)

    if not self.onCharacter then
        -- lootAll
        self.lootAll = CleanUI_LongButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonHeight) / 2), 50, self.titleButtonHeight, "", self, ISInventoryPage.lootAll)
        self.lootAll:initialise()
        self:addChild(self.lootAll)
        self.lootAll:setVisible(false)

        -- removeAll
        self.removeAll = ISButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonHeight) / 2), self.titleButtonHeight*2, self.titleButtonHeight, "", self, ISInventoryPage.removeAll)
        self.removeAll:initialise()
        self.removeAll.prerender = function()
            local brightness = self.removeAll:isMouseOver() and 0.9 or 0.6
            self.removeAll:drawTextureScaled(self.removeAllIcon, 0, 0, self.titleButtonHeight*2, self.titleButtonHeight, 1, brightness, brightness, brightness)
        end
        self:addChild(self.removeAll)
        self.removeAll:setVisible(false)

        -- toggleStove
        self.toggleStove = ISButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonHeight) / 2), self.titleButtonHeight*2, self.titleButtonHeight, "", self, ISInventoryPage.toggleStove)
        self.toggleStove:initialise()
        self.toggleStove.prerender = function()
            local stove = self.inventoryPane.inventory:getParent()
            if stove then
                local className = stove:getObjectName()
                if TurnOnOff[className] and TurnOnOff[className].isActivated(stove) then
                    self.toggleStove:drawTextureScaled(self.stoveIcon.ON, 0, 0, self.titleButtonHeight*2, self.titleButtonHeight, 1, 1, 1, 1)
                else
                    self.toggleStove:drawTextureScaled(self.stoveIcon.OFF, 0, 0, self.titleButtonHeight*2, self.titleButtonHeight, 1, 1, 1, 1)
                end
            end
        end
        self:addChild(self.toggleStove)
        self.toggleStove:setVisible(false)
    end

    -- resizeWidget
    local rh = math.floor(FONT_HGT_SMALL * 0.8)
	local resizeWidget = ISResizeWidget:new(self.width-rh, self.height-rh, rh, rh, self)
    resizeWidget.anchorRight = true
    resizeWidget.anchorBottom = true
	resizeWidget:initialise()
	self:addChild(resizeWidget)
    resizeWidget:setAlwaysOnTop(true)
	self.resizeWidget = resizeWidget

    -- Close Button
    self.closeButton = CleanUI_SquareButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonHeight) / 2), self.titleButtonHeight, getTexture("media/ui/CleanUI/ICON/Icon_Close.png"), self, ISInventoryPage.close)
    self.closeButton:initialise()
    self.closeButton:setActive(true)
    self.closeButton:setActiveColor(0.8, 0.2, 0.2)
    self:addChild(self.closeButton)
    if getCore():getGameMode() == "Tutorial" then
        self.closeButton:setVisible(false)
    end

    -- Info Button
    self.infoButton = ISButton:new(0, 0, self.titleButtonHeight, self.titleButtonHeight, "", self, ISInventoryPage.onInfo)
    self.infoButton:initialise()
    self:addChild(self.infoButton)
    self.infoButton:setVisible(false)

    -- Pin Button
    self.pinButton = CleanUI_SquareButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonHeight) / 2), self.titleButtonHeight, getTexture("media/ui/CleanUI/ICON/Icon_RightArrow.png"), self, ISInventoryPage.setPinned)
    self.pinButton:initialise()
    self:addChild(self.pinButton)
    self.pinButton:setVisible(false)

    -- Collapse Button
    self.collapseButton = CleanUI_SquareButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonHeight) / 2), self.titleButtonHeight, getTexture("media/ui/CleanUI/ICON/Icon_DownArrow.png"), self, ISInventoryPage.collapse)
    self.collapseButton:initialise()
    self.collapseButton:setActive(true)
    self:addChild(self.collapseButton)
    if getCore():getGameMode() == "Tutorial" then
        self.collapseButton:setVisible(false)
    end


	self.totalWeight = ISInventoryPage.loadWeight(self.inventory)
	self.totalItems = 0
    self:refreshBackpacks()
    self:collapse()
    self:setPagelocked()
end

-- ---------------------------------------------------------------------------------------- --
-- InventoryPage Button Function
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPage:lootAll()
    self.inventoryPane:lootAll()
end

function ISInventoryPage:transferAll()
    self.inventoryPane:transferAll()
end

function ISInventoryPage:toggleStove()
	if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
		return
	end

	local object = self.inventoryPane.inventory:getParent()
	if not object then return end
	local className = object:getObjectName()
	TurnOnOff[className].toggle(object)
end

function ISInventoryPage:syncToggleStove()
	if self.onCharacter then return end
	local isVisible = self.toggleStove:getIsVisible()
	local shouldBeVisible = false
	local stove = nil
	if self.inventoryPane.inventory then
		stove = self.inventoryPane.inventory:getParent()
		if stove then
			local className = stove:getObjectName()
			if TurnOnOff[className] and TurnOnOff[className].isPowered(stove) then
				shouldBeVisible = true
			end
		end
	end
	local containerButton
	for _,cb in ipairs(self.backpacks) do
		if cb.inventory == self.inventoryPane.inventory then
			containerButton = cb
			break
		end
	end
	if not containerButton then
		shouldBeVisible = false
	end
	if isVisible ~= shouldBeVisible and getCore():getGameMode() ~= "Tutorial" then
		self.toggleStove:setVisible(shouldBeVisible)
	end
end

function ISInventoryPage:setInfo(text)
    self.infoText = text
end

function ISInventoryPage:onInfo()
end

function ISInventoryPage:collapse()
    if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
        return
    end
    self.pin = false
    self.collapseButton:setVisible(false)
    self.pinButton:setVisible(true)
    self.pinButton:bringToTop()
    self.inventoryPane:clearWorldObjectHighlights()
end

function ISInventoryPage:setPinned()
    self.pin = true
    self.collapseButton:setVisible(true)
    self.pinButton:setVisible(false)
    self.collapseButton:bringToTop()
end

function ISInventoryPage:isRemoveButtonVisible()
	if self.onCharacter then return false end
	if self.inventory:isEmpty() then return false end
	if isClient() and not getServerOptions():getBoolean("TrashDeleteAll") then return false end
	local obj = self.inventory:getParent()
	if not instanceof(obj, "IsoObject") then return false end
	local sprite = obj:getSprite()
	return sprite and sprite:getProperties() and sprite:getProperties():Is("IsTrashCan")
end

function ISInventoryPage:close()
	ISPanel.close(self)
	if JoypadState.players[self.player+1] then
		setJoypadFocus(self.player, nil)
		local playerObj = getSpecificPlayer(self.player)
		playerObj:setBannedAttacking(false)
	end
    self.inventoryPane:clearWorldObjectHighlights()
end
-- ---------------------------------------------------------------------------------------- --
-- Container Highlight & Select
-- ---------------------------------------------------------------------------------------- --

local ObjectsHighlightedElsewhere = {}
ObjectsHighlightedElsewhere[1] = {}
ObjectsHighlightedElsewhere[2] = {}
ObjectsHighlightedElsewhere[3] = {}
ObjectsHighlightedElsewhere[4] = {}
function ISInventoryPage.OnObjectHighlighted(playerNum, object, isHighlighted)
    ObjectsHighlightedElsewhere[playerNum+1][object] = isHighlighted or nil
    local pdata = getPlayerData(playerNum)
    if pdata then
        pdata.playerInventory:updateContainerHighlight()
        pdata.lootInventory:updateContainerHighlight()
    end
end

function ISInventoryPage:getContainerParent(container)
    if not container then return nil end
    if container:getParent() then return container:getParent() end
    local item = container:getContainingItem()
    if item and item:getWorldItem() then
        return item:getWorldItem()
    end
    return nil
end

function ISInventoryPage:updateContainerHighlight()
    local coloredObj = self:getContainerParent(self.coloredInv)
    if coloredObj and ((self.inventory ~= self.coloredInv) or self.isCollapsed) then
        if ObjectsHighlightedElsewhere[self.player+1][coloredObj] then
        elseif coloredObj then
            coloredObj:setHighlighted(self.player, false)
            coloredObj:setOutlineHighlight(self.player, false)
            coloredObj:setOutlineHlAttached(self.player, false)
        end
        self.coloredInv = nil
    end

    coloredObj = self:getContainerParent(self.inventory)
    if ObjectsHighlightedElsewhere[self.player+1][coloredObj] then
    elseif not self.isCollapsed then
        if coloredObj and ((not instanceof(coloredObj, "IsoPlayer")) or instanceof(coloredObj, "IsoDeadBody")) then
            coloredObj:setHighlighted(self.player, true, false)
            if getCore():getOptionDoContainerOutline() then
                coloredObj:setOutlineHighlight(self.player, true)
                coloredObj:setOutlineHlAttached(self.player, true)
                coloredObj:setOutlineHighlightCol(self.player, getCore():getObjectHighlitedColor():getR(), getCore():getObjectHighlitedColor():getG(), getCore():getObjectHighlitedColor():getB(), 1)
            end
            coloredObj:setHighlightColor(self.player, getCore():getObjectHighlitedColor())
            self.coloredInv = self.inventory
        end
    end
end

function ISInventoryPage:setBlinkingContainer(blinking, containerType)
    --[[
	if blinking then
		self.blinkContainer = true
		self.blinkContainerType = containerType
	else
		self.blinkContainer = false
		self.blinkContainerType = nil
		for i,v in ipairs(self.backpacks) do
			if v.inventory == self.inventoryPane.inventory then
				v:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
			else
				v:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
			end
		end
	end
    ]]
end

function ISInventoryPage:setForceSelectedContainer(container, ms)
	self.forceSelectedContainer = container
	self.forceSelectedContainerTime = getTimestampMs() + (ms or 1000)
end

function ISInventoryPage:drawTextRight(str, x, y, r, g, b, a, font)
    if self.javaObject ~= nil and str ~= nil then
        if font ~= nil then
            self.javaObject:DrawTextRight(font, str, x, y, r, g, b, a)
        else
            self.javaObject:DrawTextRight(UIFont.Small, str, x, y, r, g, b, a)
        end
    end
end

function ISInventoryPage:drawText(str, x, y, r, g, b, a, font)
    if self.javaObject ~= nil then
        if font ~= nil then
            self.javaObject:DrawText(font, str, x, y, r, g, b, a)
        else
            self.javaObject:DrawText(UIFont.Small, str, x, y, r, g, b, a)
        end
    end
end

function ISInventoryPage:onToggleVisible()
    self.inventoryPane:clearWorldObjectHighlights()
end

function ISInventoryPage:onLoseJoypadFocus(joypadData)
    ISPanel.onLoseJoypadFocus(self, joypadData)

    self.inventoryPane.doController = false
    local inv = getPlayerInventory(self.player)
	if not inv then
        return
    end
    local loot = getPlayerLoot(self.player)
    if inv.joyfocus or loot.joyfocus then
        return
    end

    if getFocusForPlayer(self.player) == nil then
        inv:setVisible(false)
        loot:setVisible(false)
        local playerObj = getSpecificPlayer(self.player)
        playerObj:setBannedAttacking(false)
        if playerObj:getVehicle() and playerObj:getVehicle():isDriver(playerObj) then
            getPlayerVehicleDashboard(self.player):addToUIManager()
        end
    end
end

function ISInventoryPage:onGainJoypadFocus(joypadData)
    ISPanel.onGainJoypadFocus(self, joypadData)

    local inv = getPlayerInventory(self.player)
    local loot = getPlayerLoot(self.player)
    inv:setVisible(true)
    loot:setVisible(true)
    getPlayerVehicleDashboard(self.player):removeFromUIManager()
    self.inventoryPane.doController = true
end

function ISInventoryPage:onJoypadDown(button)
    ISContextMenu.globalPlayerContext = self.player
    local playerObj = getSpecificPlayer(self.player)
    
    if button == Joypad.AButton then
        self.inventoryPane:doContextOnJoypadSelected()
    end

    if button == Joypad.BButton then
        if isPlayerDoingActionThatCanBeCancelled(playerObj) then
            stopDoingActionThatCanBeCancelled(playerObj)
            return
        end
        self.inventoryPane:doJoypadExpandCollapse()
    end
    if button == Joypad.XButton and not JoypadState.disableGrab then
        self.inventoryPane:doGrabOnJoypadSelected()
    end
    if button == Joypad.YButton and not JoypadState.disableYInventory then
        setJoypadFocus(self.player, nil)
    end
    local shoulderSwitch = getCore():getOptionShoulderButtonContainerSwitch()
    if getCore():getGameMode() == "Tutorial" then shoulderSwitch = 1 end
    if button == Joypad.LBumper then
        if shoulderSwitch == 1 then
            getPlayerInventory(self.player):selectNextContainer()
        elseif shoulderSwitch == 2 then
            self:selectPrevContainer()
        elseif shoulderSwitch == 3 then
            setJoypadFocus(self.player, getPlayerInventory(self.player))
        end
    end
    if button == Joypad.RBumper then
        if shoulderSwitch == 1 then
            getPlayerLoot(self.player):selectNextContainer()
        elseif shoulderSwitch == 2 then
            self:selectNextContainer()
        elseif shoulderSwitch == 3 then
            setJoypadFocus(self.player, getPlayerLoot(self.player))
        end
    end
end

function ISInventoryPage:onJoypadDirUp(joypadData)
    local shoulderSwitch = getCore():getOptionShoulderButtonContainerSwitch()
    if shoulderSwitch == 3 then
        if isJoypadPressed(joypadData.id, Joypad.LBumper) then
            getPlayerInventory(self.player):selectPrevContainer()
            return
        end
        if isJoypadPressed(joypadData.id, Joypad.RBumper) then
            getPlayerLoot(self.player):selectPrevContainer()
            return
        end
    end
    self.inventoryPane.joyselection = self.inventoryPane.joyselection - 1
    self:ensureVisible(self.inventoryPane.joyselection + 1)
end

function ISInventoryPage:onJoypadDirDown(joypadData)
    local shoulderSwitch = getCore():getOptionShoulderButtonContainerSwitch()
    if shoulderSwitch == 3 then
        if isJoypadPressed(joypadData.id, Joypad.LBumper) then
            getPlayerInventory(self.player):selectNextContainer()
            return
        end
        if isJoypadPressed(joypadData.id, Joypad.RBumper) then
            getPlayerLoot(self.player):selectNextContainer()
            return
        end
    end
    self.inventoryPane.joyselection = self.inventoryPane.joyselection + 1
    self:ensureVisible(self.inventoryPane.joyselection + 1)
end

function ISInventoryPage:ensureVisible(index)
	local lb = self.inventoryPane
    if index < 1 then index = #lb.items end
    if index > #lb.items then index = 1 end
    local headerHgt = 17
    local y = headerHgt + lb.itemHgt * (index - 1)
    local height = lb.itemHgt
	if y < 0-lb:getYScroll() + headerHgt then
		lb:setYScroll(0 - y + headerHgt)
	elseif y + height > 0 - lb:getYScroll() + (lb.height - headerHgt) then
		lb:setYScroll(0 - (y + height - lb.height))
	end
end

function ISInventoryPage:onJoypadDirLeft()
    local inv = getPlayerInventory(self.player)
    local loot = getPlayerLoot(self.player)

    if self == loot then
        setJoypadFocus(self.player, inv)
    elseif self == inv then
        setJoypadFocus(self.player, loot)
    end
end

function ISInventoryPage:onJoypadDirRight()
    local inv = getPlayerInventory(self.player)
    local loot = getPlayerLoot(self.player)

    if self == loot then
        setJoypadFocus(self.player, inv)
    elseif self == inv then
        setJoypadFocus(self.player, loot)
    end
end

-- ---------------------------------------------------------------------------------------- --
-- ISButton:onMouseMove
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPage:onMouseMove(dx, dy)
	self.mouseOver = true

    if self.moving and self:isPagelocked() then
        self.moving = false
        return
    end

	if self.moving then
		self:setX(self.x + dx)
		self:setY(self.y + dy)
    end

    if not isGamePaused() then
        if self.isCollapsed and self.player and getSpecificPlayer(self.player) and getSpecificPlayer(self.player):isAiming() then
            return
        end
    end

    if self.isCollapsed and isKeyDown("PanCamera") then
        return
    end

    if not isMouseButtonDown(0) and not isMouseButtonDown(1) and not isMouseButtonDown(2) then

        self.collapseCounter = 0
        if self.isCollapsed and self:getMouseY() < self:titleBarHeight() then
           self.isCollapsed = false
		   	if isClient() and not self.onCharacter then
				self.inventoryPane.inventory:requestSync()
			end
           self:clearMaxDrawHeight()
           self.collapseCounter = 0
        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- ISButton:onMouseMoveOutside
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPage:onMouseMoveOutside(dx, dy)
	self.mouseOver = false

    if self.moving and self:isPagelocked() then
        self.moving = false
        self:setCapture(false)
        return
    end

	if self.moving then
		self:setX(self.x + dx)
		self:setY(self.y + dy)
    end

    if ISMouseDrag.dragging ~= true and not self.pin and (self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) then
        self.collapseCounter = self.collapseCounter + getGameTime():getMultiplier() / getGameTime():getTrueMultiplier() / 0.8
        local bDo = false
        if ISMouseDrag.dragging == nil then
            bDo = true
        else
            for i, k in ipairs(ISMouseDrag.dragging) do
               bDo = true
               break
            end
        end
        local playerObj = getSpecificPlayer(self.player)
        if playerObj and playerObj:isAiming() then
            self.collapseCounter = 1000
        end
        if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
            bDo = false
        end
        if self.collapseCounter > 120 and not self.isCollapsed and bDo then

            self.isCollapsed = true
            self:setMaxDrawHeight(self:titleBarHeight())

        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- ISButton:onMouseUp
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPage:onMouseUp(x, y)
	if not self:getIsVisible() then
		return
	end
	self.moving = false
	self:setCapture(false)
end

function ISInventoryPage:onMouseDown(x, y)
	if not self:getIsVisible() then return end

    if self:isPagelocked() then return end

	getSpecificPlayer(self.player):nullifyAiming()

	self.downX = self:getMouseX()
	self.downY = self:getMouseY()
	self.moving = true
	self:setCapture(true)
end

function ISInventoryPage:onRightMouseDownOutside(x, y)
    if((self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) and  not self.pin) then
        self.isCollapsed = true
        self:setMaxDrawHeight(self:titleBarHeight())
    end
end
function ISInventoryPage:onMouseDownOutside(x, y)
    if((self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) and  not self.pin) then
        self.isCollapsed = true
        self:setMaxDrawHeight(self:titleBarHeight())
    end
end

function ISInventoryPage:onMouseUpOutside(x, y)
	if not self:getIsVisible() then
		return
	end
	self.moving = false
	self:setCapture(false)
end

function ISInventoryPage:isCycleContainerKeyDown()
	local keyName = getCore():getOptionCycleContainerKey()
	if keyName == "control" then
		return isCtrlKeyDown()
	end
	if keyName == "shift" then
		return isShiftKeyDown()
	end
	if keyName == "control+shift" then
		return isCtrlKeyDown() and isShiftKeyDown()
	end
	if keyName == "command" then
		return isMetaKeyDown()
	end
	if keyName == "command+shift" then
		return isMetaKeyDown() and isShiftKeyDown()
	end
	error "unknown cycle container key"
end

function ISInventoryPage:onMouseWheel(del)
    local inContainerArea = false
    if self:isPageLeft() then
        inContainerArea = self:getMouseX() < self.containerButtonAreaWid
    else
        inContainerArea = self:getMouseX() >= (self:getWidth() - self.containerButtonAreaWid)
    end

    if not inContainerArea and not self:isCycleContainerKeyDown() then
        return false
    end

	local currentIndex = self:getCurrentBackpackIndex()
	local unlockedIndex = -1
	if del < 0 then
		unlockedIndex = self:prevUnlockedContainer(currentIndex, true)
	else
		unlockedIndex = self:nextUnlockedContainer(currentIndex, true)
	end
	if unlockedIndex ~= -1 then
		local playerObj = getSpecificPlayer(self.player)
		if playerObj and playerObj:getJoypadBind() ~= -1 then
			self.backpackChoice = unlockedIndex
		end
		self:selectContainer(self.backpacks[unlockedIndex])
	end
	return true
end

ISInventoryPage.dirtyUI = function ()
	for i=0, getNumActivePlayers() -1 do
		local pdata = getPlayerData(i)
		if pdata and pdata.playerInventory then
			pdata.playerInventory:refreshBackpacks()
			pdata.lootInventory:refreshBackpacks()
		end
	end
end

local sqsContainers = {}
local sqsVehicles = {}

function ISInventoryPage:checkExplored(container, playerObj)
	if container:isExplored() then
		return
	end
	if isClient() then
		container:requestServerItemsForContainer()
	else
		ItemPicker.fillContainer(container, playerObj)
	end
	container:setExplored(true)
	if playerObj and playerObj:isLocalPlayer() then
		playerObj:triggerMusicIntensityEvent("SearchNewContainer")
	end
end

function ISInventoryPage.GetFloorContainer(playerNum)
	if ISInventoryPage.floorContainer == nil then
		ISInventoryPage.floorContainer = {}
	end
	if ISInventoryPage.floorContainer[playerNum+1] == nil then
		ISInventoryPage.floorContainer[playerNum+1] = ItemContainer.new("floor", nil, nil)
		ISInventoryPage.floorContainer[playerNum+1]:setExplored(true)
	end
	return ISInventoryPage.floorContainer[playerNum+1]
end

function ISInventoryPage:refreshBackpacks()
    ISHandCraftPanel.drawDirty = true
    ISBuildPanel.drawDirty = true

	self.buttonPool = self.buttonPool or {}
	for i,v in ipairs(self.backpacks) do
		self:removeChild(v)
		table.insert(self.buttonPool, i, v)
	end

	local floorContainer = ISInventoryPage.GetFloorContainer(self.player)

	self.inventoryPane.lastinventory = self.inventoryPane.inventory

	self.inventoryPane:hideButtons()

	local oldNumBackpacks = #self.backpacks
	table.wipe(self.backpacks)

	local containerButton = nil

	local playerObj = getSpecificPlayer(self.player)

	triggerEvent("OnRefreshInventoryWindowContainers", self, "begin")

	if self.onCharacter then
		local name = getText("IGUI_InventoryTooltip")
		containerButton = self:addContainerButton(playerObj:getInventory(), self.invbasic, name, nil)
		containerButton.capacity = self.inventory:getMaxWeight()
		if not self.capacity then
			self.capacity = containerButton.capacity
		end
		local it = playerObj:getInventory():getItems()
		for i = 0, it:size()-1 do
			local item = it:get(i)
			if item:getCategory() == "Container" and playerObj:isEquipped(item) or item:getType() == "KeyRing"  or item:hasTag( "KeyRing") then
				containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
				if(item:getVisual() and item:getClothingItem()) then
					local tint = item:getVisual():getTint(item:getClothingItem())
					containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
				end
			end
		end
	elseif playerObj:getVehicle() then
		local vehicle = playerObj:getVehicle()
		for partIndex=1,vehicle:getPartCount() do
			local vehiclePart = vehicle:getPartByIndex(partIndex-1)
			if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) and vehiclePart:getId() ~= "TruckBed" then
				local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
				self:checkExplored(containerButton.inventory, playerObj)
                if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
                    local it = vehiclePart:getItemContainer():getItems()
                    for i = 0, it:size()-1 do
                        local item = it:get(i)
                        if item:getCategory() == "Container"  then
                            containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
                            if(item:getVisual() and item:getClothingItem()) then
                                local tint = item:getVisual():getTint(item:getClothingItem())
                                containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                            end
                        end
                    end
                end
			end
	    end
		for partIndex=1,vehicle:getPartCount() do
			local vehiclePart = vehicle:getPartByIndex(partIndex-1)
			if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) and vehiclePart:getId() == "TruckBed" then
				local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
				self:checkExplored(containerButton.inventory, playerObj)
                if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
                    local it = vehiclePart:getItemContainer():getItems()
                    for i = 0, it:size()-1 do
                        local item = it:get(i)
                        if item:getCategory() == "Container"  then
                            containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
                            if(item:getVisual() and item:getClothingItem()) then
                                local tint = item:getVisual():getTint(item:getClothingItem())
                                containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                            end
                        end
                    end
                end
			end
		end
	else
		local cx = playerObj:getX()
		local cy = playerObj:getY()
		local cz = playerObj:getZ()

		-- Do floor
		local container = floorContainer
		container:removeItemsFromProcessItems()
		container:clear()

		local sqs = sqsContainers
		table.wipe(sqs)

		local dir = playerObj:getDir()
		local lookSquare = nil
		if self.lookDir ~= dir then
			self.lookDir = dir
			local dx,dy = 0,0
			if dir == IsoDirections.NW or dir == IsoDirections.W or dir == IsoDirections.SW then
				dx = -1
			end
			if dir == IsoDirections.NE or dir == IsoDirections.E or dir == IsoDirections.SE then
				dx = 1
			end
			if dir == IsoDirections.NW or dir == IsoDirections.N or dir == IsoDirections.NE then
				dy = -1
			end
			if dir == IsoDirections.SW or dir == IsoDirections.S or dir == IsoDirections.SE then
				dy = 1
			end
			lookSquare = getCell():getGridSquare(cx + dx, cy + dy, cz)
		end

		local vehicleContainers = sqsVehicles
		table.wipe(vehicleContainers)

		for dy=-1,1 do
			for dx=-1,1 do
				local square = getCell():getGridSquare(cx + dx, cy + dy, cz)
				if square then
					table.insert(sqs, square)
				end
			end
		end

		for _,gs in ipairs(sqs) do
			local currentSq = playerObj:getCurrentSquare()
            if gs ~= currentSq and currentSq and not currentSq:canReachTo(gs) then
				gs = nil
			end
            if gs then
                if isClient() and not SafeHouse.isSafehouseAllowLoot(gs, playerObj) then
                    gs = nil
                end
            end

			if gs ~= nil then
				local numButtons = #self.backpacks

				local wobs = gs:getWorldObjects()
				for i = 0, wobs:size()-1 do
					local o = wobs:get(i)
					-- FIXME: An item can be in only one container in coop the item won't be displayed for every player.
					floorContainer:AddItem(o:getItem())
					if o:getItem() and o:getItem():getCategory() == "Container" then
						local item = o:getItem()
						containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
						if item:getVisual() and item:getClothingItem() then
							local tint = item:getVisual():getTint(item:getClothingItem())
							containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
						end
					end
				end

				local sobs = gs:getStaticMovingObjects()
				for i = 0, sobs:size()-1 do
					local so = sobs:get(i)
					if so:getContainer() ~= nil then
					    if getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) == nil and isDebugEnabled() then
					        print("Missing IGUI_ContainerTitle_ tranlastion string for " .. tostring(so:getContainer():getType()))
					    end

						local title = getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) or "!Needs IGUI_ContainerTitle defined for: " .. so:getContainer():getType()
                        if instanceof(so, "IsoDeadBody") and so:isAnimal() then
                            break
                        end
						containerButton = self:addContainerButton(so:getContainer(), nil, title, title)
						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local obs = gs:getObjects()
				for i = 0, obs:size()-1 do
					local o = obs:get(i)
					for containerIndex = 1,o:getContainerCount() do
						local container = o:getContainerByIndex(containerIndex-1)
					    if getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) == nil and isDebugEnabled() then
					        print("Missing IGUI_ContainerTitle_ translation string for " .. tostring(container:getType()))
					    end
						local title = getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) or "!Needs IGUI_ContainerTitle defined for: " .. container:getType()
						containerButton = self:addContainerButton(container, nil, title, title)
						if instanceof(o, "IsoThumpable") and o:isLockedToCharacter(playerObj) then
							containerButton.onclick = nil
							containerButton.onmousedown = nil
							containerButton:setOnMouseOverFunction(nil)
							containerButton:setOnMouseOutFunction(nil)
							containerButton.textureOverride = getTexture("media/ui/lock.png")
						end

						if instanceof(o, "IsoThumpable") and o:isLockedByPadlock() and playerObj:getInventory():haveThisKeyId(o:getKeyId()) then
							containerButton.textureOverride = getTexture("media/ui/lockOpen.png")
						end

						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local vehicle = gs:getVehicleContainer()
				if vehicle and not vehicleContainers[vehicle] then
					vehicleContainers[vehicle] = true
					for partIndex=1,vehicle:getPartCount() do
						local vehiclePart = vehicle:getPartByIndex(partIndex-1)
						if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) then
							local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
							containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
							self:checkExplored(containerButton.inventory, playerObj)
                            if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
                                local it = vehiclePart:getItemContainer():getItems()
                                for i = 0, it:size()-1 do
                                    local item = it:get(i)
                                    if item:getCategory() == "Container"  then
                                        containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
                                        if(item:getVisual() and item:getClothingItem()) then
                                            local tint = item:getVisual():getTint(item:getClothingItem())
                                            containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                                        end
                                    end
                                end
                            end
						end
					end
				end

				if (numButtons < #self.backpacks) and (gs == lookSquare) then
					self.inventoryPane.inventory = self.backpacks[numButtons + 1].inventory
				end
			end
		end

		triggerEvent("OnRefreshInventoryWindowContainers", self, "beforeFloor")

		local title = getTextOrNull("IGUI_ContainerTitle_floor") or ""
		containerButton = self:addContainerButton(floorContainer, ContainerButtonIcons.floor, title, nil)
		containerButton.capacity = floorContainer:getMaxWeight()
	end

	triggerEvent("OnRefreshInventoryWindowContainers", self, "buttonsAdded")

	local found = false
	local foundIndex = -1
	for index,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == self.inventoryPane.inventory then
			foundIndex = index
			found = true
			break
		end
	end

	self.inventoryPane.inventory = self.inventoryPane.lastinventory
	self.inventory = self.inventoryPane.inventory
	if self.backpackChoice ~= nil and playerObj:getJoypadBind() ~= -1 then
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.backpackChoice = 1
		end
		if self.backpackChoice > #self.backpacks then
			self.backpackChoice = 1
		end
		if self.backpacks[self.backpackChoice] ~= nil then
			self.inventoryPane.inventory = self.backpacks[self.backpackChoice].inventory
			self.capacity = self.backpacks[self.backpackChoice].capacity
		end
	else
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.inventoryPane.inventory = self.backpacks[1].inventory
			self.capacity = self.backpacks[1].capacity
		elseif found then
			self.inventoryPane.inventory = self.backpacks[foundIndex].inventory
			self.capacity = self.backpacks[foundIndex].capacity
		elseif not found and #self.backpacks > 0 then
			if self.backpacks[1] and self.backpacks[1].inventory then
				self.inventoryPane.inventory = self.backpacks[1].inventory
				self.capacity = self.backpacks[1].capacity
			end
		elseif self.inventoryPane.lastinventory ~= nil then
			self.inventoryPane.inventory = self.inventoryPane.lastinventory
		end
	end
	if self.forceSelectedContainer then
		if self.forceSelectedContainerTime > getTimestampMs() then
			for _,containerButton in ipairs(self.backpacks) do
				if containerButton.inventory == self.forceSelectedContainer then
					self.inventoryPane.inventory = containerButton.inventory
					self.capacity = containerButton.capacity
					break
				end
			end
		else
			self.forceSelectedContainer = nil
		end
	end

	self.inventoryPane:bringToTop()
	self.resizeWidget:bringToTop()

	self.inventory = self.inventoryPane.inventory

	self.title = nil
	for k,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == self.inventory then
			containerButton:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
			self.title = containerButton.name
		else
			containerButton:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
		end
	end

	if self.inventoryPane ~= nil then
		self.inventoryPane:refreshContainer()
	end

	self:refreshWeight()

	self:updateItemCount()

    self:syncToggleStove()

	triggerEvent("OnRefreshInventoryWindowContainers", self, "end")
end

function ISInventoryPage:onMouseOverButton(button,x,y)
	self.mouseOverButton = button
end

function ISInventoryPage:onMouseOutButton(button,x,y)
	self.mouseOverButton = nil
end

function ISInventoryPage:canPutIn()
    local playerObj = getSpecificPlayer(self.player)
    local container = self.mouseOverButton and self.mouseOverButton.inventory or nil
    if not container then
        return false
    end
    local items = {}
    local minWeight = 100000
    local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
    for i,item in ipairs(dragging) do
        local itemOK = true
        if item:isFavorite() and not container:isInCharacterInventory(playerObj) then
            itemOK = false
        end
        if container:isInside(item) then
            itemOK = false
        end
        if container:getType() == "floor" and item:getWorldItem() then
            itemOK = false
        end
        if item:getContainer() == container then
            itemOK = false
        end
        if not container:isItemAllowed(item) then
            itemOK = false
        end
        if itemOK then
            table.insert(items, item)
        end
        if item:getUnequippedWeight() < minWeight then
            minWeight = item:getUnequippedWeight()
        end
    end
    if #items == 1 then
        return container:hasRoomFor(playerObj, items[1])
    elseif #items > 0 then
        return container:hasRoomFor(playerObj, minWeight)
    end
    return false
end

-- ---------------------------------------------------------------------------------------- --
-- Layout Manager
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPage:setPagelocked()
    local config = CleanUIConfig.getConfig()
    local isLocked = config["lockPanel"] or false

    local playerData = getPlayerData(self.player)
    if playerData then
        local playerInventory = playerData.playerInventory
        local lootInventory = playerData.lootInventory

        if playerInventory and playerInventory.resizeWidget then
            playerInventory.resizeWidget:setVisible(not isLocked)
        end

        if lootInventory and lootInventory.resizeWidget then
            lootInventory.resizeWidget:setVisible(not isLocked)
        end
    end
end

function ISInventoryPage:isPagelocked()
    local config = CleanUIConfig.getConfig()
    return config["lockPanel"] or false
end


function ISInventoryPage:isPageLeft()
    local position = CleanUI_getContainerPosition(self)
    if position == "1" then
        return true 
    else
        return false
    end
end

function ISInventoryPage:RestoreLayout(name, layout)
    if getJoypadData(self.player) then return end
    ISLayoutManager.DefaultRestoreWindow(self, layout)
    if layout.pin == 'true' then
        self:setPinned()
    end
    self.inventoryPane:RestoreLayout(name, layout)
end

function ISInventoryPage:SaveLayout(name, layout)
    if getJoypadData(self.player) then return end
    ISLayoutManager.DefaultSaveWindow(self, layout)
    if self.pin then layout.pin = 'true' else layout.pin = 'false' end
    self.inventoryPane:SaveLayout(name, layout)
end

ISInventoryPage.onKeyPressed = function(key)
	if getCore():isKey("Toggle Inventory", key) and getSpecificPlayer(0) and getGameSpeed() > 0 and getPlayerInventory(0) and getCore():getGameMode() ~= "Tutorial" then
        getPlayerInventory(0):setVisible(not getPlayerInventory(0):getIsVisible())
        getPlayerLoot(0):setVisible(getPlayerInventory(0):getIsVisible())
    end
end

ISInventoryPage.toggleInventory = function()
	if ISInventoryPage.playerInventory:getIsVisible() then
		ISInventoryPage.playerInventory:setVisible(false)
	else
		ISInventoryPage.playerInventory:setVisible(true)
	end
end

function ISInventoryPage:onInventoryContainerSizeChanged()
    local sizes = { 32, 40, 48 }
    local baseButtonSize = sizes[getCore():getOptionInventoryContainerSize()]
    local scaleMultiplier = CleanUI_getContainerButtonScaleMultiplier()
    self.buttonSize = math.floor(baseButtonSize * scaleMultiplier)
    self.iconSize = math.floor(self.buttonSize * 0.8 / 2) * 2
    self.containerButtonAreaWid = math.floor(self.buttonSize + self.padding * 2)
    self.minimumWidth = 256 + self.buttonSize

    local inventoryPaneX = self:isPageLeft() and self.containerButtonAreaWid + 1 or 0
    self.inventoryPane:setX(inventoryPaneX)
    self.inventoryPane:setWidth(self.width - self.containerButtonAreaWid)

    self.fuctionalPanel:setX(inventoryPaneX)
    self.fuctionalPanel:setWidth(self.width - self.containerButtonAreaWid)
    
    for _,button in ipairs(self.buttonPool) do
        button:setWidth(self.buttonSize)
        button:setHeight(self.buttonSize)
        button:forceImageSize(self.iconSize, self.iconSize)
    end
    
    local y = self:titleBarHeight() + self.padding
    for _,button in ipairs(self.backpacks) do
        if self:isPageLeft() then
            button:setX((self.containerButtonAreaWid - self.buttonSize) / 2)
            button.anchorLeft = true
            button.anchorRight = false
        else
            button:setX(self.width - self.containerButtonAreaWid + (self.containerButtonAreaWid - self.buttonSize) / 2)
            button.anchorLeft = false
            button.anchorRight = true
        end
        button:setY(y)
        y = y + self.buttonSize + self.padding
        button:setWidth(self.buttonSize)
        button:setHeight(self.buttonSize)
        button:forceImageSize(self.iconSize, self.iconSize)
    end
end

ISInventoryPage.ContainerSizeChanged = function()
	for i=1,getNumActivePlayers() do
		local pdata = getPlayerData(i-1)
		if pdata then
			pdata.playerInventory:onInventoryContainerSizeChanged()
			pdata.lootInventory:onInventoryContainerSizeChanged()
		end
	end
end

ISInventoryPage.onInventoryFontChanged = function()
    for i=1,getNumActivePlayers() do
        local pdata = getPlayerData(i-1)
        if pdata then
            pdata.playerInventory.inventoryPane:onInventoryFontChanged()
            pdata.lootInventory.inventoryPane:onInventoryFontChanged()
        end
    end
end

function ISInventoryPage:removeAll()
	self.inventoryPane:removeAll(self.player)
end

-- ---------------------------------------------------------------------------------------- --
-- Container Button
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPage:dropItemsInContainer(button)
	if self.player ~= 0 then return false end
	if ISMouseDrag.dragging == nil then return false end
	local playerObj = getSpecificPlayer(self.player)
	if (getCore():getGameMode() ~= "Tutorial") and self:canPutIn() then
		local doWalk = true
		local items = {}
		local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
		for i,v in ipairs(dragging) do
			local transfer = v:getContainer() and not button.inventory:isInside(v)
			if v:isFavorite() and not button.inventory:isInCharacterInventory(playerObj) then
				transfer = false
			end
			if not button.inventory:isItemAllowed(v) then
				transfer = false
			end
			if transfer then
				if doWalk then
					if not luautils.walkToContainer(button.inventory, self.player) then
						break
					end
					doWalk = false
				end
				table.insert(items, v)
			end
		end
		self.inventoryPane:transferItemsByWeight(items, button.inventory)
		self.inventoryPane.selected = {}
		getPlayerLoot(self.player).inventoryPane.selected = {}
		getPlayerInventory(self.player).inventoryPane.selected = {}
	end
	if ISMouseDrag.draggingFocus then
		ISMouseDrag.draggingFocus:onMouseUp(0,0)
		ISMouseDrag.draggingFocus = nil
		ISMouseDrag.dragging = nil
	end
	self:refreshWeight()
    self:updateItemCount()
	return true
end

function ISInventoryPage:selectContainer(button)
	local playerObj = getSpecificPlayer(self.player)

    if button.inventory ~= self.inventoryPane.lastinventory then
        local object = button.inventory and button.inventory:getParent() or nil
        if instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
            return
        end
        if button.inventory:getOpenSound() then
            if ISInventoryPage.bagSoundTime + ISInventoryPage.bagSoundDelay < getTimestamp() then
                local eventInstance = getSpecificPlayer(self.player):playSound(button.inventory:getOpenSound())
                if eventInstance ~= 0 then
                    ISInventoryPage.bagSoundTime = getTimestamp()
                end
            end
        end

        if not button.inventory:getOpenSound() and self.inventoryPane.lastinventory:getCloseSound() then
            if ISInventoryPage.bagSoundTime + ISInventoryPage.bagSoundDelay < getTimestamp() then
                ISInventoryPage.bagSoundTime = getTimestamp()
                local eventInstance = getSpecificPlayer(self.player):playSound(self.inventoryPane.lastinventory:getCloseSound())
                if eventInstance ~= 0 then
                    ISInventoryPage.bagSoundTime = getTimestamp()
                end
            end
        end
    end

    self.inventoryPane.lastinventory = button.inventory
    self.inventoryPane.inventory = button.inventory
    self.inventoryPane.selected = {}
    if not button.inventory:isExplored() then
        if not isClient() then
			ItemPicker.fillContainer(button.inventory, playerObj)
        else
            button.inventory:requestServerItemsForContainer()
        end
        button.inventory:setExplored(true)
    end
	self.title = button.name
	self.capacity = button.capacity
    self:refreshBackpacks()
end

function ISInventoryPage:setNewContainer(inventory)
    self.inventoryPane.inventory = inventory
    self.inventory = inventory
    self.inventoryPane:refreshContainer()

    local playerObj = getSpecificPlayer(self.player)
    self.capacity = inventory:getEffectiveCapacity(playerObj)
	for i,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == inventory then
			containerButton:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
			self.title = containerButton.name
		else
			containerButton:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
		end
	end

	self:syncToggleStove()
end

function ISInventoryPage:selectButtonForContainer(container)
	if self.inventoryPane.inventory == container then
		return
	end
	for index,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == container then
            local playerObj = getSpecificPlayer(self.player)
            local object = container and container:getParent() or nil
            if instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
                return
            end
			if playerObj and playerObj:getJoypadBind() ~= -1 then
				self.backpackChoice = index
			end
			self:selectContainer(containerButton)
			return
		end
	end
end

function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
    local titleBarHeight = self:titleBarHeight()
    local playerObj = getSpecificPlayer(self.player)
    local c = #self.backpacks + 1

    local x
    if self:isPageLeft() then
        x = (self.containerButtonAreaWid - self.buttonSize) / 2
    else
        x = self.width - self.containerButtonAreaWid + (self.containerButtonAreaWid - self.buttonSize) / 2
    end
    
    local y = (c - 1) * (self.buttonSize + self.padding) + titleBarHeight + self.padding
	local button
	if #self.buttonPool > 0 then
		button = table.remove(self.buttonPool, 1)
		button:setX(x)
		button:setY(y)
	else
		button = ISButton:new(x, y, self.buttonSize, self.buttonSize, "", self, ISInventoryPage.onBackpackClick, ISInventoryPage.onBackpackMouseDown, false)
        if self:isPageLeft() then
            button.anchorLeft = true
            button.anchorRight = false
        else
            button.anchorLeft = false
            button.anchorRight = true
        end
		button:initialise()
        button:setDisplayBackground(false)
		button:forceImageSize(self.iconSize, self.iconSize)
        button.prerender = function()
            ISButton.prerender(button)
            local brightness = button:isMouseOver() and 0.9 or 0.5
            button:drawTextureScaled(self.containerBtnTex.BG, 0, 0, self.buttonSize, self.buttonSize, 0.5, brightness, brightness, brightness)
            if button.inventory == self.inventory then
                button:drawTextureScaled(self.containerBtnTex.Select, 0, 0, self.buttonSize, self.buttonSize, 0.8, 0.8, 0.8, 0.8)
            end
        end
	end
	button:setTextureRGBA(1.0, 1.0, 1.0, 1.0)
	button.textureOverride = nil
	button.inventory = container
	button.onclick = ISInventoryPage.onBackpackClick
	button.onmousedown = ISInventoryPage.onBackpackMouseDown
	button.onMouseUp = ISInventoryPage.onBackpackMouseUp
	button.onRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
	button:setOnMouseOverFunction(ISInventoryPage.onMouseOverButton)
	button:setOnMouseOutFunction(ISInventoryPage.onMouseOutButton)
	button:setSound("activate", nil)
	button.capacity = container:getEffectiveCapacity(playerObj)
	if instanceof(texture, "Texture") then
		button:setImage(texture)
    else
		if ContainerButtonIcons[container:getType()] ~= nil then
			button:setImage(ContainerButtonIcons[container:getType()])
		else
			button:setImage(self.conDefault)
		end
	end
	button.name = name
	button.tooltip = tooltip
	self:addChild(button)
	self.backpacks[c] = button
	return button
end

function ISInventoryPage:onBackpackMouseDown(button, x, y)
	ISMouseDrag = {}
	if not isKeyDown("Melee") then
	    getSpecificPlayer(self.player):nullifyAiming()
    end
end

function ISInventoryPage:onBackpackClick(button)
	local playerObj = getSpecificPlayer(self.player)
	if playerObj and playerObj:getJoypadBind() ~= -1 then
		for i,button2 in ipairs(self.backpacks) do
			if button2 == button then
				self.backpackChoice = index
				break
			end
		end
	end
	self:selectContainer(button)
end

function ISInventoryPage:onBackpackMouseUp(x, y)
	if not self.pressed and not ISMouseDrag.dragging then return end
	ISButton.onMouseUp(self, x, y)
	local page = self.parent
	if page:dropItemsInContainer(self) then return end
	page:onBackpackClick(self)
end

function ISInventoryPage:onBackpackRightMouseDown(x, y)
	local page = self.parent
	local container = self.inventory
	local item = container:getContainingItem()
	local context = ISContextMenu.get(page.player, getMouseX(), getMouseY())
	if item then
		context = ISInventoryPaneContextMenu.createMenu(page.player, page.onCharacter, {item}, getMouseX(), getMouseY())
		if context and context.numOptions > 1 and JoypadState.players[page.player+1] then
			context.origin = page
			context.mouseOver = 1
			setJoypadFocus(page.player, context)
		end
		return
	end
    if ISLootZed.cheat or isAdmin() then
        local playerObj = getSpecificPlayer(page.player)
        if not instanceof(container:getParent(), "BaseVehicle") and not (container:getType() == "inventorymale" or container:getType() == "inventoryfemale") then
            context:addOption("Refill container", container, function(container, playerObj)
                if container:getSourceGrid() then
                    if isClient() then
                        local items = container:getItems()
                        local tItems = {}
                        for i = items:size()-1, 0, -1 do
                            table.insert(tItems, items:get(i))
                        end

                        for i, v in ipairs(tItems) do
                            ISRemoveItemTool.removeItem(v, playerObj)
                        end

                        local sq = container:getSourceGrid()
                        local cIndex = -1
                        for i = 0, container:getParent():getContainerCount()-1 do
                            if container:getParent():getContainerByIndex(i) == container then
                                cIndex = i
                            end
                        end
                        local args = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = container:getParent():getObjectIndex(), containerIndex = cIndex }
                        sendClientCommand(playerObj, 'object', 'clearContainerExplore', args)
                        container:removeItemsFromProcessItems()
                        container:clear()
                        container:requestServerItemsForContainer()
                        container:setExplored(true)
                        sendClientCommand(playerObj, 'object', 'updateOverlaySprite', args)
                    else
                        if container:getSourceGrid():getRoom() and container:getSourceGrid():getRoom():getRoomDef() and container:getSourceGrid():getRoom():getRoomDef():getProceduralSpawnedContainer() then
                            container:getSourceGrid():getRoom():getRoomDef():getProceduralSpawnedContainer():clear()
                        end
                        container:removeItemsFromProcessItems()
                        container:clear()
                        ItemPicker.fillContainer(container, playerObj)
                        if container:getParent() then
                            ItemPicker.updateOverlaySprite(container:getParent())
                        end
                        container:setExplored(true)
                    end
                end
            end, playerObj)
        end
        if ISLootZed.cheat then
            context:addOption("Open LootZed", container, function(container, playerObj)
                LootZedTool.SpawnItemCheckerList = {}
                LootZedTool.fillContainer_CalcChances(container, playerObj)

                if ISLootZed.instance ~= nil then
                    ISLootZed.instance:updateContent()
                    ISLootZed.instance:setVisible(true)
                else
                    local ui = ISLootZed:new(750, 800, playerObj)
                    ui:initialise()
                    ui:addToUIManager()
                    ISLootZed.instance:updateContent()
                end
            end, playerObj)
        end
        return
    end
	if context:isReallyVisible() then
		if context and JoypadState.players[page.player+1] then
			context.origin = page
		end
		context:closeAll()
	end
end

function ISInventoryPage:getCurrentBackpackIndex()
    for index,backpack in ipairs(self.backpacks) do
        if backpack.inventory == self.inventory then
            return index
        end
    end
    return -1
end

function ISInventoryPage:prevUnlockedContainer(index, wrap)
    local playerObj = getSpecificPlayer(self.player)
    for i=index-1,1,-1 do
        local backpack = self.backpacks[i]
        local object = backpack.inventory:getParent()
        if not (instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj)) then
            return i
        end
    end
    return wrap and self:prevUnlockedContainer(#self.backpacks + 1, false) or -1
end

function ISInventoryPage:nextUnlockedContainer(index, wrap)
    if index < 0 then
        return wrap and self:nextUnlockedContainer(0, false) or -1
    end
    local playerObj = getSpecificPlayer(self.player)
    for i=index+1,#self.backpacks do
        local backpack = self.backpacks[i]
        local object = backpack.inventory:getParent()
        if not (instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj)) then
            return i
        end
    end
    return wrap and self:nextUnlockedContainer(0, false) or -1
end

function ISInventoryPage:selectPrevContainer()
    local currentIndex = self:getCurrentBackpackIndex()
    local unlockedIndex = self:prevUnlockedContainer(currentIndex, true)
    if unlockedIndex == -1 then
        return
    end
    local playerObj = getSpecificPlayer(self.player)
    if playerObj and playerObj:getJoypadBind() ~= -1 then
        self.backpackChoice = unlockedIndex
    end
    self:selectContainer(self.backpacks[unlockedIndex])
end

function ISInventoryPage:selectNextContainer()
    local currentIndex = self:getCurrentBackpackIndex()
    local unlockedIndex = self:nextUnlockedContainer(currentIndex, true)
    if unlockedIndex == -1 then
        return
    end
    local playerObj = getSpecificPlayer(self.player)
    if playerObj and playerObj:getJoypadBind() ~= -1 then
        self.backpackChoice = unlockedIndex
    end
    self:selectContainer(self.backpacks[unlockedIndex])
end
-- ---------------------------------------------------------------------------------------- --
-- Update
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPage:updateItemCount()
    self.totalItems = luautils.countItemsRecursive({luautils.findRootInventory(self.inventoryPane.inventory)})
end

function ISInventoryPage:refreshWeight()
	return
end

function ISInventoryPage:update()
    local playerObj = getSpecificPlayer(self.player)
    if self.inventory:getEffectiveCapacity(playerObj) ~= self.capacity then
        self.capacity = self.inventory:getEffectiveCapacity(playerObj)
    end

    self:updateContainerHighlight()

    if (ISMouseDrag.dragging ~= nil and #ISMouseDrag.dragging > 0) or self.pin then
        self.collapseCounter = 0
        if isClient() and self.isCollapsed then
            self.inventoryPane.inventory:requestSync()
        end
        self.isCollapsed = false
        self:clearMaxDrawHeight()
        self.collapseCounter = 0
    end

    if not self.onCharacter then
        self.removeAll:setVisible(self:isRemoveButtonVisible())

        local playerObj = getSpecificPlayer(self.player)
        if self.lastDir ~= playerObj:getDir() then
            self.lastDir = playerObj:getDir()
            self:refreshBackpacks()
        elseif self.lastSquare ~= playerObj:getCurrentSquare() then
            self.lastSquare = playerObj:getCurrentSquare()
            self:refreshBackpacks()
        end
        local object = self.inventory and self.inventory:getParent() or nil
        if #self.backpacks > 1 and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
            local currentIndex = self:getCurrentBackpackIndex()
            local unlockedIndex = self:prevUnlockedContainer(currentIndex, false)
            if unlockedIndex == -1 then
                unlockedIndex = self:nextUnlockedContainer(currentIndex, false)
            end
            if unlockedIndex ~= -1 then
                if playerObj:getJoypadBind() ~= -1 then
                    self.backpackChoice = unlockedIndex
                end
                self:selectContainer(self.backpacks[unlockedIndex])
            end
        end
    end

	self:syncToggleStove()
end

-- ---------------------------------------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPage:prerender()

    --[[
    if self.blinkContainer then
        if not self.blinkAlphaContainer then self.blinkAlphaContainer = 0.7 self.blinkAlphaIncreaseContainer = false end
        if not self.blinkAlphaIncreaseContainer then
            self.blinkAlphaContainer = self.blinkAlphaContainer - 0.04 * (UIManager.getMillisSinceLastRender() / 33.3)
            if self.blinkAlphaContainer < 0.3 then
                self.blinkAlphaContainer = 0.3
                self.blinkAlphaIncreaseContainer = true
            end
        else
            self.blinkAlphaContainer = self.blinkAlphaContainer + 0.04 * (UIManager.getMillisSinceLastRender() / 33.3)
            if self.blinkAlphaContainer > 0.7 then
                self.blinkAlphaContainer = 0.7
                self.blinkAlphaIncreaseContainer = false
            end
        end
        for i,v in ipairs(self.backpacks) do
            if (self.blinkContainerType and v.inventory:getType() == self.blinkContainerType) or not self.blinkContainerType then
                if v.inventory == self.inventoryPane.inventory then
                    v:setBackgroundRGBA(1, 0, 0, self.blinkAlphaContainer)
                else
                    v:setBackgroundRGBA(1, 0, 0, self.blinkAlphaContainer * 0.75)
                end
            end
        end
    end
    --]]

    local titleBarHeight = self:titleBarHeight()
    local height = self:getHeight()
    if self.isCollapsed then
        height = titleBarHeight
    end

    local titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/CUI_TitleBarBG.png")
    titlebarbkg:render(self:getAbsoluteX(), self:getAbsoluteY(), self:getWidth(), titleBarHeight, 0.5, 0.5, 0.5, 0.95)

    --[[
    if not self.blink then
        local titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/CUI_TitleBarBG.png")
        titlebarbkg:render(self:getAbsoluteX(), self:getAbsoluteY(), self:getWidth(), titleBarHeight, 0.5, 0.5, 0.5, 0.95)
    else
        if not self.blinkAlpha then self.blinkAlpha = 1 end

        if not self.blinkAlphaIncrease then
            self.blinkAlpha = self.blinkAlpha - 0.1 * (UIManager.getMillisSinceLastRender() / 33.3)
            if self.blinkAlpha < 0 then
                self.blinkAlpha = 0
                self.blinkAlphaIncrease = true
            end
        else
            self.blinkAlpha = self.blinkAlpha + 0.1 * (UIManager.getMillisSinceLastRender() / 33.3)
            if self.blinkAlpha > 1 then
                self.blinkAlpha = 1
                self.blinkAlphaIncrease = false
            end
        end
    end
    --]]

    if not self.isCollapsed then
        if self:isPageLeft() then
            local MainBackground = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBackground_R.png")
            local MainBorder = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBorder_R.png")
            local bgOpacity = CleanUI_getBackgroundOpacity()
            MainBackground:render(self:getAbsoluteX() + self.containerButtonAreaWid, self:getAbsoluteY() + titleBarHeight, self:getWidth() - self.containerButtonAreaWid, height - titleBarHeight, 0.05, 0.05, 0.05, bgOpacity)
            MainBorder:render(self:getAbsoluteX() + self.containerButtonAreaWid, self:getAbsoluteY() + titleBarHeight, self:getWidth() - self.containerButtonAreaWid, height - titleBarHeight, 0.8, 0.8, 0.8, bgOpacity)

            local containerbgOpacity = CleanUI_getContainerBackgroundOpacity()
            local containerAreaBG = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/ContainerButtonArea_L.png")
            containerAreaBG:render(self:getAbsoluteX(), self:getAbsoluteY() + titleBarHeight, self.containerButtonAreaWid, height - titleBarHeight, 1, 1, 1, containerbgOpacity)

            self:drawRect(0, titleBarHeight, self:getWidth(), 1, 1, 0, 0, 0)
            self:drawRect(self.containerButtonAreaWid, titleBarHeight, 1, height - titleBarHeight, 1, 0, 0, 0)
        else
            local MainBackground = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBackground_L.png")
            local MainBorder = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBorder_L.png")
            local bgOpacity = CleanUI_getBackgroundOpacity()
            MainBackground:render(self:getAbsoluteX(), self:getAbsoluteY() + titleBarHeight, self:getWidth() - self.containerButtonAreaWid, height - titleBarHeight, 0.05, 0.05, 0.05, bgOpacity)
            MainBorder:render(self:getAbsoluteX(), self:getAbsoluteY() + titleBarHeight, self:getWidth() - self.containerButtonAreaWid, height - titleBarHeight, 0.8, 0.8, 0.8, bgOpacity)

            local containerbgOpacity = CleanUI_getContainerBackgroundOpacity()
            local containerAreaBG = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/ContainerButtonArea_R.png")
            containerAreaBG:render(self:getAbsoluteX() + self:getWidth() - self.containerButtonAreaWid, self:getAbsoluteY() + titleBarHeight, self.containerButtonAreaWid, height - titleBarHeight, 1, 1, 1, containerbgOpacity)

            self:drawRect(0, titleBarHeight, self:getWidth(), 1, 1, 0, 0, 0)
            self:drawRect(self:getWidth() - self.containerButtonAreaWid, titleBarHeight, 1, height - titleBarHeight, 1, 0, 0, 0)
        end
        local rh = math.floor(FONT_HGT_SMALL * 0.4)
        local brightness = self.resizeWidget:isMouseOver() and 0.8 or 0.6
        if not self:isPagelocked() then
            self:drawTextureScaled(self.resizeimage, self:getWidth() - rh, self:getHeight() - rh, rh, rh, 1, brightness, brightness, brightness)
        end
    end

	local weightLabel
	self.totalWeight = ISInventoryPage.loadWeight(self.inventoryPane.inventory)
	local occupied
	local roundedWeight = round(self.totalWeight, 2)
	if self.capacity then
		local inventory = self.inventoryPane.inventory
		local part = inventory:getVehiclePart()
		if inventory == getSpecificPlayer(self.player):getInventory() then
			weightLabel = roundedWeight .. " / " .. getSpecificPlayer(self.player):getMaxWeight()
		elseif part and part:getId():contains("Seat") and part:getVehicle():getCharacter(part:getContainerSeatNumber()) then
			weightLabel = roundedWeight .. " / " .. (self.capacity/4)
			occupied = true
		else
			if isClient() then
				local itemLimit = getServerOptions():getInteger("ItemNumbersLimitPerContainer")
				if itemLimit > 0 then
					weightLabel = roundedWeight .. " / " .. self.capacity .. " (" .. self.totalItems .. " / " .. itemLimit .. ")"
				else
					weightLabel = roundedWeight .. " / " .. self.capacity
				end
			else
				weightLabel = roundedWeight .. " / " .. self.capacity
			end
		end
	else
		weightLabel = roundedWeight .. ""
	end

    if not self.onCharacter then
        self.transferAll:setVisible(false)
    elseif "Tutorial" ~= getCore():getGameMode() then
        self.transferAll:setVisible(true)
    end

    self.closeButton:setX(self.width - self.titleButtonHeight - self.padding)
    self.pinButton:setX(self.padding)
    self.collapseButton:setX(self.padding)

    -- transferAll Button & weightLabel
    local weightWid = math.max(getTextManager():MeasureStringX(UIFont.Small, "99 / 99"),getTextManager():MeasureStringX(UIFont.Small, weightLabel)) + self.padding*2
    local textWid = math.max(getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_invpage_Transfer_all")) + self.padding*2 , weightWid)
    if self.onCharacter and self.transferAll and self.transferAll:getIsVisible() then
        if self.transferAll:isMouseOver() then
            self.transferAll:setTitle(getText("IGUI_invpage_Transfer_all"))
            self.transferAll:setWidth(textWid)
        else
            self.transferAll:setTitle(weightLabel)
            self.transferAll:setWidth(textWid)
        end
        self.transferAll:setX(self.closeButton:getX() - self.padding - self.transferAll:getWidth())
    end
    -- lootAll Button & weightLabel
    if not self.onCharacter and self.lootAll and self.lootAll:getIsVisible() then
        if self.lootAll:isMouseOver() then
            self.lootAll:setTitle(getText("IGUI_invpage_Loot_all"))
            self.lootAll:setWidth(textWid)
        else
            self.lootAll:setTitle(weightLabel)
            self.lootAll:setWidth(textWid)
        end
        self.lootAll:setX(self.closeButton:getX() - self.padding - self.lootAll:getWidth())
    end
    
    if self.title then
        local fontHgt = self.onCharacter and FONT_HGT_SMALL or getTextManager():getFontHeight(self.font)
        local text = self.title
        if not self.onCharacter and occupied then
            text = self.title .. " " .. getText("IGUI_invpage_Occupied")
        end

        local titleStartX = self.padding + self.titleButtonHeight + self.padding
        local maxTitleWidth
        if self.onCharacter then
            local rightBoundary = self.closeButton:getX() - self.padding
            if self.transferAll and self.transferAll:getIsVisible() then
                rightBoundary = self.transferAll:getX() - self.padding
            end
            maxTitleWidth = rightBoundary - titleStartX
        else
            local rightBoundary = self.closeButton:getX() - self.padding
            if self.lootAll and self.lootAll:getIsVisible() then
                rightBoundary = self.lootAll:getX() - self.padding
            elseif self.removeAll and self.removeAll:getIsVisible() then
                local leftmostButtonX = self.closeButton:getX()
                if self.removeAll:getIsVisible() then
                    leftmostButtonX = math.min(leftmostButtonX, self.removeAll:getX())
                end
                if self.toggleStove and self.toggleStove:getIsVisible() then
                    leftmostButtonX = math.min(leftmostButtonX, self.toggleStove:getX())
                end
                rightBoundary = leftmostButtonX - self.padding
            end
            maxTitleWidth = rightBoundary - titleStartX
        end

        maxTitleWidth = math.max(maxTitleWidth, 50)

        local truncatedText = CleanUI.truncateText(text, maxTitleWidth, UIFont.Small)
        self:drawText(truncatedText, titleStartX, (titleBarHeight - fontHgt) / 2, 1, 1, 1, 1)

        if not self.onCharacter then
            local titleWidth = getTextManager():MeasureStringX(UIFont.Small, truncatedText)
            local buttonX = titleStartX + titleWidth + self.padding
            
            if self.toggleStove and self.toggleStove:getIsVisible() then
                self.toggleStove:setX(buttonX)
                buttonX = buttonX + self.toggleStove:getWidth() + self.padding
            end
            
            if self.removeAll and self.removeAll:getIsVisible() then
                self.removeAll:setX(buttonX)
            end
        end
    end
    self:setStencilRect(0,0,self.width, height)

    local playerObj = getSpecificPlayer(self.player)
    if playerObj and playerObj:isInvPageDirty() then
        playerObj:setInvPageDirty(false)
        ISInventoryPage.renderDirty = false
        ISInventoryPage.dirtyUI()
    end
    if ISInventoryPage.renderDirty then
        ISInventoryPage.renderDirty = false
        ISInventoryPage.dirtyUI()
    end
end

function ISInventoryPage:render()
    self:clearStencilRect()

    if self.joyfocus then
        self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), 0.4, 0.2, 1.0, 1.0)
        self:drawRectBorder(1, 1, self:getWidth()-2, self:getHeight()-2, 0.4, 0.2, 1.0, 1.0)
    end

    if self.render3DItems and #self.render3DItems > 0 then
        self:render3DItemPreview()
    end
end

function ISInventoryPage:render3DItemPreview()
    if isKeyDown("Rotate building") then
        if not self.render3DItemRot then
            self.render3DItemRot = 0
        end
        local rot = self.render3DItemRot
        if isKeyDown(Keyboard.KEY_LSHIFT) then
            rot = rot -10
        else
            rot = rot + 10
        end
        if rot < 0 then
            rot = 360
        end
        if rot > 360 then
            rot = 0
        end
        self.render3DItemRot = rot
    end
    local playerObj = getSpecificPlayer(self.player)
    local worldX = screenToIsoX(self.player, getMouseX(), getMouseY(), playerObj:getZ())
    local worldY = screenToIsoY(self.player, getMouseX(), getMouseY(), playerObj:getZ())
    local sq = getSquare(worldX, worldY, playerObj:getZ())
    if not sq then
        return
    end

    self.render3DItemXOffset = worldX - sq:getX()
    self.render3DItemYOffset = worldY - sq:getY()
    self.render3DItemZOffset = 0
    for i=0,sq:getObjects():size()-1 do
        local object = sq:getObjects():get(i)
        if object:getProperties():getSurface() and object:getProperties():getSurface() > 0 then
            self.render3DItemZOffset = (object:getProperties():getSurface() / 192) * 2
            break
        end
    end
    self.selectedSqDrop = sq
    if self.render3DItems then
        for i,v in ipairs(self.render3DItems) do
            Render3DItem(v, sq, worldX, worldY, self.render3DItemZOffset, self.render3DItemRot)
        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Events
-- ---------------------------------------------------------------------------------------- --

ISInventoryPage.OnContainerUpdate = function(object)
    ISInventoryPage.renderDirty = true
end

ISInventoryPage.ongamestart = function()
    ISInventoryPage.renderDirty = true
end

Events.OnKeyPressed.Add(ISInventoryPage.onKeyPressed)
Events.OnContainerUpdate.Add(ISInventoryPage.OnContainerUpdate)
Events.OnGameStart.Add(ISInventoryPage.ongamestart)
