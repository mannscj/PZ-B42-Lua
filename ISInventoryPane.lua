-- THIS IS A MODDER'S CUSTOM FILE --
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISMouseDrag"
require "ISUI/ISInventoryItem"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISEatFoodAction"

ISInventoryPane = ISPanel:derive("ISInventoryPane")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER = 50
ISInventoryPane.ghc = getCore():getGoodHighlitedColor()
ISInventoryPane.highlightItem = nil

local favoriteRecipeInputStarSize = 12
ISInventoryPaneDraggedItems = {}
local DraggedItems = ISInventoryPaneDraggedItems

ISInventoryPane.itemSortByWeightAsc = function(a,b)
    if a.equipped and not b.equipped then return false end
    if b.equipped and not a.equipped then return true end
    return a.weight < b.weight
end

ISInventoryPane.itemSortByWeightDesc = function(a,b)
    if a.equipped and not b.equipped then return false end
    if b.equipped and not a.equipped then return true end
    return a.weight > b.weight
end

ISInventoryPane.itemSortByNameInc = function(a,b)
    if a.equipped and not b.equipped then return false end
    if b.equipped and not a.equipped then return true end
	if a.inHotbar and not b.inHotbar then return true end
	if b.inHotbar and not a.inHotbar then return false end
    return not string.sort(a.name, b.name)
end

ISInventoryPane.itemSortByNameDesc = function(a,b)
    if a.equipped and not b.equipped then return false end
    if b.equipped and not a.equipped then return true end
	if a.inHotbar and not b.inHotbar then return true end
	if b.inHotbar and not a.inHotbar then return false end
    return string.sort(a.name, b.name)
end

ISInventoryPane.itemSortByCatInc = function(a,b)
    if a.equipped and not b.equipped then return false end
    if b.equipped and not a.equipped then return true end
    if a.cat == b.cat then return not string.sort(a.name, b.name) end
    return not string.sort(a.cat, b.cat)
end

ISInventoryPane.itemSortByCatDesc = function(a,b)
    if a.equipped and not b.equipped then return false end
    if b.equipped and not a.equipped then return true end
    if a.cat == b.cat then return not string.sort(a.name, b.name) end
    return string.sort(a.cat, b.cat)
end

-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPane:initialise()
	ISPanel.initialise(self)
end

function ISInventoryPane:new (x, y, width, height, inventory, zoom)
	local o = {}
	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
    self.__index = self
    o.player = 0 
	o.x = x
	o.y = y
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.5}
	o.width = width
	o.height = height
	o.anchorLeft = true
	o.anchorRight = false
	o.anchorTop = true
	o.anchorBottom = false
    o.padding = math.floor(FONT_HGT_SMALL*0.2)
	o.inventory = inventory
    o.zoom = zoom
	o.mode = "details"
	o.column2 = 30
	o.column3 = 140
 	o.column4 = o.width
	o.items = {}
	o.selected = {}
    o.highlightItems = {}
	o.previousMouseUp = nil
	local font = getCore():getOptionInventoryFont()
	if font == "Large" then
		o.font = UIFont.Large
	elseif font == "Small" then
		o.font = UIFont.Small
	else
		o.font = UIFont.Medium
	end
    if zoom > 1.5 then
        o.font = UIFont.Large
    end
    o.fontHgt = getTextManager():getFontFromEnum(o.font):getLineHeight()
    o.itemHgt = math.ceil(math.max(18, o.fontHgt) * o.zoom)
    o.texScale = math.min(32, (o.itemHgt - 2)) / 32
    o.draggedItems = DraggedItems:new(o)

    o.treecolicon = getTexture("media/ui/CleanUI/ICON/Icon_RightArrow.png")
    o.treeexpicon = getTexture("media/ui/CleanUI/ICON/Icon_DownArrow.png")

	o.equippedItemIcon = getTexture("media/ui/icon.png")
	o.equippedInHotbar = getTexture("media/ui/iconInHotbar.png")
    o.brokenItemIcon = getTexture("media/ui/icon_broken.png")
    o.frozenItemIcon = getTexture("media/ui/icon_frozen.png")
    o.poisonIcon = getTexture("media/ui/SkullPoison.png")
    o.itemSortFunc = ISInventoryPane.itemSortByNameInc
    o.favoriteStar = getTexture("media/ui/CleanUI/ICON/Icon_FavoriteStar.png")
    o.favoriteRecipeInputStar = getTexture("media/ui/CleanUI/ICON/FavouriteYes.png")

    o.mouseOverColumnDivider = false
    o.dividerDragging = false
   return o
end

-- ---------------------------------------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPane:createChildren()
    self.minimumHeight = 50
    self.minimumWidth = 256
    self.headerHgt = 0

    self.column2 = math.floor(FONT_HGT_SMALL * 2)
    self.column3 = math.ceil(self.column3*self.zoom)
    self.column3 = self.column3 + 100

    local categoryWid = math.max(100,self.column4-self.column3-1)
    if self.column3 - 1 + categoryWid > self.width then
        self.column3 = self.width - categoryWid + 1
    end

    self.nameHeader = ISResizableButton:new(self.column2, 0, (self.column3 - self.column2), self.headerHgt, getText("IGUI_invpanel_Type"), self, ISInventoryPane.sortByName)
    self.nameHeader:initialise()
    self.nameHeader.minimumWidth = 100
    self.nameHeader.onresize = { ISInventoryPane.onResizeColumn, self, self.nameHeader }
    self:addChild(self.nameHeader)
    self.nameHeader:setVisible(false)

    self.typeHeader = ISResizableButton:new(self.column3-1, 0, self.column4 - self.column3 + 1, self.headerHgt, getText("IGUI_invpanel_Category"), self, ISInventoryPane.sortByType)
    self.typeHeader.anchorRight = true
    self.typeHeader.minimumWidth = 100
    self.typeHeader.resizeLeft = true
    self.typeHeader.onresize = { ISInventoryPane.onResizeColumn, self, self.typeHeader }
    self.typeHeader:initialise()
    self:addChild(self.typeHeader)
    self.typeHeader:setVisible(false)

    self.contextButton1 = CleanUI_LongButton:new(0, 0, 10, self.itemHgt, getText("ContextMenu_Grab"), self, ISInventoryPane.onContext)
    self.contextButton1:initialise()
    self.contextButton1:setActive(true)
    self.contextButton1:setActiveColor(0, 0, 0)
    self:addChild(self.contextButton1)
    self.contextButton1:setFont(self.font)
    self.contextButton1:setVisible(false)

    self.contextButton2 = CleanUI_LongButton:new(0, 0, 10, self.itemHgt, getText("IGUI_invpanel_Pack"), self, ISInventoryPane.onContext)
    self.contextButton2:initialise()
    self.contextButton2:setActive(true)
    self.contextButton2:setActiveColor(0, 0, 0)
    self:addChild(self.contextButton2)
    self.contextButton2:setFont(self.font)
    self.contextButton2:setVisible(false)

    self.contextButton3 = CleanUI_LongButton:new(0, 0, 10, self.itemHgt, getText("IGUI_invpanel_Pack"), self, ISInventoryPane.onContext)
    self.contextButton3:initialise()
    self.contextButton3:setActive(true)
    self.contextButton3:setActiveColor(0, 0, 0)
    self:addChild(self.contextButton3)
    self.contextButton3:setFont(self.font)
    self.contextButton3:setVisible(false)

    self.vscroll = CleanUI.ScrollBar:new(self)
    self.vscroll:initialise()
    self:addChild(self.vscroll)
end

-- ---------------------------------------------------------------------------------------- --
-- Search Item
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPane:searchContainer(searchString)
    searchString = searchString or ""
    
    if searchString == "" then
        self:clearSearch()
        return
    end

    self.itemSortFunc = function(a, b)
        return self:searchSortFunction(a, b, searchString)
    end

    self:refreshContainer()
end

function ISInventoryPane:searchSortFunction(a, b, searchString)
    local lowerSearch = string.lower(searchString)

    local aMatches = self:itemMatchesSearch(a, lowerSearch)
    local bMatches = self:itemMatchesSearch(b, lowerSearch)

    if aMatches and not bMatches then
        return true
    elseif not aMatches and bMatches then
        return false
    end

    return self:getItemName(a) < self:getItemName(b)
end

function ISInventoryPane:itemMatchesSearch(item, lowerSearchString)
    local itemName = string.lower(self:getItemName(item))
    return string.find(itemName, lowerSearchString, 1, true) ~= nil
end

function ISInventoryPane:getItemName(item)
    if instanceof(item, "InventoryItem") then
        return item:getName()
    elseif item.name then
        return item.name
    elseif item.items and item.items[1] then
        return item.items[1]:getName()
    else
        return ""
    end
end

function ISInventoryPane:clearSearch()
    self.itemSortFunc = ISInventoryPane.itemSortByNameInc
    self:refreshContainer()
end

-- ---------------------------------------------------------------------------------------- --
-- Button Function
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPane:onContext(button)

    local playerObj = getSpecificPlayer(self.player)
    local playerInv = playerObj:getInventory()
    local lootInv = getPlayerLoot(self.player).inventory

    if button.mode == "unpack" then
        local k = self.items[self.buttonOption]
        local items = ISInventoryPane.getActualItems({k})
        ISInventoryPaneContextMenu.onMoveItemsTo(items, playerInv, self.player)
    end
    if button.mode == "grab" then
        local k = self.items[self.buttonOption]
        local items = ISInventoryPane.getActualItems({k})
        if isForceDropHeavyItem(items[1]) then
            ISInventoryPaneContextMenu.equipHeavyItem(playerObj, items[1])
            return
        end
        ISInventoryPaneContextMenu.onGrabItems(items, self.player)
    end
    if button.mode == "grab1" then
        local k = self.items[self.buttonOption]
        local items = ISInventoryPane.getActualItems({k})
        ISInventoryPaneContextMenu.onGrabOneItems(items, self.player)
    end
    if button.mode == "drop" then
        local k = self.items[self.buttonOption]
        local items = ISInventoryPane.getActualItems({k})
        ISInventoryPaneContextMenu.onDropItems(items, self.player)
    end
    if button.mode == "drop1" then
        local k = self.items[self.buttonOption]
        local items = ISInventoryPane.getActualItems({k})
        ISInventoryPaneContextMenu.onDropItems({items[1]}, self.player)
    end
    if button.mode == "place" then
        local k = self.items[self.buttonOption]
        local items = ISInventoryPane.getActualItems({k})
        local mo = ISMoveableCursor:new(getSpecificPlayer(self.player))
        getCell():setDrag(mo, mo.player)
        mo:setMoveableMode("place")
        mo:tryInitialItem(items[1])
    end

	getPlayerLoot(self.player).inventoryPane.selected = {}
	getPlayerInventory(self.player).inventoryPane.selected = {}
end

function ISInventoryPane:hideButtons()
    self.contextButton1:setVisible(false)
    self.contextButton2:setVisible(false)
    self.contextButton3:setVisible(false)
end

