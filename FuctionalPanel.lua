-- THIS IS A MODDER'S CUSTOM FILE --
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane" 
require "ISUI/ISTextEntryBox" 
require "ISUI/CleanUI_Helper"

FuctionalPanel = ISPanel:derive("FuctionalPanel")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ---------------------------------------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:initialise()
    ISPanel.initialise(self)
end

function FuctionalPanel:new(x, y, width, height, inventoryPage)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.inventoryPage = inventoryPage
    o.inventoryPane = inventoryPage.inventoryPane
    o.moveWithMouse = false
    o.inventoryPanefont = inventoryPage.inventoryPane.font
    o.inventoryPanefontHgt = inventoryPage.inventoryPane.fontHgt
    o.padding = FONT_HGT_SMALL *0.4
    o.buttonSize = math.floor(o.inventoryPanefontHgt*1.2)
    o.searchBoxWidth = FONT_HGT_SMALL * 6

    o.searchBoxTex = {
        Left = getTexture("media/ui/CleanUI/Button/SraechBox_L.png"),
        Middle = getTexture("media/ui/CleanUI/Button/SraechBox_M.png"),
        Right = getTexture("media/ui/CleanUI/Button/SraechBox_R.png")
    }

    o.searchIconTex = getTexture("media/ui/CleanUI/ICON/Icon_Search.png")
    o.expandIconTex = getTexture("media/ui/CleanUI/ICON/Icon_CollapsedIcon.png")
    o.collapseIconTex = getTexture("media/ui/CleanUI/ICON/Icon_ExpandedIcon.png")
    o.weightIconTex = getTexture("media/ui/CleanUI/ICON/Icon_Weight.png")
    o.dropCategoryIconTex = getTexture("media/ui/CleanUI/ICON/Icon_Drop.png") 
    o.lootCategoryIconTex = getTexture("media/ui/CleanUI/ICON/Icon_Loot.png") 
    o.nameIconTex = getTexture("media/ui/CleanUI/ICON/Icon_SortByName.png")
    o.typeIconTex = getTexture("media/ui/CleanUI/ICON/Icon_SortByType.png")
    o.lockIconTex = getTexture("media/ui/CleanUI/ICON/Icon_Lock.png")
    o.unlockIconTex = getTexture("media/ui/CleanUI/ICON/Icon_UnLock.png")
    o.hideEquippedIconTex = getTexture("media/ui/CleanUI/ICON/Icon_HideEquipped.png")
    o.showEquippedIconTex = getTexture("media/ui/CleanUI/ICON/Icon_ShowEquipped.png")
    o.ButtonHoverTex = getTexture("media/ui/CleanUI/ICON/Icon_FunctionalButton_Hover.png")
    o.clearSearchIconTex = getTexture("media/ui/CleanUI/ICON/Icon_Close.png")

    o.isSearchVisible = false
    o.isAllExpanded = false
    o.isWeightSortAscending = true

    return o
end

