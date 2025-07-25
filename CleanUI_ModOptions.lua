local MOD_ID = "CleanUI"
local NAME_COLOR_ID = "itemNameColor"
local CATEGORY_COLOR_ID = "itemCategoryColor"

local defaultNameColor = {r=0.8, g=0.8, b=0.8, a=1.0}
local defaultCategoryColor = {r=0.8, g=0.7, b=0.3, a=1.0}

local function InitCleanUIModOptions()
    local options = PZAPI.ModOptions:create(MOD_ID, getText("UI_CleanUI_ModName"))

-- ------------------------------------------------- --
-- Add options
-- ------------------------------------------------- --
    local transferMethodOption = options:addComboBox("transferMethod", getText("UI_CleanUI_TransferMethod"))
    transferMethodOption:addItem(getText("UI_CleanUI_TransferByCategory"), true)
    transferMethodOption:addItem(getText("UI_CleanUI_TransferByName"), false)
    
    local playerContainerPositionOption = options:addComboBox("playerContainerPosition",getText("UI_CleanUI_PlayerContainerPosition"))
    playerContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionLeft"), false)
    playerContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionRight"), true)

    local lootContainerPositionOption = options:addComboBox("lootContainerPosition",getText("UI_CleanUI_LootContainerPosition"))
    lootContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionLeft"), true)
    lootContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionRight"), false)
    
    local buttonScaleOption = options:addComboBox("containerButtonScale",getText("UI_CleanUI_ContainerButtonScale"))
    buttonScaleOption:addItem("1x(default)", true)
    buttonScaleOption:addItem("1.2x", false)
    buttonScaleOption:addItem("1.5x", false)
    buttonScaleOption:addItem("1.8x", false)
    buttonScaleOption:addItem("2x", false)

    local opacityOption = options:addSlider("backgroundOpacity", getText("UI_CleanUI_BackgroundOpacity").."(%)", 0.1, 1.0, 0.05, 0.65, nil)

    local containerOpacityOption = options:addSlider("containerBackgroundOpacity", getText("UI_CleanUI_ContainerBackgroundOpacity").."(%)", 0.1, 1.0, 0.05, 0.9, nil)

    options:addColorPicker(NAME_COLOR_ID,getText("UI_CleanUI_ItemNameColor"),defaultNameColor.r, defaultNameColor.g, defaultNameColor.b, defaultNameColor.a)
    options:addColorPicker(CATEGORY_COLOR_ID,getText("UI_CleanUI_ItemCategoryColor"),defaultCategoryColor.r, defaultCategoryColor.g, defaultCategoryColor.b, defaultCategoryColor.a)
end

Events.OnGameBoot.Add(InitCleanUIModOptions)

-- ------------------------------------------------- --
-- Get Modoption
-- ------------------------------------------------- --

function CleanUI_getTransferMethod()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local transferOption = options:getOption("transferMethod")
        if transferOption then
            local value = transferOption:getValue()
            return tostring(value) -- 1 = category, 2 = name
        end
    end
    return "1"
end

function CleanUI_getContainerPosition(inventoryPage)
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if not options then
        return inventoryPage and (inventoryPage.onCharacter and "2" or "1") or "2"
    end
    
    if not inventoryPage then
        local playerOption = options:getOption("playerContainerPosition")
        if playerOption then
            local value = playerOption:getValue()
            return tostring(value)
        end
        return "2"
    end
    
    if inventoryPage.onCharacter then
        local playerOption = options:getOption("playerContainerPosition")
        if playerOption then
            local value = playerOption:getValue()
            return tostring(value) -- 1 = left, 2 = right
        end
        return "2"
    else
        local lootOption = options:getOption("lootContainerPosition")
        if lootOption then
            local value = lootOption:getValue()
            return tostring(value) -- 1 = left, 2 = right
        end
        return "1"
    end
end

function CleanUI_getItemNameColor()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local colorOption = options:getOption(NAME_COLOR_ID)
        if colorOption and colorOption.color then
            return colorOption.color
        end
    end
    return defaultNameColor
end

function CleanUI_getItemCategoryColor()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local colorOption = options:getOption(CATEGORY_COLOR_ID)
        if colorOption and colorOption.color then
            return colorOption.color
        end
    end
    return defaultCategoryColor
end

function CleanUI_getContainerButtonScaleMultiplier()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local scaleOption = options:getOption("containerButtonScale")
        if scaleOption then
            local value = scaleOption:getValue()
            if value == 1 then return 1.0 end
            if value == 2 then return 1.2 end
            if value == 3 then return 1.5 end
            if value == 4 then return 1.8 end
            if value == 5 then return 2.0 end
        end
    end
    return 1.0
end

function CleanUI_getBackgroundOpacity()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local opacityOption = options:getOption("backgroundOpacity")
        if opacityOption then
            return opacityOption:getValue()
        end
    end
    return 0.65
end

function CleanUI_getContainerBackgroundOpacity()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local opacityOption = options:getOption("containerBackgroundOpacity")
        if opacityOption then
            return opacityOption:getValue()
        end
    end
    return 0.9
end