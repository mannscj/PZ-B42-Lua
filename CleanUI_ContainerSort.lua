CleanUI_ContainerSort = {}

local SORT_KEY = "CleanUI_SortContainer"

function CleanUI_ContainerSort.getTargetModDataAndSortKey(player, inventory)
    local playerKey = player:getUsername()
    local sortKey = SORT_KEY
    local targetModData = nil

    if inventory == player:getInventory() then
        sortKey = SORT_KEY
        targetModData = player:getModData()
    elseif inventory:getType() == "floor" then
        sortKey = SORT_KEY .. "_Floor"
        targetModData = player:getModData()
    else
        local item = inventory:getContainingItem()
        local isoObject = inventory:getParent()
        
        if item then
            sortKey = playerKey .. SORT_KEY
            targetModData = item:getModData()
        elseif isoObject then
            sortKey = playerKey .. SORT_KEY
            targetModData = isoObject:getModData()
        end
    end

    return targetModData, sortKey
end

function CleanUI_ContainerSort.getSortPriority(player, inventory)
    local targetModData, sortKey = CleanUI_ContainerSort.getTargetModDataAndSortKey(player, inventory)
    if targetModData then
        return targetModData[sortKey] or 999
    end
    return 999
end

function CleanUI_ContainerSort.setSortPriority(player, inventory, priority)
    local targetModData, sortKey = CleanUI_ContainerSort.getTargetModDataAndSortKey(player, inventory)
    if targetModData then
        targetModData[sortKey] = priority
    end
end

-- ---------------------------------------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------------------------------------- --

function CleanUI_ContainerSort.onMouseDown(self, x, y)
    if self.original_onMouseDown then
        self.original_onMouseDown(self, x, y)
    end

    self.dragStartMouseY = getMouseY()
    self.dragStartY = self:getY()
    self.canDragToReorder = true
end

function CleanUI_ContainerSort.onMouseMove(self, dx, dy)
    if self.original_onMouseMove then
        self.original_onMouseMove(self, dx, dy)
    end

    if self.pressed and self.canDragToReorder then
        local parent = self:getParent()

        if math.abs(self.dragStartMouseY - getMouseY()) > parent.buttonSize / 2 then
            self.draggingToReorder = true
        end

        if self.draggingToReorder then
            local mouseY = getMouseY()
            local parentY = parent:getAbsoluteY()
            local newY = mouseY - parentY - self:getHeight() / 2

            newY = math.max(parent:titleBarHeight(), newY)
            
            self:setY(newY)
            self:bringToTop()
        end
    end
end

function CleanUI_ContainerSort.onMouseMoveOutside(self, dx, dy)
    if self.original_onMouseMoveOutside then
        self.original_onMouseMoveOutside(self, dx, dy)
    end

    CleanUI_ContainerSort.onMouseMove(self, dx, dy)

    if self.draggingToReorder and not isMouseButtonDown(0) then
        CleanUI_ContainerSort.onMouseUp(self, 0, 0)
    end
end

function CleanUI_ContainerSort.onMouseUp(self, x, y)
    local page = self:getParent()
    
    if self.draggingToReorder then
        self.pressed = false
        self.draggingToReorder = false

        if math.abs(self:getY() - self.dragStartY) <= 30 then
            self:setY(self.dragStartY)
        else
            local draggedInventory = self.inventory
            page:reorderContainerButtons(self)
            page:refreshBackpacks()
            page:selectButtonForContainer(draggedInventory)
        end
    else
        if self.original_onMouseUp then
            self.original_onMouseUp(self, x, y)
        end
    end
end

-- ---------------------------------------------------------------------------------------- --
-- extendInventoryPage
-- ---------------------------------------------------------------------------------------- --