function FuctionalPanel:createChildren()
    -- Search Button
    self.searchButton = CleanUI_SquareButton:new(self.padding, (self.height - self.buttonSize) / 2, self.buttonSize, self.searchIconTex, self, FuctionalPanel.toggleSearch)
    self.searchButton:initialise()
    self.searchButton.tooltip = getText("UI_CleanUI_SearchTooltip") 
    self:addChild(self.searchButton)
    
    -- Expand / Collapse Button
    self.expandCollapseButton = CleanUI_SquareButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize, self.expandIconTex, self, FuctionalPanel.toggleExpandCollapseAll)
    self.expandCollapseButton:initialise()
    self.expandCollapseButton.tooltip = getText("UI_CleanUI_ExpandCollapseTooltip")
    self.expandCollapseButton.update = function()
        if self.isAllExpanded then
            self.expandCollapseButton:setIcon(self.collapseIconTex)
        else
            self.expandCollapseButton:setIcon(self.expandIconTex)
        end
    end
    self:addChild(self.expandCollapseButton)

    -- Sort By Weight
    self.weightSortButton = CleanUI_SquareButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize, self.weightIconTex, self, FuctionalPanel.toggleWeightSort)
    self.weightSortButton:initialise()
    self.weightSortButton.tooltip = getText("UI_CleanUI_WeightSortTooltip")
    self:addChild(self.weightSortButton)
    
    -- Search Text Box
    self.searchField = ISTextEntryBox:new("", 0, (self.height - self.buttonSize) / 2, self.searchBoxWidth, self.buttonSize)
    self.searchField:initialise()
    self.searchField:setFont(self.inventoryPanefont)
    self.searchField.onTextChange = function()
        local searchFilter = self.searchField:getInternalText()
        self:onSearchContainer(searchFilter)
    end
    self.searchField.prerender = function()
        CleanUI.ThreePatch.drawHorizontal(self.searchField, -self.padding/2, 0, self.searchBoxWidth + self.padding, self.buttonSize, self.searchBoxTex.Left, self.searchBoxTex.Middle, self.searchBoxTex.Right, 1, 0.4, 0.4, 0.4)
    end
    self.searchField:setVisible(false) 
    self:addChild(self.searchField)

    -- Clear Search
    self.searchClearButton = ISButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize,self.buttonSize, "", self, FuctionalPanel.clearSearch)
    self.searchClearButton:initialise()
    self.searchClearButton:setVisible(false)
    self.searchClearButton.prerender = function()
        local iconSize = math.floor(self.buttonSize * 0.6)
        self.searchClearButton:drawTextureScaled(self.clearSearchIconTex, math.floor((self.buttonSize-iconSize)/2), math.floor((self.buttonSize-iconSize)/2), iconSize, iconSize, 1, 0.6, 0.6, 0.6)
    end
    self:addChild(self.searchClearButton)
    
    -- Sort By Name
    self.nameButton = CleanUI_SquareButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize, self.nameIconTex, self, FuctionalPanel.sortByName)
    self.nameButton:initialise()
    self.nameButton.tooltip = getText("UI_CleanUI_NameSortTooltip")
    self:addChild(self.nameButton)
    
    -- Sort By Type
    self.typeButton = CleanUI_SquareButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize, self.typeIconTex, self, FuctionalPanel.sortByType)
    self.typeButton:initialise()
    self.typeButton.tooltip = getText("UI_CleanUI_TypeSortTooltip")
    self:addChild(self.typeButton)
    
    -- Transfer Items By ...
    self.categoryTransferButton = CleanUI_SquareButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize, self.dropCategoryIconTex, self, FuctionalPanel.onCategoryTransferClick)
    self.categoryTransferButton:initialise()
    self.categoryTransferButton.tooltip = getText("UI_CleanUI_CategoryTransferTooltip")
    self.categoryTransferButton.update = function()
        if not self.inventoryPage.onCharacter then 
            self.categoryTransferButton:setIcon(self.lootCategoryIconTex)
        else
            self.categoryTransferButton:setIcon(self.dropCategoryIconTex)
        end
    end
    self.categoryTransferButton.onRightMouseDown = self.categoryTransferButton.onMouseDown
    self.categoryTransferButton.onRightMouseUp = function(_, x, y) FuctionalPanel.onCategoryTransferRightClick(self) end
    self:addChild(self.categoryTransferButton)

    -- Lock/Unlock
    self.lockButton = CleanUI_SquareButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize, self.unlockIconTex, self, FuctionalPanel.toggleLock)
    self.lockButton:initialise()
    self.lockButton.tooltip = getText("UI_CleanUI_LockTooltip")
    self.lockButton.update = function()
        if self:getconfig("lockPanel", false) then 
            self.lockButton:setIcon(self.lockIconTex)
        else
            self.lockButton:setIcon(self.unlockIconTex)
        end
    end
    self:addChild(self.lockButton)

    -- hide Equipped
    self.hideEquippedButton = CleanUI_SquareButton:new(0, (self.height - self.buttonSize) / 2, self.buttonSize, self.showEquippedIconTex, self, FuctionalPanel.toggleHideEquipped)
    self.hideEquippedButton:initialise()
    self.hideEquippedButton.tooltip = getText("UI_CleanUI_HideEquippedTooltip")
    self.hideEquippedButton:setVisible(false)
    self.hideEquippedButton.update = function()
        if self:getconfig("hideEquipped", false) then
            self.hideEquippedButton:setIcon(self.hideEquippedIconTex)
        else
            self.hideEquippedButton:setIcon(self.showEquippedIconTex)
        end
    end
    self:addChild(self.hideEquippedButton)

    self:updateButtonPositions()
end