function ISInventoryPane:doButtons(y)

    self.contextButton1:setVisible(false)
    self.contextButton2:setVisible(false)
    self.contextButton3:setVisible(false)

	if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 or
			getPlayerContextMenu(self.player):isAnyVisible() or
			getSpecificPlayer(self.player):isAsleep() then
		return
	end

	if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
		return
	end

    local count = 1
    local item = self.items[y]
    if not instanceof(item, "InventoryItem") then
        count = item.count-1
        item = item.items[1]
    end
    local isNoDropMoveable = instanceof(item, "Moveable") and not item:CanBeDroppedOnFloor()

    local mode1,mode2,mode3 = nil,nil,nil
    local label1,label2,label3 = nil,nil,nil

    if self.inventory:isInCharacterInventory(getSpecificPlayer(self.player)) and self.inventory ~= getSpecificPlayer(self.player):getInventory() then
       -- unpack, drop
        mode1,label1 = "unpack", getText("IGUI_invpanel_unpack")
        if isNoDropMoveable then
            -- No 'Drop' option
        elseif count == 1 then
            mode2,label2 = "drop", getText("ContextMenu_Drop")
        else
            mode2,label2 = "drop", getText("IGUI_invpanel_drop_all")
            mode3,label3 = "drop1", getText("IGUI_invpanel_drop_one")
        end
        if not instanceof(self.items[y], "InventoryItem") then
            local fav = true
            local firstFav = true
            for i,v in ipairs(self.items[y].items) do
                if i == 1 then firstFav = v:isFavorite() end
                if not v:isFavorite() then
                    fav = false
                end
            end
            if fav then
                mode2 = nil
                mode3 = nil
            elseif count > 1 and firstFav then
                mode3 = nil
            end
        else
            if self.items[y]:isFavorite() then
                mode2 = nil
                mode3 = nil
            end
        end
    elseif self.inventory == getSpecificPlayer(self.player):getInventory() then
        if isNoDropMoveable then
            -- No 'Drop' option
        elseif count == 1 then
            mode1,label1 = "drop", getText("ContextMenu_Drop")
        else
            mode1,label1 = "drop", getText("IGUI_invpanel_drop_all")
            mode2,label2 = "drop1", getText("IGUI_invpanel_drop_one")
        end
        if not instanceof(self.items[y], "InventoryItem") then
            local fav = true
            local firstFav = true
            for i,v in ipairs(self.items[y].items) do
                if i == 1 then firstFav = v:isFavorite() end
                if not v:isFavorite() then
                    fav = false
                end
            end
            if fav then
                mode1 = nil
                mode2 = nil
            elseif count > 1 and firstFav then
                mode2 = nil
            end
        else
            if self.items[y]:isFavorite() then
                mode1 = nil
                mode2 = nil
            end
        end

        if instanceof(item, "Moveable") then
            if mode1 and mode2 then
                mode3,label3 = "place", getText("IGUI_Place")
            elseif mode1 then
                mode2,label2 = "place", getText("IGUI_Place")
            else
                mode1,label1 = "place", getText("IGUI_Place")
            end
        end
    else
        if count == 1 then
            mode1,label1 = "grab",getText("ContextMenu_Grab")
        else
            mode1,label1 = "grab",getText("ContextMenu_Grab_all")
            mode2,label2 = "grab1",getText("ContextMenu_Grab_one")
        end
    end

    local ypos = ((y-1)*self.itemHgt) + self.headerHgt
    ypos = ypos + self:getYScroll()

	if getCore():getGameMode() ~= "Tutorial" then
		if mode1 then
			self.contextButton1:setTitle(label1)
			self.contextButton1.mode = mode1
			self.contextButton1:setWidthToTitle()
			self.contextButton1:setX(self.column3)
			self.contextButton1:setY(ypos)
			self.contextButton1:setVisible(true)
		end
		if mode2 then
			self.contextButton2:setTitle(label2)
			self.contextButton2.mode = mode2
			self.contextButton2:setWidthToTitle()
			self.contextButton2:setX(self.contextButton1:getRight() + self.padding)
			self.contextButton2:setY(ypos)
			self.contextButton2:setVisible(true)
		end
		if mode3 then
			self.contextButton3:setTitle(label3)
			self.contextButton3.mode = mode3
			self.contextButton3:setWidthToTitle()
			self.contextButton3:setX(self.contextButton2:getRight() + self.padding)
			self.contextButton3:setY(ypos)
			self.contextButton3:setVisible(true)
		end
	end

    self.buttonOption = y
end


function ISInventoryPane:collapseAll(button)
    for k, v in pairs(self.collapsed) do
        self.collapsed[k] = true
    end
    self:refreshContainer()
end

function ISInventoryPane:expandAll(button)
    for k, v in pairs(self.collapsed) do
        self.collapsed[k] = false
    end
    self:refreshContainer()
end

function ISInventoryPane:toggleStove()
    local stove = self.inventory:getParent()
    stove:Toggle()
    return stove:Activated()
end

function ISInventoryPane:transferItemsByWeight(items, container)
	local playerObj = getSpecificPlayer(self.player)
	if true then
		self:sortItemsByTypeAndWeight(items)
	else
		self:sortItemsByType(items)
		self:sortItemsByWeight(items)
	end
	for _,item in ipairs(items) do
		if not container:isItemAllowed(item) then
		elseif container:getType() == "floor" then
			ISInventoryPaneContextMenu.dropItem(item, self.player)
		else
			ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), container))
		end
	end
end

function ISInventoryPane:removeAll(player)
	if self.removeAllDialog then
		self.removeAllDialog:destroy()
	end
	local width = 350
	local x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
	local height = 120
	local y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2
	local modal = ISModalDialog:new(x,y, width, height, getText("IGUI_ConfirmDeleteItems"), true, self, ISInventoryPane.onConfirmDelete, player)
	modal:initialise()
	self.removeAllDialog = modal
	modal:addToUIManager()
	if JoypadState.players[player+1] then
		modal.prevFocus = JoypadState.players[player+1].focus
		setJoypadFocus(player, modal)
	end
end

function ISInventoryPane:onConfirmDelete(button)
	if button.internal == "YES" then
		local object = self.inventory:getParent()
		local playerObj = getSpecificPlayer(self.player)
		local args = { x = object:getX(), y = object:getY(), z = object:getZ(), index = object:getObjectIndex() }
		sendClientCommand(playerObj, 'object', 'emptyTrash', args)
	end
	self.removeAllDialog = nil
end

function ISInventoryPane:lootAll()
	local playerObj = getSpecificPlayer(self.player)
	local playerInv = getPlayerInventory(self.player).inventory
	local items = {}
	local it = self.inventory:getItems()
	local heavyItem = nil
	if luautils.walkToContainer(self.inventory, self.player) then
		for i = 0, it:size()-1 do
			local item = it:get(i)
			if isForceDropHeavyItem(item) then
				heavyItem = item
			else
				table.insert(items, item)
			end
		end
		if heavyItem and it:size() == 1 then
			ISInventoryPaneContextMenu.equipHeavyItem(playerObj, heavyItem)
			return
		end
		self:transferItemsByWeight(items, playerInv)
	end
	self.selected = {}
	getPlayerLoot(self.player).inventoryPane.selected = {}
	getPlayerInventory(self.player).inventoryPane.selected = {}
end

function ISInventoryPane:transferAll()
	local playerObj = getSpecificPlayer(self.player)
	local playerLoot = getPlayerLoot(self.player).inventory
	local hotBar = getPlayerHotbar(self.player)
    local it = self.inventory:getItems()
	local items = {}
	if luautils.walkToContainer(self.inventory, self.player) then
		local toFloor = getPlayerLoot(self.player).inventory:getType() == "floor"
		for i = 0, it:size()-1 do
			local item = it:get(i)
			local ok = not item:isEquipped() and item:getType() ~= "KeyRing" and not item:hasTag( "KeyRing") and not hotBar:isInHotbar(item)
			if item:isFavorite() then
				ok = false
			end
			if toFloor and instanceof(item, "Moveable") and item:getSpriteGrid() == nil and not item:CanBeDroppedOnFloor() then
				ok = false
			end
			if ok then
				table.insert(items, item)
			end
		end
		self:transferItemsByWeight(items, playerLoot)
	end
    self.selected = {}
    getPlayerLoot(self.player).inventoryPane.selected = {}
    getPlayerInventory(self.player).inventoryPane.selected = {}
end

-- ---------------------------------------------------------------------------------------- --
-- Sort Item
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPane:onFilterMenu(button)
    local playerObj = getSpecificPlayer(self.player)
    local playerInv = playerObj:getInventory()
    if playerObj:isAsleep() then return end

    local x = button:getAbsoluteX()
    local y = button:getAbsoluteY()
    local context = ISContextMenu.get(self.player, x, y)

    getCell():setDrag(nil, self.player)

    local weight = context:addOption(getText("IGUI_invpanel_weight"), nil, nil)
    local subMenuWeight = ISContextMenu:getNew(context)
    context:addSubMenu(weight, subMenuWeight)

    subMenuWeight:addOption(getText("IGUI_invpanel_ascending"), self, ISInventoryPane.sortByWeight, true)
    subMenuWeight:addOption(getText("IGUI_invpanel_descending"), self, ISInventoryPane.sortByWeight, false)
end

function ISInventoryPane:sortByWeight(_isAscending)
    if _isAscending and self.itemSortFunc ~= ISInventoryPane.itemSortByWeightAsc then
        self.itemSortFunc = ISInventoryPane.itemSortByWeightAsc
        self:refreshContainer()
    end
    if (not _isAscending) and self.itemSortFunc ~= ISInventoryPane.itemSortByWeightDesc then
        self.itemSortFunc = ISInventoryPane.itemSortByWeightDesc
        self:refreshContainer()
    end
end

function ISInventoryPane:sortByName(button)
    if self.itemSortFunc == ISInventoryPane.itemSortByNameInc then
        self.itemSortFunc = ISInventoryPane.itemSortByNameDesc
    else
        self.itemSortFunc = ISInventoryPane.itemSortByNameInc
    end
    self:refreshContainer()
end

function ISInventoryPane:sortByType(button)
    if self.itemSortFunc == ISInventoryPane.itemSortByCatInc then
        self.itemSortFunc = ISInventoryPane.itemSortByCatDesc
    else
        self.itemSortFunc = ISInventoryPane.itemSortByCatInc
    end
    self:refreshContainer()
end

function ISInventoryPane:sortItemsByType(items)
	table.sort(items, function(a,b)
		if a:getContainer() and a:getContainer() == b:getContainer() and a:getDisplayName() == b:getDisplayName() then
			return a:getContainer():getItems():indexOf(a) < b:getContainer():getItems():indexOf(b)
		end
		return not string.sort(a:getType(), b:getType())
	end)
end

function ISInventoryPane:sortItemsByWeight(items)
	table.sort(items, function(a,b)
		if a:getContainer() and a:getContainer() == b:getContainer() and a:getDisplayName() == b:getDisplayName() then
			return a:getContainer():getItems():indexOf(a) < b:getContainer():getItems():indexOf(b)
		end
		return a:getUnequippedWeight() < b:getUnequippedWeight()
	end)
end

function ISInventoryPane:sortItemsByTypeAndWeight(items)
	local indexMap = {}
	local containers = {}
	local allIndexMap = {}
	for index,item in ipairs(items) do
		local container = item:getContainer()
		if container and not containers[container] then
			containers[container] = true
			local containerItems = container:getItems()
			for i=1,containerItems:size() do
				indexMap[containerItems:get(i-1)] = i
			end
		end
		allIndexMap[item] = index
	end

	local itemsByName = {}
	for _,item in ipairs(items) do
		local key = item:getDisplayName()
		itemsByName[key] = itemsByName[key] or {}
		table.insert(itemsByName[key], item)
	end

	local sorted = {}
	for _,itemList in pairs(itemsByName) do
		timSort(itemList, function(a,b)
			if a:getContainer() and (a:getContainer() == b:getContainer()) then
                -- this sometimes catches items that have the same parent container
                -- returned by :getContainer() but parent:getItems() failed to return
                -- both of them (some desync issue elsewhere?). In which case it doesnt
                -- matter which gets sorted first.
                if not indexMap[a] or not indexMap[b] then return false end
				return indexMap[a] < indexMap[b]
			end
			return allIndexMap[a] < allIndexMap[b]
		end)
		table.insert(sorted, itemList)
	end
	timSort(sorted, function(a,b)
		local wa = a[1]:getUnequippedWeight()
		local wb = b[1]:getUnequippedWeight()
		if wa < wb then
			return true
		end
		if wa == wb then
			return allIndexMap[a[1]] < allIndexMap[b[1]]
		end
		return false
	end)
	table.wipe(items)
	local count = 1
	for _,itemList in ipairs(sorted) do
		for _,item in ipairs(itemList) do
			items[count] = item
			count = count + 1
		end
	end
end



function ISInventoryPane:SaveLayout(name, layout)
    layout.column2 = self.nameHeader.width
    if self.itemSortFunc == self.itemSortByNameInc then layout.sortBy = "nameInc" end
    if self.itemSortFunc == self.itemSortByNameDesc then layout.sortBy = "nameDesc" end
    if self.itemSortFunc == self.itemSortByCatInc then layout.sortBy = "catInc" end
    if self.itemSortFunc == self.itemSortByCatDesc then layout.sortBy = "catDesc" end
end