function CleanUI_ContainerSort.extendInventoryPage()
    --[[
    if JoypadState and JoypadState.players then
        for i=1, #JoypadState.players do
            if JoypadState.players[i] and JoypadState.players[i].player ~= nil then
                return
            end
        end
    end
    ]]

    ISInventoryPage.original_addContainerButton = ISInventoryPage.addContainerButton
    ISInventoryPage.original_refreshBackpacks = ISInventoryPage.refreshBackpacks
    ISInventoryPage.original_onMouseWheel = ISInventoryPage.onMouseWheel

    ISInventoryPage.addContainerButton = function(self, container, texture, name, tooltip)
        local button = self:original_addContainerButton(container, texture, name, tooltip)

        if self.onCharacter then
            if not button.original_onMouseDown then
                button.original_onMouseDown = button.onMouseDown
                button.original_onMouseMove = button.onMouseMove
                button.original_onMouseMoveOutside = button.onMouseMoveOutside
                button.original_onMouseUp = button.onMouseUp
            end

            button.onMouseDown = CleanUI_ContainerSort.onMouseDown
            button.onMouseMove = CleanUI_ContainerSort.onMouseMove
            button.onMouseMoveOutside = CleanUI_ContainerSort.onMouseMoveOutside
            button.onMouseUp = CleanUI_ContainerSort.onMouseUp
        end

        return button
    end

    local function isButtonValid(invPage, button)
        return button:getIsVisible() and invPage.children[button.ID]
    end

    function ISInventoryPage.reorderContainerButtons(self, draggedButton)
        if not self.onCharacter then return end

        if draggedButton and math.abs(draggedButton:getY() - draggedButton.dragStartY) <= 32 then
            draggedButton:setY(draggedButton.dragStartY)
            return
        end
        
        local player = getSpecificPlayer(self.player)
        local inventoriesAndY = {}

        for _, button in ipairs(self.backpacks) do
            if isButtonValid(self, button) then
                table.insert(inventoriesAndY, {
                    inventory = button.inventory,
                    y = button:getY()
                })
            end
        end

        table.sort(inventoriesAndY, function(a, b) return a.y < b.y end)

        local lastSort = 0
        for _, data in ipairs(inventoriesAndY) do
            lastSort = lastSort + 10
            CleanUI_ContainerSort.setSortPriority(player, data.inventory, lastSort)
        end
    end

    function ISInventoryPage.applySortOrder(self)
        if not self.onCharacter then return end
        
        local player = getSpecificPlayer(self.player)
        local buttonsWithOrder = {}

        for index, button in ipairs(self.backpacks) do
            if isButtonValid(self, button) then
                local order = CleanUI_ContainerSort.getSortPriority(player, button.inventory)
                if order == 999 then
                    order = 1000 + index
                end
                table.insert(buttonsWithOrder, {button = button,order = order})
            end
        end

        table.sort(buttonsWithOrder, function(a, b) return a.order < b.order end)
        for index, data in ipairs(buttonsWithOrder) do
            local y = self:titleBarHeight() + self.padding + ((index - 1) * (self.buttonSize + self.padding))
            data.button:setY(y)
        end
    end

    function ISInventoryPage.refreshBackpacks(self)
        self:original_refreshBackpacks()

        if self.onCharacter then
            self:applySortOrder()
        end
    end

    ISInventoryPage.onMouseWheel = function(self, del)
        local inContainerArea = false
        if self:isPageLeft() then
            inContainerArea = self:getMouseX() < self.containerButtonAreaWid
        else
            inContainerArea = self:getMouseX() >= (self:getWidth() - self.containerButtonAreaWid)
        end

        if not inContainerArea and not self:isCycleContainerKeyDown() then
            return false
        end
        local originalOrder = {}
        for index, button in ipairs(self.backpacks) do
            originalOrder[button] = index
        end

        table.sort(self.backpacks, function(a, b) return a:getY() < b:getY() end)
        local retVal = self:original_onMouseWheel(del)
        table.sort(self.backpacks, function(a, b) return originalOrder[a] < originalOrder[b] end)

        return retVal
    end
end

local function initCleanUI_ContainerSort()
    CleanUI_ContainerSort.extendInventoryPage()
end

Events.OnGameStart.Add(initCleanUI_ContainerSort)