-- ---------------------------------------------------------------------------------------- --
-- updateButtonPositions
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:updateButtonPositions()
    local currentX = self.padding

    self.searchButton:setX(currentX)
    currentX = currentX + self.searchButton:getWidth() + self.padding

    if self.isSearchVisible then
        self.searchField:setX(currentX)
        currentX = currentX + self.searchField:getWidth() - self.searchClearButton:getWidth()

        self.searchClearButton:setX(currentX)
        currentX = currentX + self.searchClearButton:getWidth() + self.padding
    end

    self.categoryTransferButton:setX(currentX)
    currentX = currentX + self.categoryTransferButton:getWidth() + self.padding

    if self.inventoryPage.onCharacter then
        self.hideEquippedButton:setVisible(true)
        self.hideEquippedButton:setX(currentX)
        currentX = currentX + self.hideEquippedButton:getWidth() + self.padding
    end

    self.lockButton:setX(currentX)
    currentX = currentX + self.lockButton:getWidth() + self.padding

    self.expandCollapseButton:setX(currentX)
    currentX = currentX + self.expandCollapseButton:getWidth() + self.padding

    self.weightSortButton:setX(currentX)
    currentX = currentX + self.weightSortButton:getWidth() + self.padding

    self.nameButton:setX(currentX)
    currentX = currentX + self.nameButton:getWidth() + self.padding

    self.typeButton:setX(currentX)
end
-- ---------------------------------------------------------------------------------------- --
-- Sort Items
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:sortByName()
    local pane = self.inventoryPane
    if pane.itemSortFunc == ISInventoryPane.itemSortByNameInc then
        pane.itemSortFunc = ISInventoryPane.itemSortByNameDesc
    else
        pane.itemSortFunc = ISInventoryPane.itemSortByNameInc
    end
    pane:refreshContainer()
end

function FuctionalPanel:sortByType()
    local pane = self.inventoryPane
    if pane.itemSortFunc == ISInventoryPane.itemSortByCatInc then
        pane.itemSortFunc = ISInventoryPane.itemSortByCatDesc
    else
        pane.itemSortFunc = ISInventoryPane.itemSortByCatInc
    end
    pane:refreshContainer()
end

function FuctionalPanel:toggleWeightSort()
    local pane = self.inventoryPane
    self.isWeightSortAscending = not self.isWeightSortAscending
    
    if self.isWeightSortAscending then
        pane.itemSortFunc = ISInventoryPane.itemSortByWeightAsc
    else
        pane.itemSortFunc = ISInventoryPane.itemSortByWeightDesc
    end
    
    pane:refreshContainer()
end

-- ---------------------------------------------------------------------------------------- --
-- Expand / Collapse
-- ---------------------------------------------------------------------------------------- --

function FuctionalPanel:toggleExpandCollapseAll()
    if not self.inventoryPage or not self.inventoryPane then return end
    self.isAllExpanded = not self.isAllExpanded
    
    if self.isAllExpanded then
        self.inventoryPane:expandAll()
    else
        self.inventoryPane:collapseAll()
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Lock / Unlock
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:toggleLock()
    local islock = self:getconfig("lockPanel", false)

    CleanUIConfig.updateConfig("lockPanel", not islock)

    self.inventoryPage:setPagelocked()
end


-- ---------------------------------------------------------------------------------------- --
-- Search
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:toggleSearch()
    self.isSearchVisible = not self.isSearchVisible
    self.searchField:setVisible(self.isSearchVisible)
    self.searchClearButton:setVisible(self.isSearchVisible)
    
    self:updateButtonPositions()
    
    if self.isSearchVisible then
        self.searchField:focus()
        local currentText = self.searchField:getInternalText()
        if currentText and currentText ~= "" then
            self.inventoryPane:searchContainer(currentText)
        end
    else
        self.searchField:setText("")
        self.inventoryPane:clearSearch()
    end
end


function FuctionalPanel:onSearchContainer(searchFilter)
    self.inventoryPane:searchContainer(searchFilter)
end

function FuctionalPanel:clearSearch()
    self.searchField:setText("")
    self.searchField:focus()
    self.inventoryPane:clearSearch()
end

-- ---------------------------------------------------------------------------------------- --
-- Hide Equipped
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:toggleHideEquipped()
    local ishide = self:getconfig("hideEquipped", false)
    
    CleanUIConfig.updateConfig("hideEquipped",  not ishide)
    
    self.inventoryPane:refreshContainer()
end

-- ---------------------------------------------------------------------------------------- --
-- CategoryTransfer
-- ---------------------------------------------------------------------------------------- --

function FuctionalPanel:onCategoryTransferClick()
    local playerData = getPlayerData(self.inventoryPage.player)
    local playerInventory = playerData.playerInventory.inventory
    local lootInventory = playerData.lootInventory.inventory
    
    local source, destination
    if self.inventoryPage.onCharacter then
        source = playerInventory
        destination = lootInventory
    else
        source = lootInventory
        destination = playerInventory
    end
    
    if CleanUI_getTransferMethod() == "2" then
        self:transferItemsByName(source, destination)
    else
        self:transferItemsByCategory(source, destination)
    end
end