function ISInventoryPane:RestoreLayout(name, layout)
    if layout.column2 and tonumber(layout.column2) then
        self.nameHeader:setWidth(tonumber(layout.column2))
        self:onResizeColumn(self.nameHeader)
    end
    if layout.sortBy == "nameInc" then self.itemSortFunc = self.itemSortByNameInc end
    if layout.sortBy == "nameDesc" then self.itemSortFunc = self.itemSortByNameDesc end
    if layout.sortBy == "catInc" then self.itemSortFunc = self.itemSortByCatInc end
    if layout.sortBy == "catDesc" then self.itemSortFunc = self.itemSortByCatDesc end
    self:refreshContainer()
end

function ISInventoryPane:rowAt(x, y)
	local rowCount = math.floor((self:getScrollHeight() - self.headerHgt) / self.itemHgt)
	if rowCount > 0 then
		return math.floor((y) / self.itemHgt) + 1
	end
	return -1
end

function ISInventoryPane:topOfItem(index)
	local rowCount = math.floor((self:getScrollHeight() - self.headerHgt) / self.itemHgt)
	if rowCount > 0 then
		return (index - 1) * self.itemHgt
	end
	return -1
end

function ISInventoryPane:onMouseWheel(del)
    if self.inventoryPage.isCollapsed then return false end
    if self.inventoryPage:isCycleContainerKeyDown() then return false end
	local yScroll = self.smoothScrollTargetY or self:getYScroll()
	local topRow = self:rowAt(0, -yScroll)
	if self.items[topRow] then
		if not self.smoothScrollTargetY then self.smoothScrollY = self:getYScroll() end
		local y = self:topOfItem(topRow)
		if del < 0 then
			if yScroll == -y and topRow > 1 then
				y = self:topOfItem(topRow - 1)
			end
			self.smoothScrollTargetY = -y
		else
			self.smoothScrollTargetY = -(y + self.itemHgt)
		end
	else
		self:setYScroll(self:getYScroll() - (del*9))
	end
    return true
end

function ISInventoryPane:selectIndex(index)
	local listItem = self.items[index]
	if not listItem then return end
	self.selected[index] = listItem
    if not instanceof(listItem, "InventoryItem") and not self.collapsed[listItem.name] then
        for i=2,#listItem.items do
            self.selected[index+i-1] = listItem.items[i]
            if i == ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then break end
        end
    else
        local v = self.items[index-1]
        if v ~= nil and not instanceof(v, "InventoryItem") and not self.collapsed[v.name] and #v.items == 2 then
            self.selected[index-1] = v
        end
    end
end

function ISInventoryPane:onMouseMoveOutside(dx, dy)
	local x = self:getMouseX()
	local y = self:getMouseY()
    self.buttonOption = 0

    self.contextButton1:setVisible(false)
    self.contextButton2:setVisible(false)
    self.contextButton3:setVisible(false)

    self.mouseOverOption = 0

    if(self.draggingMarquis) then
		local x2 = self.draggingMarquisX
		local y2 = self.draggingMarquisY
        if(self:getMouseY() + self:getYScroll() > self:getHeight()) then
            self:setYScroll(self:getYScroll() - (9))
        end
        if(self:getMouseY() + self:getYScroll() < 0) then
            self:setYScroll(self:getYScroll() + (9))
        end

		if (x2 < x) then
			local xt = x
			x = x2
			x2 = xt
		end
		if (y2 < y) then
			local yt = y
			y = y2
			y2 = yt
		end

		if x > self.column3 then
			return
		end

		local startY = math.floor((y-self.headerHgt) / self.itemHgt) + 1
		local endY = math.floor((((y2)-self.headerHgt) / self.itemHgt)) + 1

		if(startY < 1) then
			startY = 1
		end

		self.selected = {}
		for i=startY, endY do
			self:selectIndex(i)
		end
	end

	if self.dragging and not self.dragStarted and (math.abs(x - self.draggingX) > 4 or math.abs(y - self.draggingY) > 4) then
		self.dragStarted = true
	end
end

function ISInventoryPane:onMouseMove(dx, dy)
    if self.player ~= 0 then return end

    local x = self:getMouseX()
    local y = self:getMouseY()

    local dividerX = self.column3 - self.padding - 1
    self.mouseOverColumnDivider = (x >= dividerX - 4 and x <= dividerX + 4)

    if self.dividerDragging then
        local newColumn3 = x + 1
        newColumn3 = math.max(100, math.min(self.width - 100, newColumn3))

        local newNameWidth = newColumn3 - self.column2
        self.nameHeader:setWidth(newNameWidth)

        self:onResizeColumn(self.nameHeader)
        return
    end

    self.contextButton1:setVisible(false)
    self.contextButton2:setVisible(false)
    self.contextButton3:setVisible(false)

    if(self.draggingMarquis) then
		local x2 = self.draggingMarquisX
		local y2 = self.draggingMarquisY

		if (x2 < x) then
			local xt = x
			x = x2
			x2 = xt
		end
		if (y2 < y) then
			local yt = y
			y = y2
			y2 = yt
		end

		if x > self.column3 then
			return
		end

		local startY = math.floor((y-self.headerHgt) / self.itemHgt) + 1
		local endY = math.floor((((y2)-self.headerHgt) / self.itemHgt)) + 1

		if(startY < 1) then
			startY = 1
		end

		self.selected = {}
		for i=startY, endY do
			self:selectIndex(i)
		end
    else
        if self.dragging == nil and x >= 0 and y >= 0 and x >= self.column3 and not isShiftKeyDown() and not self:isMouseOverScrollBar() then
            y = y - self.headerHgt
            y = y / self.itemHgt
            y = math.floor(y + 1)
            local topOfRow = ((y - 1) * self.itemHgt) + self:getYScroll() + self.headerHgt
            if self.items[y] and topOfRow >= self.headerHgt then
                self:doButtons(y)
            end
        end
		if self.dragging == nil and x >= 0 and y >= 0 and x < self.column3 then
            y = y - self.headerHgt
            y = y / self.itemHgt
            y = math.floor(y + 1)
            self.mouseOverOption = y
		else
			self.mouseOverOption = 0
		end

	end
	if self.dragging and not self.dragStarted and (math.abs(x - self.draggingX) > 4 or math.abs(y - self.draggingY) > 4) then
		self.dragStarted = true
	end
end

function ISInventoryPane:updateTooltip()
	if not self:isReallyVisible() then
		if self.parent.onCharacter then
			Key.setHighlightDoors(self.player, nil)
		end
		return
	end
	local item = nil
	if self.doController and self.joyselection then
		if self.joyselection < 0 then self.joyselection = #self.items - 1 end
		if self.joyselection >= #self.items then self.joyselection = 0 end
		item = self.items[self.joyselection+1]
	end
	if not self.doController and not self.dragging and not self.draggingMarquis and self:isMouseOver() then
		local x = self:getMouseX()
		local y = self:getMouseY()
		if x < self.column3 and y + self:getYScroll() >= self.headerHgt then
			y = y - self.headerHgt
			y = y / self.itemHgt
			self.mouseOverOption = math.floor(y + 1)
			item = self.items[self.mouseOverOption]
		end
	end
	local weightOfStack = 0.0
	if item and not instanceof(item, "InventoryItem") then
		if #item.items > 2 then
			weightOfStack = item.weight
		end
		item = item.items[1]
	end
	if getPlayerContextMenu(self.player):isAnyVisible() then
		item = nil
	end
	if item and self.toolRender and (item == self.toolRender.item) and
			(weightOfStack == self.toolRender.tooltip:getWeightOfStack()) and
			self.toolRender:isVisible() then
		if self.parent.onCharacter then
			Key.setHighlightDoors(self.player, item)
		end
		return
	end
	if item then
		if self.toolRender then
			self.toolRender:setItem(item)
			self.toolRender:setVisible(true)
			self.toolRender:addToUIManager()
			self.toolRender:bringToTop()
		else
			self.toolRender = ISToolTipInv:new(item)
			self.toolRender:initialise()
			self.toolRender:addToUIManager()
			self.toolRender:setVisible(true)
			self.toolRender:setOwner(self)
			self.toolRender:setCharacter(getSpecificPlayer(self.player))
			self.toolRender.anchorBottomLeft = { x = self:getAbsoluteX() + self.column2, y = self:getParent():getAbsoluteY() }
		end
		self.toolRender.followMouse = not self.doController
		self.toolRender.tooltip:setWeightOfStack(weightOfStack)
		if not self.doController then
		end
	elseif self.toolRender then
		self.toolRender:removeFromUIManager()
		self.toolRender:setVisible(false)
	end

	-- Hack for highlighting doors when a Key tooltip is displayed.
	if self.parent.onCharacter then
		if not self.toolRender or not self.toolRender:getIsVisible() then
			item = nil
		end
		Key.setHighlightDoors(self.player, item)
	end

	local inventoryPage = getPlayerInventory(self.player)
	local inventoryTooltip = inventoryPage and inventoryPage.inventoryPane.toolRender
	local lootPage = getPlayerLoot(self.player)
	local lootTooltip = lootPage and lootPage.inventoryPane.toolRender
	UIManager.setPlayerInventoryTooltip(self.player,
		inventoryTooltip and inventoryTooltip.javaObject or nil,
		lootTooltip and lootTooltip.javaObject or nil)
end

-- ---------------------------------------------------------------------------------------- --
-- ISInventoryPane:onMouseUpOutside
-- ---------------------------------------------------------------------------------------- --
function ISInventoryPane:onMouseDownOutside(x, y)
	self.dragging = nil
	self.draggedItems:reset()
	if self:isMouseOverScrollBar() then
		self.clickedScrollBar = true
	else
		self.clickedScrollBar = false
		self.selected = {}
	end
end

function ISInventoryPane:onMouseUpOutside(x, y)
    self.previousMouseUp = self.mouseOverOption
    if self.draggingMarquis then
        self:onMouseUp(x, y)
    elseif not self.clickedScrollBar then
        self.selected = {}
    end
    self.draggingMarquis = false
    self.clickedScrollBar = false
end

function ISInventoryPane.getActualItems(items)
	local ret = {}
	local contains = {}
	for _,item in ipairs(items) do
		if instanceof(item, "InventoryItem") then
			if not contains[item] then
				-- The top-level group and its children might both be selected.
				table.insert(ret, item)
				contains[item] = true
			end
		else
			-- The first item is a dummy duplicate, skip it.
			for i=2,#item.items do
				local item2 = item.items[i]
				if not contains[item2] then
					table.insert(ret, item2)
					contains[item2] = true
				end
			end
		end
	end
	return ret
end

function ISInventoryPane:doContextualDblClick(item)
	local playerObj = getSpecificPlayer(self.player)
	if instanceof(item, "HandWeapon") then
		if playerObj:isHandItem(item) then
			ISInventoryPaneContextMenu.unequipItem(item, self.player)
		elseif item:getCondition() > 0 then
			ISInventoryPaneContextMenu.equipWeapon(item, true, item:isTwoHandWeapon(), self.player)
		end
	end
	if instanceof(item, "Clothing") then
		if playerObj:isEquipped(item) then
			ISInventoryPaneContextMenu.onUnEquip({item}, self.player)
		else
			ISInventoryPaneContextMenu.onWearItems({item}, self.player)
		end
	end
	if instanceof(item, "InventoryContainer") and item:canBeEquipped() ~= nil and item:canBeEquipped() ~= "" then
		if playerObj:isEquipped(item) then
			ISInventoryPaneContextMenu.onUnEquip({item}, self.player)
		else
			ISInventoryPaneContextMenu.onWearItems({item}, self.player)
		end
	elseif instanceof (item, "InventoryContainer") and item:getItemReplacementSecondHand() ~= nil then
		if playerObj:isEquipped(item) then
			ISInventoryPaneContextMenu.onUnEquip({item}, self.player)
		else
			ISInventoryPaneContextMenu.equipWeapon(item, false, false, self.player)
		end
	end
	if instanceof(item, "Food") and item:getHungChange() < 0 and not item:getScriptItem():isCantEat() then
        -- if playerObj:getMoodles():getMoodleLevel(MoodleType.FoodEaten) < 3 or playerObj:getNutrition():getCalories() < 1000 then
        if playerObj:getMoodles():getMoodleLevel(MoodleType.FoodEaten) < 3 then
            ISInventoryPaneContextMenu.onEatItems({item}, 1, self.player)
        end

	end
