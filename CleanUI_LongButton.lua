require "ISUI/ISButton"
require "ISUI/CleanUI_Helper"

CleanUI_LongButton = ISButton:derive("CleanUI_LongButton")

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --

function CleanUI_LongButton:initialise()
    ISButton.initialise(self)
end

function CleanUI_LongButton:new(x, y, width, height, title, target, onclick)
    local o = ISButton:new(x, y, width, height, title, target, onclick)
    setmetatable(o, self)
    self.__index = self
    o:setDisplayBackground(false)

    o.buttonBg = {
        L = getTexture("media/ui/CleanUI/Button/LongBackground_L.png"),
        M = getTexture("media/ui/CleanUI/Button/LongBackground_M.png"),
        R = getTexture("media/ui/CleanUI/Button/LongBackground_R.png")
    }

    o.buttonBorder = {
        L = getTexture("media/ui/CleanUI/Button/LongBorder_L.png"),
        M = getTexture("media/ui/CleanUI/Button/LongBorder_M.png"),
        R = getTexture("media/ui/CleanUI/Button/LongBorder_R.png")
    }

    o.isActive = false
    o.activeColor = {r=0.95, g=0.5, b=0.1}
    o.textColor = {r=1.0, g=1.0, b=1.0, a=1.0}
    o.font = UIFont.Small
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Setting
-- ----------------------------------------------------------------------------------------------------- --

function CleanUI_LongButton:setActive(active)
    self.isActive = active
end

function CleanUI_LongButton:setActiveColor(r, g, b)
    self.activeColor = {r=r, g=g, b=b}
end

function CleanUI_LongButton:setTextColor(r, g, b, a)
    self.textColor = {r=r, g=g, b=b, a=a or 1.0}
end

function CleanUI_LongButton:setFont(font)
    self.font = font
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function CleanUI_LongButton:render()
    -- Background
    if self.isActive then
        -- Active
        if self.pressed then
            -- Press
            CleanUI.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height, self.buttonBg.L, self.buttonBg.M, self.buttonBg.R, 0.8, self.activeColor.r * 0.8, self.activeColor.g * 0.8, self.activeColor.b * 0.8)
        elseif self:isMouseOver() then
            -- Mouse Over
            CleanUI.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height, self.buttonBg.L, self.buttonBg.M, self.buttonBg.R, 0.8, math.min(self.activeColor.r * 1.2, 1), math.min(self.activeColor.g * 1.2, 1), math.min(self.activeColor.b * 1.2, 1))
        else
            -- Default
            CleanUI.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height, self.buttonBg.L, self.buttonBg.M, self.buttonBg.R, 0.8, self.activeColor.r, self.activeColor.g, self.activeColor.b)
        end
    else
        -- Un-Active
        if self.pressed then
            -- Press
            CleanUI.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height, self.buttonBg.L, self.buttonBg.M, self.buttonBg.R, 0.8, 0.05, 0.05, 0.05)
        elseif self:isMouseOver() then
            -- Mouse Over
            CleanUI.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height, self.buttonBg.L, self.buttonBg.M, self.buttonBg.R, 0.8, 0.2, 0.2, 0.2)
        else
            -- Default
            CleanUI.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height, self.buttonBg.L, self.buttonBg.M, self.buttonBg.R, 0.8, 0.1, 0.1, 0.1)
        end
    end

    -- Border
    CleanUI.ThreePatch.drawHorizontal(self, 0, 0, self.width, self.height, self.buttonBorder.L, self.buttonBorder.M, self.buttonBorder.R, 1, 0.4, 0.4, 0.4)

    -- Text
    if self.title and self.title ~= "" then
        local textW = getTextManager():MeasureStringX(self.font, self.title)
        local textH = getTextManager():MeasureStringY(self.font, self.title)
        local x = self.width / 2 - textW / 2
        local y = self.height / 2 - textH / 2

        if self.enable then
            self:drawText(self.title, x, y, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, self.font)
        else
            -- Disabled state - gray text
            self:drawText(self.title, x, y, 0.3, 0.3, 0.3, 1, self.font)
        end
    end
end

return CleanUI_LongButton