function FuctionalPanel:transferItemsByCategory(source, destination)
    local playerObj = getSpecificPlayer(self.inventoryPage.player)
    local categories = {}
    local destItems = destination:getItems()

    for i = 0, destItems:size() - 1 do
        local item = destItems:get(i)
        local category = item:getDisplayCategory()
        if category then
            categories[category] = true
        end
    end

    local sourceItems = source:getItems()
    for i = 0, sourceItems:size() - 1 do
        local item = sourceItems:get(i)
        local category = item:getDisplayCategory()
        if category and categories[category] and not item:isFavorite() and not playerObj:isEquipped(item) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), destination))
        end
    end
end

function FuctionalPanel:transferItemsByName(source, destination)
    local playerObj = getSpecificPlayer(self.inventoryPage.player)
    local names = {}
    local destItems = destination:getItems()

    for i = 0, destItems:size() - 1 do
        local item = destItems:get(i)
        local name = item:getName()
        if name then
            names[name] = true
        end
    end

    local sourceItems = source:getItems()
    for i = 0, sourceItems:size() - 1 do
        local item = sourceItems:get(i)
        local name = item:getName()
        if name and names[name] and not item:isFavorite() and not playerObj:isEquipped(item) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), destination))
        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- CategoryTransfer (Right Click)
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:onCategoryTransferRightClick()
    local player = self.inventoryPage.player
    local playerData = getPlayerData(player)
    
    local source
    if self.inventoryPage.onCharacter then
        source = playerData.playerInventory.inventory
    else
        source = playerData.lootInventory.inventory
    end
    
    local useNameMethod = CleanUI_getTransferMethod() == "2"
    self:stackItems(source, useNameMethod)
end

function FuctionalPanel:stackItems(source, useNameMethod)
    local playerObj = getSpecificPlayer(self.inventoryPage.player)
    local hotBar = getPlayerHotbar(self.inventoryPage.player)

    local destinationContainers = {}
    local targetPage
    if source:isInCharacterInventory(playerObj) then
        targetPage = getPlayerLoot(self.inventoryPage.player)
    else
        targetPage = getPlayerInventory(self.inventoryPage.player)
    end

    if targetPage and targetPage.backpacks then
        for _, backpack in ipairs(targetPage.backpacks) do
            table.insert(destinationContainers, backpack.inventory)
        end
    end

    local addedWeight = {}
    for _, container in ipairs(destinationContainers) do
        addedWeight[container] = 0.0
    end

    local itemGroups = {}
    local items = source:getItems()
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if not item:isEquipped() and not item:isFavorite() and not hotBar:isInHotbar(item) and item:getType() ~= "KeyRing" then
            local groupKey
            if useNameMethod then
                groupKey = item:getName()
            else
                groupKey = item:getDisplayCategory()
            end
            
            if groupKey then
                if not itemGroups[groupKey] then
                    itemGroups[groupKey] = {}
                end
                table.insert(itemGroups[groupKey], item)
            end
        end
    end

    for groupKey, groupItems in pairs(itemGroups) do
        for _, item in ipairs(groupItems) do
            for _, container in ipairs(destinationContainers) do
                if self:canStackItem(item, container, addedWeight[container], useNameMethod) then
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, source, container))
                    addedWeight[container] = addedWeight[container] + item:getUnequippedWeight()
                    break
                end
            end
        end
    end
end

function FuctionalPanel:canStackItem(item, container, addedWeight, useNameMethod)
    local player = getSpecificPlayer(self.inventoryPage.player)

    if not container:hasRoomFor(player, item:getUnequippedWeight() + addedWeight) then
        return false
    end

    if not container:isItemAllowed(item) then
        return false
    end

    local containerItems = container:getItems()
    for i = 0, containerItems:size() - 1 do
        local containerItem = containerItems:get(i)
        
        if useNameMethod then
            if item:getName() == containerItem:getName() then
                return true
            end
        else
            if item:getDisplayCategory() == containerItem:getDisplayCategory() then
                return true
            end
        end
    end
    
    return false
end

-- ---------------------------------------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------------------------------------- --

function FuctionalPanel:prerender()
    self.width = self.inventoryPage.width - self.inventoryPage.containerButtonAreaWid

    self:setStencilRect(0, 0, self.width, self.height)
end

function FuctionalPanel:render()
    self:drawRect(self.padding, self.height - 1, self.width - self.padding * 2, 1, 0.8, 0.4, 0.4, 0.4)

    self:clearStencilRect()
end

-- ---------------------------------------------------------------------------------------- --
-- Config
-- ---------------------------------------------------------------------------------------- --
function FuctionalPanel:getconfig(settingName, defaultValue)
    local config = CleanUIConfig.getConfig()
    if config[settingName] ~= nil then
        return config[settingName]
    end
    return defaultValue
end