end

function ISInventoryPane:onMouseDoubleClick(x, y)
	if self.vscroll and self:isMouseOverScrollBar() then
		return self.vscroll:onMouseDoubleClick(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
	end
	if self.items and self.mouseOverOption and self.previousMouseUp == self.mouseOverOption then
		if getCore():getGameMode() == "Tutorial" then
			if TutorialData.chosenTutorial.doubleClickInventory(self, x, y, self.mouseOverOption) then
				return
			end
		end
		local playerObj = getSpecificPlayer(self.player)
		local playerInv = getPlayerInventory(self.player).inventory
		local lootInv = getPlayerLoot(self.player).inventory
		local item = self.items[self.mouseOverOption]
		local doWalk = true
        local shiftHeld = isShiftKeyDown()
		if item and not instanceof(item, "InventoryItem") then
			-- expand or collapse...
			if x < self.column2 then
				self.collapsed[item.name] = not self.collapsed[item.name]
				self:refreshContainer()
				return
			end
			if item.items then
				for k, v in ipairs(item.items) do
					if k ~= 1 and v:getContainer() ~= playerInv then
						if isForceDropHeavyItem(v) then
							ISInventoryPaneContextMenu.equipHeavyItem(playerObj, v)
							break
						end
						if doWalk then
							if not luautils.walkToContainer(v:getContainer(), self.player) then
								break
							end
							doWalk = false
						end
						ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, v, v:getContainer(), playerInv))
                        if instanceof(v, "Clothing") and not v:isBroken() and shiftHeld then
                            ISTimedActionQueue.add(ISWearClothing:new(playerObj, v))
                        end
					elseif k ~= 1 and v:getContainer() == playerInv then
						local tItem = v
						self:doContextualDblClick(tItem)
						break
					end
				end
			end
		elseif item and item:getContainer() ~= playerInv then
			if isForceDropHeavyItem(item) then
				ISInventoryPaneContextMenu.equipHeavyItem(playerObj, item)
			elseif luautils.walkToContainer(item:getContainer(), self.player) then
				ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerInv))
			end
		elseif item and item:getContainer() == playerInv then -- double click do some basic action, equip weapon/wear clothing...
			self:doContextualDblClick(item)
		end
		self.previousMouseUp = nil
	end
end

function ISInventoryPane:onMouseUp(x, y)
	if self.player ~= 0 then return end

    local playerObj = getSpecificPlayer(self.player)

    if self.dividerDragging then
        self.dividerDragging = false
        return true
    end

	self.previousMouseUp = self.mouseOverOption
    if (not isShiftKeyDown() and not isCtrlKeyDown() and x >= self.column2 and  x == self.downX and y == self.downY) and  self.mouseOverOption ~= 0 and self.items[self.mouseOverOption] ~= nil then
        self.selected = {}
        self:selectIndex(self.mouseOverOption)
    end

    if ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus ~= self and ISMouseDrag.draggingFocus ~= nil then
        if getCore():getGameMode() ~= "Tutorial" then
            if self:canPutIn() then
                local doWalk = true
                local items = {}
                local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
                for i,v in ipairs(dragging) do
                    local transfer = v:getContainer() and not self.inventory:isInside(v)
                    if v:isFavorite() and not self.inventory:isInCharacterInventory(playerObj) then
                        transfer = false
                    end
                    if transfer then
                        -- only walk for the first item
                        if doWalk then
                            if not luautils.walkToContainer(self.inventory, self.player) then
                                break
                            end
                            doWalk = false
                        end
                        table.insert(items, v)
                    end
                end
                self:transferItemsByWeight(items, self.inventory)
                self.selected = {}
                getPlayerLoot(self.player).inventoryPane.selected = {}
                getPlayerInventory(self.player).inventoryPane.selected = {}
            end
        end
        if ISMouseDrag.draggingFocus then
            ISMouseDrag.draggingFocus:onMouseUp(0,0)
        end
        ISMouseDrag.draggingFocus = nil
        ISMouseDrag.dragging = nil
        return
    end

	self.dragging = nil
	self.draggedItems:reset()
	ISMouseDrag.dragging = nil
	ISMouseDrag.draggingFocus = nil

    if x >= 0 and y >= 0 and x < self.column3 then
        y = y - self.headerHgt
        y = y / self.itemHgt
        y = math.floor(y + 1)
        self.mouseOverOption = y
    end
    self.draggingMarquis = false

	return true
end

function ISInventoryPane:canPutIn()
    local playerObj = getSpecificPlayer(self.player)

    if self.inventory == nil then
        return false
    end
    if self.inventory:getType() == "floor" then
        return true
    end

    if self.inventory:getParent() == playerObj then
        return true
    end

    local items = {}
    -- If the lightest item fits, allow the transfer.
    local minWeight = 100000
    local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
    for i,v in ipairs(dragging) do
        local itemOK = true
        if v:isFavorite() and not self.inventory:isInCharacterInventory(playerObj) then
            itemOK = false
        end
        -- you can't draw the container in himself
        if (self.inventory:isInside(v)) then
            itemOK = false
        end
        if self.inventory:getType() == "floor" and v:getWorldItem() then
            itemOK = false
        end
        if v:getContainer() == self.inventory then
            itemOK = false
        end
        local inv = self.inventory
--        if self.mouseOverButton and self.mouseOverButton.inventory then
--            inv = self.mouseOverButton.inventory
--        end
        if not inv:isItemAllowed(v) then
            itemOK = false
        end
        if itemOK then
            table.insert(items, v)
        end
        if v:getUnequippedWeight() < minWeight then
            minWeight = v:getUnequippedWeight()
        end
    end
    if #items == 1 then
        return self.inventory:hasRoomFor(playerObj, items[1])
    end
    return self.inventory:hasRoomFor(playerObj, minWeight)
end

function DraggedItems:getDropContainer()
    local playerInv = getPlayerInventory(self.playerNum)
    local playerLoot = getPlayerLoot(self.playerNum)
    if not playerInv or not playerLoot then
        return nil
    end
    if playerInv.mouseOverButton then
        return playerInv.mouseOverButton.inventory, "button"
    end
    if playerInv.inventoryPane:isMouseOver() then
        return playerInv.inventoryPane.inventory, "inventory"
    end
    if playerLoot.mouseOverButton then
        return playerLoot.mouseOverButton.inventory, "button"
    end
    if playerLoot.inventoryPane:isMouseOver() then
        return playerLoot.inventoryPane.inventory, "loot"
    end

    local mx = getMouseX()
    local my = getMouseY()
    local uis = UIManager.getUI()
    local mouseOverUI = nil
    for i=0,uis:size()-1 do
        local ui = uis:get(i)
        if ui:isPointOver(mx, my) then
            mouseOverUI = ui
            break
        end
    end
    if not mouseOverUI then
        return ISInventoryPage.GetFloorContainer(self.playerNum), "floor"
    end

    return nil
end

function DraggedItems:update()
    self.playerNum = self.inventoryPane.player
    local playerObj = getSpecificPlayer(self.playerNum)

    if not self.items then
        self.items = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        self.inventoryPane:sortItemsByTypeAndWeight(self.items)
    end

    -- Try to detect changes to the destination container.
    if self.mouseOverContainer and (self.mouseOverItemCount ~= self.mouseOverContainer:getItems():size()) then
        self.mouseOverContainer = nil
    end

    local container, what = self:getDropContainer()
    if (container == self.mouseOverContainer) and (what == self.mouseOverWhat) then
        return
    end
    self.mouseOverContainer = container
    self.mouseOverWhat = what
    self.mouseOverItemCount = container and container:getItems():size() or 0
    table.wipe(self.itemNotOK)

    if #self.items == 0 then
        return
    end

    if not container then
        return
    end

    local containerInInventory = container:isInCharacterInventory(playerObj)

    -- Items may always be dragged to the floor (except favorited items).
    if container:getType() == "floor" then
        for _,item in ipairs(self.items) do
            if item:isFavorite() and not containerInInventory then
                self.itemNotOK[item] = true
            end
            if what ~= "loot" and item:getWorldItem() then
                self.itemNotOK[item] = true
            end
        end
        return
    end

    -- Dragging from ourself to ourself does nothing, but don't show as prevented.
    if what ~= "button" and container == self.inventoryPane.inventory then
        return
    end

    local totalWeight = 0
    local overWeight = false
    local validItems = {}
    for _,item in ipairs(self.items) do
        local itemOK = true
        if container:isInside(item) then
            itemOK = false
        end
        if item:isFavorite() and not containerInInventory then
            itemOK = false
        end
        if item:getContainer() == container then
            itemOK = false
        end
        if not container:isItemAllowed(item) then
            itemOK = false
        end
        -- Items are sorted by weight (see above)
        if itemOK then
            totalWeight = totalWeight + item:getUnequippedWeight()
        end
        if overWeight then
            itemOK = false
        else
            if not container:hasRoomFor(playerObj, totalWeight) then
                itemOK = false
                overWeight = true
            end
        end
        if itemOK then
            table.insert(validItems, item)
        else
            self.itemNotOK[item] = true
        end
    end

    -- Hack: Allow any single item on a vehicle seat regardless of weight (ex, Generator)
    if #validItems == 1 then
        local item = validItems[1]
        self.itemNotOK[item] = not container:hasRoomFor(playerObj, item)
    end
end

function DraggedItems:cannotDropItem(item)
    if not item then return false end
    return self.itemNotOK[item] == true
end

function DraggedItems:reset()
    self.mouseOverContainer = nil
    self.mouseOverWhat = nil
    self.items = nil
    table.wipe(self.itemNotOK)
end

function DraggedItems:new(inventoryPane)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.inventoryPane = inventoryPane
    o.mouseOverContainer = nil
    o.mouseOverWhat = nil
    o.items = nil
    o.itemNotOK = {}
    return o
end

function ISInventoryPane:doJoypadExpandCollapse()
    if not self.joyselection then return end
    if not self.items or not self.items[self.joyselection+1] then return end
    if not instanceof(self.items[self.joyselection+1], "InventoryItem") then
        self.collapsed[self.items[self.joyselection+1].name] = not self.collapsed[self.items[self.joyselection+1].name]
        self:refreshContainer()
    end
end

function ISInventoryPane:doGrabOnJoypadSelected()
    if self.joyselection == nil then return end
    if not self.doController then return end

    local playerObj = getSpecificPlayer(self.player)
    if playerObj:isAsleep() then return end

    if #self.items == 0 then return end

    self.selected = {}
    self:selectIndex(self.joyselection+1)

    local items = {}
    for k, v in ipairs(self.items) do
        if self.selected[k] ~= nil then
            if instanceof(v, "InventoryItem") then
                if not self.parent.onCharacter and isForceDropHeavyItem(v) then
                    ISInventoryPaneContextMenu.equipHeavyItem(playerObj, v)
                    return
                end
                table.insert(items, v)
            elseif self.collapsed[v.name] then
                if not self.parent.onCharacter and isForceDropHeavyItem(v.items[1]) then
                    ISInventoryPaneContextMenu.equipHeavyItem(playerObj, v.items[1])
                    return
                end
                table.insert(items, v)
            end
        end
    end
    if self.parent.onCharacter then
        ISInventoryPaneContextMenu.onPutItems(items, self.player)
    else
        ISInventoryPaneContextMenu.onGrabItems(items, self.player)
    end
end

function ISInventoryPane:doContextOnJoypadSelected()
	if JoypadState.disableInvInteraction then
		return
	end
	if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
		return
	end

    local playerObj = getSpecificPlayer(self.player)
    if playerObj:isAsleep() then return end

    local isInInv = self.inventory:isInCharacterInventory(playerObj)

    if #self.items == 0 then
        local menu = ISInventoryPaneContextMenu.createMenuNoItems(self.player, not isInInv, self:getAbsoluteX()+64, self:getAbsoluteY()+64)
        if menu then
            menu.origin = self.inventoryPage
            menu.mouseOver = 1
            setJoypadFocus(self.player, menu)
        end
        return
    end

    if self.joyselection == nil then return end
    if not self.doController then return end

    self:selectIndex(self.joyselection+1)
    local item = self.items[self.joyselection+1]

    local contextMenuItems = {}
    for k, v in ipairs(self.items) do
        if self.selected[k] ~= nil then
            if instanceof(v, "InventoryItem") or self.collapsed[v.name] then
                table.insert(contextMenuItems, v)
            end
        end
    end
	
	local menu = nil
	if getCore():getGameMode() == "Tutorial" then
		menu = Tutorial1.createInventoryContextMenu(self.player, isInInv, contextMenuItems, self:getAbsoluteX()+64, self:getAbsoluteY()+8+(self.joyselection*self.itemHgt)+self:getYScroll())
	else
    	menu = ISInventoryPaneContextMenu.createMenu(self.player, isInInv, contextMenuItems, self:getAbsoluteX()+64, self:getAbsoluteY()+8+(self.joyselection*self.itemHgt)+self:getYScroll())
	end
    menu.origin = self.inventoryPage
    menu.mouseOver = 1
	if menu.numOptions > 1 then
    	setJoypadFocus(self.player, menu)
	end
end

function ISInventoryPane:onRightMouseUp(x, y)

	if self.player ~= 0 then return end

    local isInInv = self.inventory:isInCharacterInventory(getSpecificPlayer(self.player))
    
    if #self.items == 0 then
        local menu = ISInventoryPaneContextMenu.createMenuNoItems(self.player, not isInInv, self:getAbsoluteX()+x, self:getAbsoluteY()+y+self:getYScroll())
        if menu and menu.numOptions > 1 and JoypadState.players[self.player+1] then
            menu.origin = self.inventoryPage
            menu.mouseOver = 1
            setJoypadFocus(self.player, menu)
        end
        return
    end

	if self.selected == nil then
		self.selected = {}
	end

    if self.mouseOverOption ~= 0 and self.items[self.mouseOverOption] ~= nil and self.selected[self.mouseOverOption] == nil then
        self.selected = {}
        self:selectIndex(self.mouseOverOption)
    end

    local contextMenuItems = {}
    for k, v in ipairs(self.items) do
       if self.selected[k] ~= nil then
           if instanceof(v, "InventoryItem") or self.collapsed[v.name] then
                table.insert(contextMenuItems, v)
           end
       end
    end

	if self.toolRender then
		self.toolRender:setVisible(false)
	end

    local menu = ISInventoryPaneContextMenu.createMenu(self.player, isInInv, contextMenuItems, self:getAbsoluteX()+x, self:getAbsoluteY()+y+self:getYScroll())
    if menu and menu.numOptions > 1 and JoypadState.players[self.player+1] then
        menu.origin = self.inventoryPage
        menu.mouseOver = 1
        setJoypadFocus(self.player, menu)
    end

	return true
end

function ISInventoryPane:onMouseDown(x, y)
	if self.player ~= 0 then return true end

	getSpecificPlayer(self.player):nullifyAiming()

    if self.mouseOverColumnDivider then
        self.dividerDragging = true
        return true
    end

	local count = 0

    self.downX = x
    self.downY = y

    if self.selected == nil then
		self.selected = {}
    end

    if self.mouseOverOption ~= 0 and self.items[self.mouseOverOption] ~= nil then

        -- expand or collapse...
        if x < self.column2 then

            if not instanceof(self.items[self.mouseOverOption], "InventoryItem") then
                self.collapsed[self.items[self.mouseOverOption].name] = not self.collapsed[self.items[self.mouseOverOption].name]
                self:refreshContainer()
                self.selected = {}
                return
            end
        end
        if not isShiftKeyDown() and not isCtrlKeyDown() and self.selected[self.mouseOverOption] == nil then
            self.selected = {}
            self.firstSelect = nil
        end

        if not isShiftKeyDown() then
            self.firstSelect = self.mouseOverOption
            if isCtrlKeyDown() then
                if self.selected[self.mouseOverOption] then
                    self.selected[self.mouseOverOption] = nil
                else
                    self.selected[self.mouseOverOption] =  self.items[self.mouseOverOption]
                end
            else
                self.selected[self.mouseOverOption] =  self.items[self.mouseOverOption]
            end
        end
        if isShiftKeyDown() then
           if self.firstSelect then
               self.selected = {}
               if self.firstSelect < self.mouseOverOption then
                    for i=self.firstSelect, self.mouseOverOption do
                        self.selected[i] =  self.items[i]
                    end
               else
                   for i=self.mouseOverOption, self.firstSelect do
                       self.selected[i] =  self.items[i]
                   end
               end
           else
               self.firstSelect = self.mouseOverOption
               self.selected[self.mouseOverOption] =  self.items[self.mouseOverOption]
           end
        end

        local listItem = self.items[self.mouseOverOption]
        if listItem and self.selected[self.mouseOverOption] and not instanceof(listItem, "InventoryItem") and not self.collapsed[listItem.name] then
            for i=2,#listItem.items do
                self.selected[self.mouseOverOption+i-1] = listItem.items[i]
                if i == ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then break end
            end
        end

		self.dragging = self.mouseOverOption
		self.draggingX = x
		self.draggingY = y
		self.dragStarted = false
		ISMouseDrag.dragging = {}
		for i,v in ipairs(self.items) do
            if self.selected[count+1] ~= nil then
                table.insert(ISMouseDrag.dragging, v)
            end
            count = count + 1
		end
		ISMouseDrag.draggingFocus = self
        return
	end
    if not isShiftKeyDown() and not isCtrlKeyDown() then
        self.selected = {}
        self.firstSelect = nil
    end

    if self.dragging == nil and x >= 0 and y >= 0 and (x<=self.column3 and y <= self:getScrollHeight() - self.itemHgt) then

	elseif count == 0 then
		self.draggingMarquis = true
		self.draggingMarquisX = x
		self.draggingMarquisY = y
		self.dragging = nil
		self.draggedItems:reset()
		ISMouseDrag.dragging = nil
		ISMouseDrag.draggingFocus = nil


	end

	if x < self.column2 and y < self.headerHgt then
		return false
	end
	return true
end

function ISInventoryPane:getScrollAreaHeight()
	return self:getHeight() - self.headerHgt
end

function ISInventoryPane:updateSmoothScrolling()
	if not self.smoothScrollTargetY or #self.items == 0 then return end
	local dy = self.smoothScrollTargetY - self.smoothScrollY
	local maxYScroll = self:getScrollHeight() - self:getScrollAreaHeight()
	local frameRateFrac = UIManager.getMillisSinceLastRender() / 33.3
	local itemHeightFrac = 160 / (self:getScrollHeight() / #self.items)
	local targetY = self.smoothScrollY + dy * math.min(0.5, 0.25 * frameRateFrac * itemHeightFrac)
	if frameRateFrac > 1 then
		targetY = self.smoothScrollY + dy * math.min(1.0, math.min(0.5, 0.25 * frameRateFrac * itemHeightFrac) * frameRateFrac)
	end
	if targetY > 0 then targetY = 0 end
	if targetY < -maxYScroll then targetY = -maxYScroll end
	if math.abs(targetY - self.smoothScrollY) > 0.1 then
		self:setYScroll(targetY)
		self.smoothScrollY = targetY
	else
		self:setYScroll(self.smoothScrollTargetY)
		self.smoothScrollTargetY = nil
		self.smoothScrollY = nil
	end
end

function ISInventoryPane:isMouseOverScrollBar()
	return self:isVScrollBarVisible() and self.vscroll:isMouseOver()
end

local function isSelectAllPossible(page)
    if not page then return false end
    if not page:isVisible() then return false end
    if page.isCollapsed then return false end
    if not page:isMouseOver() then return false end
    for _,v in pairs(page.inventoryPane.selected) do
        return true
    end
    return false
end

function ISInventoryPane:update()

    local playerObj = getSpecificPlayer(self.player)
    
    if self.doController then
        --print("do controller!")
        if (self.player ~= 0) or (wasMouseActiveMoreRecentlyThanJoypad() == false) then
            table.wipe(self.selected)
        end
        if self.joyselection == nil then
            self.joyselection = 0
        end
    end
	self:updateTooltip()


    local remove = nil

    for i,v in pairs(self.selected) do
        if instanceof(v, "InventoryItem") then
            if v:getContainer() ~= self.inventory then
                if remove == nil then
                    remove = {}
                end
                remove[i] = i
            end
        end
    end
    if remove ~= nil then
        for i,v in pairs(remove) do
            self.selected[v] = nil
        end
    end


    -- Make it select the header if all sub items in expanded item are selected.
    for i,v in ipairs(self.items) do
        if not instanceof(v, "InventoryItem") and self.selected[i] == nil and not self.collapsed[v.name] then
            local anyNot = false
            for j=2,#v.items do
                if self.selected[i+j-1] == nil then
                    anyNot = true
                    break
                end
            end
            if not anyNot then
                self.selected[i] = v
            end
        end
    end

    -- If the user was dragging items from this pane and the mouse wasn't released over a valid drop location,
    -- then we must clear the drag info.  Additionally, if the mouse was released outside any UIElement, then
    -- we will drop the items onto the floor (unless this pane is displaying the floor container).
    -- NOTE: This only works because update() is called after all the mouse-event handling, so other UIElements
    -- have already had a chance to accept the drag.
    if ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus == self and not isMouseButtonDown(0) then
		if getCore():getGameMode() == "Tutorial" then
            if ISMouseDrag.draggingFocus then
                ISMouseDrag.draggingFocus:onMouseUp(0,0)
            end
            ISMouseDrag.draggingFocus = nil
            ISMouseDrag.dragging = nil
			return
		end
        local dragContainsMovables = false
        local dragContainsNonMovables = false
        local mx = getMouseX()
        local my = getMouseY()
        local uis = UIManager.getUI()
        local mouseOverUI
        for i=0,uis:size()-1 do
            local ui = uis:get(i)
            if ui:isPointOver(mx, my) then
                mouseOverUI = ui
                break
            end
        end

        local noVehicle = true
        local vehicleNoWindow = true
        local vehicleWindowDestroyed = true
        local vehicleWindowOpen = true

        local vehicle = playerObj:getVehicle()

        if vehicle ~= nil then
            noVehicle = false
            local seat = vehicle:getSeat(playerObj)
            local door = vehicle:getPassengerDoor(seat)
            local windowPart = VehicleUtils.getChildWindow(door)
            if windowPart and (not windowPart:getItemType() or windowPart:getInventoryItem()) then
                vehicleNoWindow = false
                local window = windowPart:getWindow()
                if window:isOpenable() and not window:isOpen() then
                    vehicleWindowOpen = false
                end
            end
        end

        if self.inventory:getType() ~= "floor" and not mouseOverUI and (noVehicle or vehicleNoWindow or vehicleWindowOpen) then
            local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
            local dropit = false
            for i,v in ipairs(dragging) do
                if not self.inventory:isInside(v) and not v:isFavorite() then
                    if not instanceof(v, "Moveable") or v:CanBeDroppedOnFloor() then
                            ISInventoryPaneContextMenu.dropItem(v, self.player)
                        dragContainsNonMovables = true
                    else
                        dragContainsMovables = dragContainsMovables or v
                    end
                end
            end
            self.selected = {}
            getPlayerLoot(self.player).inventoryPane.selected = {}
            getPlayerInventory(self.player).inventoryPane.selected = {}
        end
        self.inventoryPage.selectedSqDrop = nil
        self.inventoryPage.render3DItems = {}
        self.dragging = nil
        self.draggedItems:reset()
        ISMouseDrag.dragging = nil
        ISMouseDrag.draggingFocus = nil

        if dragContainsMovables and not dragContainsNonMovables then
            local mo = ISMoveableCursor:new(getSpecificPlayer(self.player))
            getCell():setDrag(mo, mo.player)
            mo:setMoveableMode("place")
            mo:tryInitialItem(dragContainsMovables)
        end
    end

    -- If the user was draggingMarquis from this pane and the mouse wasn't released over a valid location,
    -- then we must clear the drag info.
    if self.draggingMarquis and not isMouseButtonDown(0) then
        self.draggingMarquis = false
    end

    if self.doController then
        return
    end

    local page1 = getPlayerInventory(0)
    local page2 = getPlayerLoot(0)
    if not page1 or not page2 then
        return
    end
    if isCtrlKeyDown() and (isSelectAllPossible(page1) or isSelectAllPossible(page2)) then
        getCore():setIsSelectingAll(true)
    else
        getCore():setIsSelectingAll(false)
    end
    if isCtrlKeyDown() and isKeyDown(Keyboard.KEY_A) and isSelectAllPossible(self.parent) then
        table.wipe(self.selected)
        for k,v in ipairs(self.items) do
            self.selected[k] = v
        end
    end
end

function ISInventoryPane:saveSelection(selected)
    for _,v in pairs(self.selected) do
        if instanceof(v, "InventoryItem") then
            selected[v] = selected[v] or "item"
        else
            selected[v.items[1]] = "group"
        end
    end
    -- Hack for the selection being cleared while dragging items.
    if ISMouseDrag.dragging and (ISMouseDrag.draggingFocus == self) then
        for _,v in ipairs(ISMouseDrag.dragging) do
            if instanceof(v, "InventoryItem") then
                selected[v] = selected[v] or "item"
            else
                selected[v.items[1]] = "group"
            end
        end
    end
    return selected
end

function ISInventoryPane:restoreSelection(selected)
    local row = 1
    for _,v in ipairs(self.itemslist) do
        local item = v.items[1]
        if selected[item] == "group" then
            self.selected[row] = item
        end
        row = row + 1
        if not self.collapsed[v.name] then
            for j=2,#v.items do
                local item2 = v.items[j]
                if selected[item2] then
                    self.selected[row] = item2
                end
                row = row + 1
            end
        end
    end
end

function ISInventoryPane:refreshContainer()
    self.itemslist = {}
    self.itemindex = {}

    if self.collapsed == nil then
        self.collapsed = {}
    end
	if self.selected == nil then
		self.selected = {}
	end

	local selected = self:saveSelection({})
	table.wipe(self.selected)

	local playerObj = getSpecificPlayer(self.player)

	if not self.hotbar then
		self.hotbar = getPlayerHotbar(self.player)
	end

	local isEquipped = {}
	local isInHotbar = {}
	if self.parent.onCharacter then
		local wornItems = playerObj:getWornItems()
		for i=1,wornItems:size() do
			local wornItem = wornItems:get(i-1)
			isEquipped[wornItem:getItem()] = true
		end
		local item = playerObj:getPrimaryHandItem()
		if item then
			isEquipped[item] = true
		end
		item = playerObj:getSecondaryHandItem()
		if item then
			isEquipped[item] = true
		end
		if self.hotbar and self.hotbar.attachedItems then
			for _,item in pairs(self.hotbar.attachedItems) do
				isInHotbar[item] = true
			end
		end
	end

    local expandedItems = 0
    for k, v in pairs(self.collapsed) do
        if not self.collapsed[k] then
            expandedItems = 1
            break
        end
    end

    local it = self.inventory:getItems()
    for i = 0, it:size()-1 do
        local item = it:get(i)
        local add = true
        -- don't add the ZedDmg category, they are just equipped models
        if item:isHidden() then
            add = false
        end
        
        if add and self.parent.onCharacter then
            local config = CleanUIConfig.getConfig()
            local hideEquipped = config["hideEquipped"] or false
            if hideEquipped then
                if isEquipped[item] and (item ~= playerObj:getPrimaryHandItem() and item ~= playerObj:getSecondaryHandItem()) then
                    add = false
                elseif (item:getType() == "KeyRing" or item:hasTag("KeyRing")) and playerObj:getInventory():contains(item) then
                    add = false
                elseif self.hotbar and isInHotbar[item] then
                    add = false
                end
            end
        end
		if add then
			local itemName = item:getName()
			if item:IsFood() and item:getHerbalistType() and item:getHerbalistType() ~= "" then
				if playerObj:isRecipeActuallyKnown("Herbalist") then
					if item:getHerbalistType() == "Berry" then
						itemName = (item:getPoisonPower() > 0) and getText("IGUI_PoisonousBerry") or getText("IGUI_Berry")
					end
					if item:getHerbalistType() == "Mushroom" then
						itemName = (item:getPoisonPower() > 0) and getText("IGUI_PoisonousMushroom") or getText("IGUI_Mushroom")
					end
				else
					if item:getHerbalistType() == "Berry"  then
						itemName = getText("IGUI_UnknownBerry")
					end
					if item:getHerbalistType() == "Mushroom" then
						itemName = getText("IGUI_UnknownMushroom")
					end
				end
				if itemName ~= item:getDisplayName() then
					item:setName(itemName)
				end
				itemName = item:getName()
			end
			local equipped = false
			local inHotbar = false
			if self.parent.onCharacter then
				if isEquipped[item] then
					itemName = "equipped:"..itemName
					equipped = true
				elseif (item:getType() == "KeyRing" or item:hasTag( "KeyRing")) and playerObj:getInventory():contains(item) then
					itemName = "keyring:"..itemName
					equipped = true
				end
				if self.hotbar then
					inHotbar = isInHotbar[item]
					if inHotbar and not equipped then
						itemName = "hotbar:"..itemName
					end
				end
			end

			if self.itemindex[itemName] == nil then
				self.itemindex[itemName] = {}
				self.itemindex[itemName].items = {}
				self.itemindex[itemName].count = 0
			end
			local ind = self.itemindex[itemName]
			ind.equipped = equipped
			ind.inHotbar = inHotbar

			ind.count = ind.count + 1
			ind.items[ind.count] = item
		end
    end

    for k, v in pairs(self.itemindex) do

        if v ~= nil then
            table.insert(self.itemslist, v)
            local count = 1
            local weight = 0
            for k2, v2 in ipairs(v.items) do
                if v2 == nil then
                    table.remove(v.items, k2)
                else
                    count = count + 1
                    weight = weight + v2:getUnequippedWeight()
                end
            end
            v.count = count
            v.invPanel = self
            v.name = k -- v.items[1]:getName()
            v.cat = v.items[1]:getDisplayCategory() or v.items[1]:getCategory()
            v.weight = weight
            if self.collapsed[v.name] == nil then
                self.collapsed[v.name] = true
            end
        end
    end

    table.sort(self.itemslist, self.itemSortFunc )
    
    -- Adding the first item in list additionally at front as a dummy at the start, to be used in the details view as a header.
    for k, v in ipairs(self.itemslist) do
        local item = v.items[1]
        table.insert(v.items, 1, item)
    end

    self:restoreSelection(selected)
    table.wipe(selected)

    self:updateScrollbars()
    self.inventory:setDrawDirty(false)

    -- Update the buttons
    if self:isMouseOver() then
        self:onMouseMove(0, 0)
    end

    self:updateWorldObjectHighlight()
end

function ISInventoryPane:isLiteratureRead(playerObj, item)
    if not item then return false end
    if not item:IsLiterature() then return false end
    local modData = item:hasModData() and item:getModData() or nil
    if modData ~= nil then
        if (modData.literatureTitle) and playerObj:isLiteratureRead(modData.literatureTitle) then return true end
        if (modData.printMedia ~= nil) and playerObj:isPrintMediaRead(modData.printMedia) then return true end
        if (modData.teachedRecipe ~= nil) and playerObj:getKnownRecipes():contains(modData.teachedRecipe) then return true end
    end
    local skillBook = SkillBook[item:getSkillTrained()]
    if (skillBook ~= nil) and (item:getMaxLevelTrained() < playerObj:getPerkLevel(skillBook.perk) + 1) then return true end
    if (item:getNumberOfPages() > 0) and (playerObj:getAlreadyReadPages(item:getFullType()) == item:getNumberOfPages()) then return true end
    if (item:getTeachedRecipes() ~= nil) and playerObj:getKnownRecipes():containsAll(item:getTeachedRecipes()) then return true end
    return false
end

function ISInventoryPane:doWorldObjectHighlight(_item)
    if instanceof(_item, "InventoryItem") then
        local worldItem = _item:getWorldItem()
        if (worldItem and worldItem:getChunk() ~= nil) then
            if not self.highlightItems[worldItem] then
                worldItem:setHighlighted(self.player, true, false)
            end
            self.highlightItems[worldItem] = worldItem
        end
        return true
    end

    return false
end

function ISInventoryPane:clearWorldObjectHighlights()
    for worldItem in pairs(self.highlightItems) do
        if worldItem:getItem() ~= nil then
            worldItem:setHighlighted(self.player, false)
        end
        self.highlightItems[worldItem] = nil
    end
end

function ISInventoryPane:findItemForWorldObjectHighlight(_itemTest)
    if _itemTest then
        if not instanceof(_itemTest, "InventoryItem") then
            if _itemTest.items then
                for _, item in ipairs(_itemTest.items) do
                    --break on an invalid item
                    if not self:doWorldObjectHighlight(item) then
                        break
                    end
                end
            end
        else
            self:doWorldObjectHighlight(_itemTest)
        end
    end
end

function ISInventoryPane:updateWorldObjectHighlight()
    --reset highlights
    self:clearWorldObjectHighlights()

    --controller selected
    if self.doController and self.joyselection ~= nil then
        --joyselection is offset to self.items by +1
        self:findItemForWorldObjectHighlight(self.items[self.joyselection + 1])
    end

    --selected (clicked or draggingMarquis)
    for _, item in ipairs(self.selected) do
        self:findItemForWorldObjectHighlight(item)
    end

    --hovering mouse
    if self.mouseOverOption ~= 0 then
        self:findItemForWorldObjectHighlight(self.items[self.mouseOverOption])
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Layout Manager
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPane:onResizeColumn(button)
    if button == self.nameHeader then
        self.column3 = self.nameHeader.x + self.nameHeader.width
        self.typeHeader:setX(self.column3 - 1)
        self.typeHeader:setWidth(self.width - self.typeHeader.x)
    end
    if button == self.typeHeader then
        self.nameHeader:setWidth(self.typeHeader.x - self.column2 + 1)
        self.column3 = self.typeHeader.x
    end
end

function ISInventoryPane:onResize()
    ISPanel.onResize(self)
    if self.typeHeader:getWidth() == self.typeHeader.minimumWidth then
        self.column3 = self.width - self.typeHeader:getWidth() + 1
        self.nameHeader:setWidth(self.column3 - self.column2)
        self.typeHeader:setX(self.column3 - 1)
    end
    self.column4 = self.width
end

function ISInventoryPane:setMode(mode)
    self.mode = mode
end

function ISInventoryPane:onInventoryFontChanged()
	local font = getCore():getOptionInventoryFont()
	if font == "Large" then
		self.font = UIFont.Large
	elseif font == "Small" then
		self.font = UIFont.Small
	else
		self.font = UIFont.Medium
	end
	self.fontHgt = getTextManager():getFontFromEnum(self.font):getLineHeight()
	self.itemHgt = math.ceil(math.max(18, self.fontHgt) * self.zoom)
    self.texScale = math.min(32, (self.itemHgt - 2)) / 32
    
    self.contextButton1:setFont(self.font)
    self.contextButton2:setFont(self.font)
    self.contextButton3:setFont(self.font)
    self.contextButton1:setHeight(self.itemHgt)
    self.contextButton2:setHeight(self.itemHgt)
    self.contextButton3:setHeight(self.itemHgt)
end

-- ---------------------------------------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------------------------------------- --

function ISInventoryPane:prerender()
	local mouseY = self:getMouseY()
	self:updateSmoothScrolling()
	if mouseY ~= self:getMouseY() and self:isMouseOver() then
		self:onMouseMove(0, self:getMouseY() - mouseY)
	end

	if self.mode == "icons" then
		self:rendericons()
	elseif self.mode == "details" then
		self:renderdetails(false)
	end

    self:setStencilRect(0,0,self.width, self.height)

	self:updateScrollbars()
end

function ISInventoryPane:render()
    if self.mode == "icons" then
        self:rendericons()
    elseif self.mode == "details" then
        self:renderdetails(true)
    end

    local resize = self.nameHeader.resizing or self.nameHeader.mouseOverResize
    if not resize then
        resize = self.typeHeader.resizing or self.typeHeader.mouseOverResize
    end

    if self.mouseOverColumnDivider or self.dividerDragging or resize then
        local dividerX = self.column3 - self.padding - 1
        self:repaintStencilRect(dividerX, 0, 2, self.height)
        self:drawRectStatic(dividerX, 0, 2, self.height, 0.5, 1, 1, 1)
    end

    self:clearStencilRect()

    -- highlight mouseOverOption world objects
    self:updateWorldObjectHighlight()
end

function ISInventoryPane:getProgressBarWidth()
    return 200
end

function ISInventoryPane:getProgressBarHeight()
    local height = 5
    if self.font == UIFont.Medium then
        height = 6
    elseif self.font == UIFont.Large then
        height = 7
    end
    return height
end

function ISInventoryPane:drawProgressBar(x, y, w, h, f, fg)
	if f < 0.0 then f = 0.0 end
	if f > 1.0 then f = 1.0 end
	local done = math.floor(w * f)
	if f > 0 then done = math.max(done, 1) end
	self:drawRect(x-1, y-1, w+2, h, 1.0, 0.25, 0.25, 0.25)
	self:drawRect(x, y, done, h-2, fg.a, fg.r, fg.g, fg.b)
	local bg = {r=0.5, g=0.5, b=0.5, a=1.0}
	self:drawRect(x + done, y, w - done, h-2, bg.a, bg.r, bg.g, bg.b)
end

function ISInventoryPane:drawTextAndProgressBar(text, fraction, xoff, top, fgText, fgBar)
	self:drawText(text, 40 + 30 + xoff, top + (self.itemHgt - self.fontHgt) / 2, fgText.a, fgText.r, fgText.g, fgText.b, self.font)
	local textWid = getTextManager():MeasureStringX(self.font, text)
	self:drawProgressBar(40 + math.max(120, 30 + textWid + 20) + xoff, top+(self.itemHgt/2)-1, self:getProgressBarWidth(), self:getProgressBarHeight(), fraction, fgBar)
end

function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)

    if item == nil then
        return
    end

	local hdrHgt = self.headerHgt
	local top = hdrHgt + y * self.itemHgt + yoff
    local hc = getCore():getGoodHighlitedColor()
    local fgBar = {r=hc:getR(), g=hc:getG(), b=hc:getB(), a=1}
	local fgText = {r=0.6, g=0.8, b=0.5, a=0.6}
	if red then fgText = {r=0.0, g=0.0, b=0.5, a=0.7} end
	if instanceof(item, "HandWeapon") then
		local text = getText("IGUI_invpanel_Condition") .. ":"
		self:drawTextAndProgressBar(text, item:getCondition() / item:getConditionMax(), xoff, top, fgText, fgBar)
	elseif instanceof(item, "Drainable") and not item:hasTag("HideRemaining") then
		local text = getText("IGUI_invpanel_Remaining") .. ":"
		self:drawTextAndProgressBar(text, item:getCurrentUsesFloat(), xoff, top, fgText, fgBar)
    elseif item:getMeltingTime() > 0 then
		local text = getText("IGUI_invpanel_Melting") .. ":"
		self:drawTextAndProgressBar(text, item:getMeltingTime() / 100, xoff, top, fgText, fgBar)
	elseif instanceof(item, "Food") then
		if item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6 then
			local ct = item:getCookingTime()
			local mtc = item:getMinutesToCook()
			local mtb = item:getMinutesToBurn()
			local f = ct / mtc
			local s = getText("IGUI_invpanel_Cooking") .. ":"
			if ct > mtb then
				s = getText("IGUI_invpanel_Burnt") .. ":"
			elseif ct > mtc then
				s = getText("IGUI_invpanel_Burning") .. ":"
				f = (ct - mtc) / (mtb - mtc)
                fgBar.r = getCore():getBadHighlitedColor():getR()
                fgBar.g = getCore():getBadHighlitedColor():getG()
                fgBar.b = getCore():getBadHighlitedColor():getB()
			end	
			self:drawText(s, 40 + 30 + xoff, top + (self.itemHgt - self.fontHgt) / 2, fgText.a, fgText.r, fgText.g, fgText.b, self.font)
			if item:isBurnt() then return end
			local textWid = getTextManager():MeasureStringX(self.font, s)
			self:drawProgressBar(40 + math.max(120, 30 + textWid + 20) + xoff, top+(self.itemHgt/2)-1, self:getProgressBarWidth(), self:getProgressBarHeight(), f, fgBar)
        elseif item:getFreezingTime() > 0 then
			local text = getText("IGUI_invpanel_FreezingTime") .. ":"
			self:drawTextAndProgressBar(text, item:getFreezingTime() / 100, xoff, top, fgText, fgBar)
		else
			local hunger = item:getHungerChange()
			if(hunger ~= 0) then
				local text = getText("IGUI_invpanel_Nutrition") .. ":"
				self:drawTextAndProgressBar(text, (-hunger) / 1.0, xoff, top, fgText, fgBar)
			else
				self:drawText(item:getName(), 40 + 30 + xoff, top + (self.itemHgt - self.fontHgt) / 2, fgText.a, fgText.r, fgText.g, fgText.b, self.font)
			end
		end
   else
		self:drawText(item:getName(), 40 + 30 + xoff, top + (self.itemHgt - self.fontHgt) / 2, fgText.a, fgText.r, fgText.g, fgText.b, self.font)
   end
end

function ISInventoryPane:rendericons()
    local xpad = 10
    local ypad = 10
    local slotSize = self.fontHgt*2
    local iconSize = math.floor(slotSize * 0.6)
    local iconOffset = math.floor((slotSize - iconSize) / 2)
    
    local xmax = math.floor((self.width - (xpad * 2)) / slotSize)
    local xcount = 0
    local ycount = 0

    if not self.items then
        self.items = {}
    end
    table.wipe(self.items)

    if self.itemslist == nil then
        self:refreshContainer()
    end
    
    local itemIndex = 1

    for k, v in ipairs(self.itemslist) do
        local slotX = (xcount * slotSize) + xpad
        local slotY = (ycount * slotSize) + ypad
        local iconX = slotX + iconOffset
        local iconY = slotY + iconOffset

        local displayItem = v.items[1]
        self.items[itemIndex] = v

        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()
        if mouseX >= slotX and mouseX <= slotX + slotSize and 
           mouseY >= slotY and mouseY <= slotY + slotSize then
            self.mouseOverOption = itemIndex

            self:drawRect(slotX, slotY, slotSize, slotSize, 0.3, 1.0, 1.0, 1.0)
        end

        if self.selected and self.selected[itemIndex] then
            self:drawRect(slotX, slotY, slotSize, slotSize, 0.5, 0.2, 0.8, 1.0)
        end

        self:drawRect(slotX, slotY, slotSize, slotSize, 0.2, 0.2, 0.2, 0.2)

        ISInventoryItem.renderItemIcon(self, displayItem, iconX, iconY, 1.0, iconSize, iconSize)

        if v.count > 2 then
            local countText = tostring(v.count - 1)
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, countText)
            local textHeight = getTextManager():getFontHeight(UIFont.Small)
            self:drawText(countText, slotX + slotSize - textWidth - 2, slotY + slotSize - textHeight - 2, 1, 1, 1, 1, UIFont.Small)
        end
        
        itemIndex = itemIndex + 1
        xcount = xcount + 1

        if xcount >= xmax then
            xcount = 0
            ycount = ycount + 1
        end
    end

    local totalRows = math.ceil(#self.itemslist / xmax)
    self:setScrollHeight(totalRows * slotSize + ypad * 2)
end

function ISInventoryPane:renderdetails(doDragged)

    self:updateScrollbars()
    local scrollBarWid = self:isVScrollBarVisible() and self.vscroll.width or 0
    if doDragged == false then
        table.wipe(self.items)

        if self.inventory:isDrawDirty() then
            self:refreshContainer()
        end
    end
    
    local player = getSpecificPlayer(self.player)

    local checkDraggedItems = false
    if doDragged and self.dragging ~= nil and self.dragStarted then
        self.draggedItems:update()
        checkDraggedItems = true
    end

    local y = 0
    local alt = false
    if self.itemslist == nil then
        self:refreshContainer()
    end
    local MOUSEX = self:getMouseX()
    local MOUSEY = self:getMouseY()
    local YSCROLL = self:getYScroll()
    local HEIGHT = self:getHeight()
    local equippedLine = false
    local all3D = true
    -- Go through all the stacks of items.
    for k, v in ipairs(self.itemslist) do
        local count = 1
        -- Go through each item in stack..
        for k2, v2 in ipairs(v.items) do
           -- print("trace:a")
            local item = v2
            local doIt = true
            local xoff = 0
            local yoff = 0
            if doDragged == false then
                -- if it's the first item, then store the category, otherwise the item
                if count == 1 then
                    table.insert(self.items, v)
                else
                    table.insert(self.items, item)
                end

                if instanceof(item, 'InventoryItem') then
                    item:updateAge()
                end
                if instanceof(item, 'Clothing') then
                    item:updateWetness()
                end
            end
            local isDragging = false
            if self.dragging ~= nil and self.selected[y+1] ~= nil and self.dragStarted then
                xoff = MOUSEX - self.draggingX
                yoff = MOUSEY - self.draggingY
                if not doDragged then
                    doIt = false
                else
                    self:suspendStencil()
                    isDragging = true
                end
            else
                if doDragged then
                    doIt = false
                end
            end
            --[[
            local topOfItem = y * self.itemHgt + YSCROLL
            if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
                doIt = false
            end
            ]]

            local topOfItem = y * self.itemHgt + YSCROLL
            local bottomOfItem = topOfItem + self.itemHgt
            if not isDragging and (bottomOfItem < 0 or topOfItem > HEIGHT) then
                doIt = false
            end
            if doIt == true then
                if count == 1 then
                end
                if self.joyselection ~= nil and self.doController then
                    if self.joyselection == y then
                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self:getWidth()-1, self.itemHgt, 0.2, 0.2, 1.0, 1.0)
                    end
                end

                -- only do icon if header or dragging sub items without header.
                local tex = item:getTex()
                if tex ~= nil then
					local texDY = 0
					local texWH = math.min(self.itemHgt-2,32)
					local auxDXY = self.itemHgt-(self.itemHgt-texWH)/2-13
                    local texOffsetY = (y*self.itemHgt)+(self.itemHgt-texWH)/2+self.headerHgt+yoff
                    local texOffsetX = self.column2-texWH-(self.itemHgt-texWH)/2+xoff
                    if count == 1  then
                        --ISInventoryItem.renderItemIcon(self, item, 10+xoff, (y*self.itemHgt)+self.headerHgt+texDY+yoff, 1.0, texWH, texWH)
                        ISInventoryItem.renderItemIcon(self, item, texOffsetX, texOffsetY+texDY, 1.0, texWH, texWH)
						--self:drawTextureScaledAspect(tex, 10+xoff, (y*self.itemHgt)+self.headerHgt+texDY+yoff, texWH, texWH, 1, item:getR(), item:getG(), item:getB())
						if player:isEquipped(item) then
							self:drawTexture(self.equippedItemIcon, texOffsetX+auxDXY, texOffsetY+auxDXY, 1, 1, 1, 1)
						end
						if not self.hotbar then
							self.hotbar = getPlayerHotbar(self.player)
						end
						if not player:isEquipped(item) and self.hotbar and self.hotbar:isInHotbar(item) then
							self:drawTexture(self.equippedInHotbar, texOffsetX+auxDXY, texOffsetY+auxDXY, 1, 1, 1, 1)
						end
                        if item:isBroken() then
                            self:drawTexture(self.brokenItemIcon, texOffsetX+auxDXY, texOffsetY+auxDXY-1, 1, 1, 1, 1)
                        end
                        if instanceof(item, "Food") and item:isFrozen() then
                            self:drawTexture(self.frozenItemIcon, texOffsetX+auxDXY, texOffsetY+auxDXY-1, 1, 1, 1, 1)
                        end
                        if instanceof(item, "Food") and(item:isTainted() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue()) or player:isKnownPoison(item) or item:hasTag("ShowPoison") then
                            self:drawTexture(self.poisonIcon, texOffsetX+auxDXY, texOffsetY+auxDXY-1, 1, 1, 1, 1)
                        end
                        if self:isLiteratureRead(player, item) then
                            self:drawTexture(getTexture("media/ui/Tick_Mark-10.png"), texOffsetX+auxDXY, texOffsetY+auxDXY-1, 1, 1, 1, 1)
                        end
                        local fluidContainer = item:getFluidContainer() or (item:getWorldItem() and item:getWorldItem():getFluidContainer())
						if fluidContainer ~= nil and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() and (not fluidContainer:isEmpty()) and (fluidContainer:contains(Fluid.Bleach) or (fluidContainer:contains(Fluid.TaintedWater) and fluidContainer:getPoisonRatio() > 0.1)) then
							self:drawTexture(self.poisonIcon, (10+auxDXY+xoff), (y*self.itemHgt)+self.headerHgt+auxDXY-1+yoff, 1, 1, 1, 1)
						end
                        if item:isFavouriteRecipeInput(player) then
                            self:drawTextureScaled(self.favoriteRecipeInputStar, texOffsetX, texOffsetY+auxDXY, favoriteRecipeInputStarSize, favoriteRecipeInputStarSize, 1,0.8,0.2,0.2)
                        end
                    elseif v.count > 2 or (doDragged and count > 1 and self.selected[(y+1) - (count-1)] == nil) then
                        -- removed the fade effect on items in stacks as it makes it difficult to tell what color clothing and bags in stacks are
                        -- we also have variable icons for items now as well, so that makes it difficult as well when they are in stacks
                        ISInventoryItem.renderItemIcon(self, item, 10+16+xoff, texOffsetY+texDY, 1.0, texWH, texWH)
						if player:isEquipped(item) then
							self:drawTexture(self.equippedItemIcon, texOffsetX+auxDXY+16, texOffsetY+auxDXY, 1, 1, 1, 1)
                        end
                        if item:isBroken() then
                            self:drawTexture(self.brokenItemIcon, texOffsetX+auxDXY+16, texOffsetY+auxDXY-1, 1, 1, 1, 1)
                        end
                        if instanceof(item, "Food") and item:isFrozen() then
                            self:drawTexture(self.frozenItemIcon, texOffsetX+auxDXY+16, texOffsetY+auxDXY-1, 1, 1, 1, 1)
                        end
                        if item:isFavouriteRecipeInput(player) then
                            self:drawTextureScaled(self.favoriteRecipeInputStar, texOffsetX, texOffsetY+auxDXY, favoriteRecipeInputStarSize, favoriteRecipeInputStarSize, 1,0.8,0.2,0.2)
                        end
                    end
                end
                if count == 1 and v.count > 2 then
					if not doDragged then
                        local texWH = math.min(self.itemHgt-2,32)
                        local texOffsetX = self.column2-texWH-(self.itemHgt-texWH)/2+xoff
                        local size = math.min(15, 8+getCore():getOptionFontSizeReal()*2)
                        local xPos = math.max(2, (2+texOffsetX-size)/2)
                        if not self.collapsed[v.name] then
                            self:drawTextureScaled(self.treeexpicon, xPos, (y*self.itemHgt)+self.headerHgt+(self.itemHgt-15)/2+yoff, size, size, 1, 0.6, 0.6, 0.6)
                        else
                            self:drawTextureScaled(self.treecolicon, xPos, (y*self.itemHgt)+self.headerHgt+(self.itemHgt-15)/2+yoff, size, size, 1, 0.6, 0.6, 0.6)
                        end
                    end
                end
                if self.selected[y+1] ~= nil and not self.highlightItem then -- clicked/dragged item
					if checkDraggedItems and self.draggedItems:cannotDropItem(item) then
                        local bgWidth = self:getWidth() - 1 - scrollBarWid
                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, bgWidth, self.itemHgt, 0.20, 1.0, 0.0, 0.0)
					elseif false and (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() ~= 1) or item:getItemHeat() ~= 1) then
						if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() > 1) or item:getItemHeat() > 1) then
							self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.5, math.abs(item:getInvHeat()), 0.0, 0.0)

						else
							self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.5, 0.0, 0.0, math.abs(item:getInvHeat()))
						end
                    else
                        local bgWidth = self:getWidth() - 1 - scrollBarWid
                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, bgWidth, self.itemHgt, 0.20, 1.0, 1.0, 1.0)
					end
                elseif self.mouseOverOption == y+1 and not self.highlightItem then -- called when you mose over an element
					if(((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() ~= 1) or item:getItemHeat() ~= 1) then
                        if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() > 1) or item:getItemHeat() > 1) then
							self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.3, math.abs(item:getInvHeat()), 0.0, 0.0)
						else
							self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.3, 0.0, 0.0, math.abs(item:getInvHeat()))
						end
                    else
                        local bgWidth = self:getWidth() - 1 - scrollBarWid
                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, bgWidth, self.itemHgt, 0.05, 1.0, 1.0, 1.0)
					end
                else
                    if count == 1 then
						-- background of item line
                        if self.highlightItem and self.highlightItem == item:getType() then
                            if not self.blinkAlpha then self.blinkAlpha = 0.5 end
                            self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  self.blinkAlpha, 1, 1, 1)
                            if not self.blinkAlphaIncrease then
                                self.blinkAlpha = self.blinkAlpha - 0.05 * (UIManager.getMillisSinceLastRender() / 33.3)
                                if self.blinkAlpha < 0 then
                                    self.blinkAlpha = 0
                                    self.blinkAlphaIncrease = true
                                end
                            else
                                self.blinkAlpha = self.blinkAlpha + 0.05 * (UIManager.getMillisSinceLastRender() / 33.3)
                                if self.blinkAlpha > 0.5 then
                                    self.blinkAlpha = 0.5
                                    self.blinkAlphaIncrease = false
                                end
                            end
                        else
                            if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() ~= 1) or item:getItemHeat() ~= 1) then
                                if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() > 1) or item:getItemHeat() > 1) then
                                    if alt then
                                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.15, math.abs(item:getInvHeat()), 0.0, 0.0)
                                    else
                                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.2, math.abs(item:getInvHeat()), 0.0, 0.0)
                                    end
                                else
                                    if alt then
                                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.15, 0.0, 0.0, math.abs(item:getInvHeat()))
                                    else
                                        self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.2, 0.0, 0.0, math.abs(item:getInvHeat()))
                                    end
                                end
                            end
                        end
                    else
                        if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() ~= 1) or item:getItemHeat() ~= 1) then
                            if (((instanceof(item,"Food") or instanceof(item,"DrainableComboItem")) and item:getHeat() > 1) or item:getItemHeat() > 1) then
								self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.2, math.abs(item:getInvHeat()), 0.0, 0.0)
							else
								self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.2, 0.0, 0.0, math.abs(item:getInvHeat()))
							end
						else
							self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, self.column4 - scrollBarWid, self.itemHgt,  0.4, 0.0, 0.0, 0.0)
						end
                    end
                end
                -- divider between equipped and unequipped items
                if v.equipped then
                    if not doDragged and not equippedLine and y > 0 then
                        local lineWidth = self.column4 - scrollBarWid
                        self:drawRect(1, ((y+1)*self.itemHgt)+self.headerHgt-1-self.itemHgt, lineWidth, 1, 0.2, 1, 1, 1)
                    end
                    equippedLine = true
                end

                if item:getJobDelta() > 0 and (count > 1 or self.collapsed[v.name]) then
                    local displayWid = self.column4 - scrollBarWid
                    self:drawRect(1+xoff, (y*self.itemHgt)+self.headerHgt+yoff, displayWid * item:getJobDelta(), self.itemHgt, 0.2, 0.4, 1.0, 0.3)
                end

				local textDY = (self.itemHgt - self.fontHgt) / 2

                local itemName = item:getName()
                if count == 1 then

					-- if we're dragging something and want to put it in a container wich is full
					if doDragged and ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
						local red = false
						if red then
							if v.count > 2 then
								self:drawText(itemName.." ("..(v.count-1)..")", self.column2+self.padding+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, 0.7, 0.0, 0.0, 1.0, self.font)
							else
								self:drawText(itemName, self.column2+self.padding+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, 0.7, 0.0, 0.0, 1.0, self.font)
							end
						else
							if v.count > 2 then
								self:drawText(itemName.." ("..(v.count-1)..")", self.column2+self.padding+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, 0.7, 0.7, 0.7, 1.0, self.font)
							else
								self:drawText(itemName, self.column2+self.padding+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, 0.7, 0.7, 0.7, 1.0, self.font)
							end
						end
					else
                        local favoriteIconSize = math.min(self.itemHgt - 4, 16)
                        local favoriteIconOffset = 0

                        if item:isFavorite() then
                            self:drawTextureScaled(self.favoriteStar, self.column2+self.padding+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff + (self.fontHgt - favoriteIconSize) / 2, favoriteIconSize, favoriteIconSize, 1, 1, 1, 1)
                            favoriteIconOffset = favoriteIconSize + 4
                        end

                        local maxNameWidth = math.floor(self.column3 - self.column2 - self.padding - favoriteIconOffset)

                        if v.count > 2 then
                            local fullText = itemName.." ("..(v.count-1)..")"
                            local nameColor = CleanUI_getItemNameColor()
                            local truncatedText = CleanUI.truncateText(fullText, maxNameWidth, self.font)
                            self:drawText(truncatedText, self.column2+self.padding+favoriteIconOffset+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, nameColor.r, nameColor.g, nameColor.b, nameColor.a, self.font)
                        else
                            local nameColor = CleanUI_getItemNameColor()
                            local truncatedText = CleanUI.truncateText(itemName, maxNameWidth, self.font)
                            self:drawText(truncatedText, self.column2+self.padding+favoriteIconOffset+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, nameColor.r, nameColor.g, nameColor.b, nameColor.a, self.font)
                        end
					end
                end

                if item:getJobDelta() > 0  then
                    if  (count > 1 or self.collapsed[v.name]) then
                        local rightBoundary = self.width - self.padding - scrollBarWid
                        local maxJobTextWidth = math.floor(rightBoundary - self.column3 - self.padding)

                        local jobText = item:getJobType()
                        local truncatedJobText = CleanUI.truncateText(jobText, maxJobTextWidth, self.font)

                        if self.dragging == count then
                            self:drawTextRight(truncatedJobText, rightBoundary+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, 0.7, 0.0, 0.0, 1.0, self.font)
                        else
                            self:drawTextRight(truncatedJobText, rightBoundary+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, 0.7, 0.7, 0.7, 1.0, self.font)
                        end
                    end
                else
                    if count == 1 then
                        local rightBoundary = self.width - self.padding - scrollBarWid
                        local maxCategoryWidth = math.floor(rightBoundary - self.column3 - self.padding)
                        
                        if doDragged then
                            -- Don't draw the category when dragging
                        elseif item:getDisplayCategory() then
                            local categoryColor = CleanUI_getItemCategoryColor()
                            local categoryText = getText("IGUI_ItemCat_" .. item:getDisplayCategory())
                            local truncatedCategory = CleanUI.truncateText(categoryText, maxCategoryWidth, self.font)
                            self:drawTextRight(truncatedCategory, rightBoundary+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, categoryColor.r, categoryColor.g, categoryColor.b, categoryColor.a, self.font)
                        else
                            local categoryColor = CleanUI_getItemCategoryColor()
                            local categoryText = getText("IGUI_ItemCat_" .. item:getCategory())
                            local truncatedCategory = CleanUI.truncateText(categoryText, maxCategoryWidth, self.font)
                            self:drawTextRight(truncatedCategory, rightBoundary+xoff, (y*self.itemHgt)+self.headerHgt+textDY+yoff, categoryColor.r, categoryColor.g, categoryColor.b, categoryColor.a, self.font)
                        end
                    else
                        local redDetail = false
                        self:drawItemDetails(item, y, xoff, yoff, redDetail)
                    end
                end
                if self.selected ~= nil and self.selected[y+1] ~= nil then
                    self:resumeStencil()
                end

            end
            if count == 1 then
                if alt == nil then alt = false end
                alt = not alt
            end

            y = y + 1

            if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
                if instanceof(item, "Food") then
                    -- Update all food items in a collapsed stack so they separate when freshness changes.
                    for k3,v3 in ipairs(v.items) do
                        v3:updateAge()
                    end
                end
                break
            end
            if count == ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER + 1 then
                break
            end
            count = count + 1
        end
	end

    self:setScrollHeight(y * self.itemHgt)
	self:setScrollWidth(0)

	if self.draggingMarquis then
		local w = self:getMouseX() - self.draggingMarquisX
		local h = self:getMouseY() - self.draggingMarquisY
		self:drawRectBorder(self.draggingMarquisX, self.draggingMarquisY, w, h, 0.4, 0.9, 0.9, 1)
    end
end