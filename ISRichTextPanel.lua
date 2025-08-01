require "ISUI/ISPanel"

ISRichTextPanel = ISPanel:derive("ISRichTextPanel");
local IMAGE_PAD = 5

ISRichTextPanel.drawMargins = false

--************************************************************************--
--** ISRichTextPanel:initialise
--**
--************************************************************************--

function ISRichTextPanel:initialise()
	ISPanel.initialise(self);
end

function ISRichTextPanel:setText(text)
	self.text = text or ""
end

function ISRichTextPanel:processCommand(command, x, y, lineImageHeight, lineHeight)
    if command == "LINE" then
        x = 0;
        lineImageHeight = 0;
        y = y + lineHeight;

    end
    if command == "BR" then
        x = 0;
        lineImageHeight = 0;
        y = y + lineHeight + lineHeight;

    end
    if command == "H1" then
        self.orient[self.currentLine] = "centre";
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = 1;
        self.rgb[self.currentLine].g = 1;
        self.rgb[self.currentLine].b = 1;
        self.font = UIFont.Large;
        self.fonts[self.currentLine] = self.font;
    end
    if command == "H2" then
        self.orient[self.currentLine] = "left";
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = 0.8;
        self.rgb[self.currentLine].g = 0.8;
        self.rgb[self.currentLine].b = 0.8;
        self.font = UIFont.Medium;
        self.fonts[self.currentLine] = self.font;
    end
    if command == "TEXT" then
        self.orient[self.currentLine] = "left";
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = 0.7;
        self.rgb[self.currentLine].g = 0.7;
        self.rgb[self.currentLine].b = 0.7;
        self.rgbCurrent = self.rgb[self.currentLine]
        self.font = self.defaultFont;
        self.fonts[self.currentLine] = self.font;
    end
    if command == "CENTRE" then
        self.orient[self.currentLine] = "centre";
    end

    if command == "LEFT" then
        self.orient[self.currentLine] = "left";
    end

    if command == "RIGHT" then
        self.orient[self.currentLine] = "right";
    end
    if string.find(command, "PUSHRGB:") then
        table.insert(self.rgbStack, self.rgbCurrent)
        local rgb = string.split(string.sub(command, 9, string.len(command)), ",")
        self.rgb[self.currentLine] = {}
        self.rgb[self.currentLine].r = tonumber(rgb[1])
        self.rgb[self.currentLine].g = tonumber(rgb[2])
        self.rgb[self.currentLine].b = tonumber(rgb[3])
        self.rgbCurrent = self.rgb[self.currentLine]
    elseif string.find(command, "POPRGB") then
        if #self.rgbStack > 0 then
            self.rgbCurrent = table.remove(self.rgbStack, #self.rgbStack)
            self.rgb[self.currentLine] = self.rgbCurrent
        end
    elseif string.find(command, "RGB:") then
		local rgb = string.split(string.sub(command, 5, string.len(command)), ",");
		self.rgb[self.currentLine] = {};
		self.rgb[self.currentLine].r = tonumber(rgb[1]);
		self.rgb[self.currentLine].g = tonumber(rgb[2]);
		self.rgb[self.currentLine].b = tonumber(rgb[3]);
        self.rgbCurrent = self.rgb[self.currentLine]
    elseif string.find(command, "GHC") then
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = getCore():getGoodHighlitedColor():getR();
        self.rgb[self.currentLine].g = getCore():getGoodHighlitedColor():getG();
        self.rgb[self.currentLine].b = getCore():getGoodHighlitedColor():getB();
        self.rgbCurrent = self.rgb[self.currentLine]
    elseif string.find(command, "BHC") then
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = getCore():getBadHighlitedColor():getR();
        self.rgb[self.currentLine].g = getCore():getBadHighlitedColor():getG();
        self.rgb[self.currentLine].b = getCore():getBadHighlitedColor():getB();
        self.rgbCurrent = self.rgb[self.currentLine]
    end
    if string.find(command, "RED") then
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = 1;
        self.rgb[self.currentLine].g = 0;
        self.rgb[self.currentLine].b = 0;
        self.rgbCurrent = self.rgb[self.currentLine]
    end
    if string.find(command, "ORANGE") then
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = 0.9;
        self.rgb[self.currentLine].g = 0.3;
        self.rgb[self.currentLine].b = 0;
        self.rgbCurrent = self.rgb[self.currentLine]
    end
    if string.find(command, "GREEN") then
        self.rgb[self.currentLine] = {};
        self.rgb[self.currentLine].r = 0;
        self.rgb[self.currentLine].g = 1;
        self.rgb[self.currentLine].b = 0;
        self.rgbCurrent = self.rgb[self.currentLine]
    end
    if string.find(command, "SIZE:") then

		local size = string.sub(command, 6);
--~         print(size);
		if(size == "small") then
			self.font = UIFont.NewSmall;
		end
		if(size == "medium") then
			self.font = UIFont.Medium;
		end
		if(size == "large") then
			self.font = UIFont.Large;
		end
		self.fonts[self.currentLine] = self.font;
	end

    if string.find(command, "IMAGE:") ~= nil then
        local w = 0;
        local h = 0;
        if string.find(command, ",") ~= nil then
            local vs = string.split(command, ",");

            command = string.trim(vs[1]);
            w = tonumber(string.trim(vs[2]));
            h = tonumber(string.trim(vs[3]));

        end
        self.images[self.imageCount] = getTexture(string.sub(command, 7));
        if(w==0) then
            w = self.images[self.imageCount]:getWidth();
            h = self.images[self.imageCount]:getHeight();
        end
        if(x + w >= self.width - (self.marginLeft + self.marginRight)) then
            x = 0;
            y = y +  lineHeight;
        end

        if(lineImageHeight < h + 0) then
            lineImageHeight = h + 0;
        end

        if self.images[self.imageCount] == nil then
            --print("Could not find texture");
        end
        self.imageX[self.imageCount] = x+IMAGE_PAD;
        self.imageY[self.imageCount] = y+(lineHeight-lineImageHeight)/2;
        self.imageW[self.imageCount] = w;
        self.imageH[self.imageCount] = h;
        self.imageCount = self.imageCount + 1;
        x = x + w + IMAGE_PAD*2;
--[[
        local newY = math.max(y + (h / 2) - 7, y)

        for c,v in ipairs(self.lines) do
            if self.lineY[c] == y then
                self.lineY[c] = newY;
            end
		end
		for c,v in ipairs(self.imageY) do
			if self.imageY[c] == y then
				self.imageY[c] = newY;
			end
		end
        y = newY;
--]]
    end


    if string.find(command, "IMAGECENTRE:") ~= nil then
        local w = 0;
        local h = 0;
        if string.find(command, ",") ~= nil then
            local vs = string.split(command, ",");

            command = string.trim(vs[1]);
            w = tonumber(string.trim(vs[2]));
            h = tonumber(string.trim(vs[3]));

        end
        self.images[self.imageCount] = getTexture(string.sub(command, 13));
        if(w==0) then
            w = self.images[self.imageCount]:getWidth();
            h = self.images[self.imageCount]:getHeight();
        end
        if(x + w >= self.width - (self.marginLeft + self.marginRight)) then
            x = 0;
            y = y +  lineHeight;
        end

        if(lineImageHeight < (h / 2) + 8) then
            lineImageHeight = (h / 2) + 16;
        end

        if self.images[self.imageCount] == nil then
            --print("Could not find texture");
        end
        local mx = (self.width - self.marginLeft - self.marginRight) / 2;
        self.imageX[self.imageCount] = mx - (w/2);
        self.imageY[self.imageCount] = y;
        self.imageW[self.imageCount] = w;
        self.imageH[self.imageCount] = h;
        self.imageCount = self.imageCount + 1;
        x = x + w + 7;

        for c,v in ipairs(self.lines) do
            if self.lineY[c] == y then
                self.lineY[c] = self.lineY[c] + (h / 2);
            end
        end

        y = y + (h / 2);
    end

    if string.find(command, "VIDEOCENTRE:") ~= nil then
        local w = 0;
        local h = 0;
        local w2 = 384
        local h2 = 216
        local image = "";
        if string.find(command, ",") ~= nil then
            local vs = string.split(command, ",");

            command = string.trim(vs[1]);
            w = tonumber(string.trim(vs[2])); --video width
            h = tonumber(string.trim(vs[3])); --video height
            if vs[5] then --test to see if the display height has been defined
                w2 = tonumber(string.trim(vs[4])) --display width
                h2 = tonumber(string.trim(vs[5])) --display height
            end
            image = "media/videos/" .. string.trim(string.split(command, ":")[2]) .. ".png"
        end

        if Core.getInstance():getOptionDoVideoEffects() then
            -- Play the video
            self.videos[self.videoCount] = getVideo(string.sub(command, 13), w, h);

            w = w2
            h = h2
            if(x + w >= self.width - (self.marginLeft + self.marginRight)) then
                x = 0;
                y = y + lineHeight;
            end

            if(lineImageHeight < (h / 2) + 8) then
                lineImageHeight = (h / 2) + 16;
            end

            if self.videos[self.videoCount] == nil then
                print("Could not find video");
            end
            local mx = (self.width - self.marginLeft - self.marginRight) / 2;
            self.videoX[self.videoCount] = mx - (w/2);
            self.videoY[self.videoCount] = y;
            self.videoW[self.videoCount] = w;
            self.videoH[self.videoCount] = h;
            self.videoCount = self.videoCount + 1;
            x = x + w + 7;

            for c,v in ipairs(self.lines) do
                if self.lineY[c] == y then
                    self.lineY[c] = self.lineY[c] + (h / 2);
                end
            end

            y = y + (h / 2);
        else
            -- Video Effects off, show the backup image
            self.images[self.imageCount] = getTexture(image);

            if self.images[self.imageCount] ~= nil then
                w = self.images[self.imageCount]:getWidth();
                h = self.images[self.imageCount]:getHeight();

                if(x + w >= self.width - (self.marginLeft + self.marginRight)) then
                    x = 0;
                    y = y +  lineHeight;
                end

                if(lineImageHeight < (h / 2) + 8) then
                    lineImageHeight = (h / 2) + 16;
                end

                if self.images[self.imageCount] == nil then
                    --print("Could not find texture");
                end
                local mx = (self.width - self.marginLeft - self.marginRight) / 2;
                self.imageX[self.imageCount] = mx - (w/2);
                self.imageY[self.imageCount] = y;
                self.imageW[self.imageCount] = w;
                self.imageH[self.imageCount] = h;
                self.imageCount = self.imageCount + 1;
                x = x + w + 7;

                for c,v in ipairs(self.lines) do
                    if self.lineY[c] == y then
                        self.lineY[c] = self.lineY[c] + (h / 2);
                    end
                end

                y = y + (h / 2);
            end
        end
    end

    if string.find(command, "INDENT:") then
        self.indent = tonumber(string.sub(command, 8))
    end

    if string.find(command, "JOYPAD:") ~= nil then
        local w = 0
        local h = 0
        if string.find(command, ",") ~= nil then
            local vs = string.split(command, ",")
            command = string.trim(vs[1])
            w = tonumber(string.trim(vs[2]))
            h = tonumber(string.trim(vs[3]))
        end
        self.images[self.imageCount] = Joypad.Texture[string.sub(command, 8)]
        if w == 0 then
            w = self.images[self.imageCount]:getWidth()
            h = self.images[self.imageCount]:getHeight()
        end
        if(x + w >= self.width - (self.marginLeft + self.marginRight)) then
            x = 0
            y = y + lineHeight
        end
        if lineImageHeight < h + 0 then
            lineImageHeight = h + 0;
        end
        self.imageX[self.imageCount] = x+IMAGE_PAD
        self.imageY[self.imageCount] = y+(lineHeight-lineImageHeight)/2
        self.imageW[self.imageCount] = w
        self.imageH[self.imageCount] = h
        self.imageCount = self.imageCount + 1
        x = x + w + IMAGE_PAD*2
    end

    if string.find(command, "SETX:") then
        x = tonumber(string.sub(command, 6))
    end

    if string.find(command, "SPACE") then
        if x > 0 then
            x = x + getTextManager():MeasureStringX(self.font, " ") + 2
        end
    end

    return x, y, lineImageHeight

end

function ISRichTextPanel:replaceKeyName(text, offset)
	local p1,p2 = string.find(text, "<KEY:", offset)
	if not p1 then return text, nil end
	local p3,p4 = string.find(text, ">", p2 + 1)
	if not p3 then return text, nil end
	local binding = string.sub(text, p2 + 1, p3 - 1):gsub("&nbsp;", " ")
	local textBefore = string.sub(text, 1, p1 - 1)
	local textAfter = string.sub(text, p4 + 1)
	local newText = " <PUSHRGB:0,0.635,0.91> " .. getKeyName(getCore():getKey(binding)) .. " <POPRGB> "
	return textBefore .. newText .. textAfter, p1 + #newText
end

function ISRichTextPanel:replaceKeyNames(text)
	local offset = 1
	while true do
		text, offset = self:replaceKeyName(text, offset)
		if not offset then break end
	end
	return text
end

function ISRichTextPanel:onMouseWheel(del)
	self:setYScroll(self:getYScroll() - (del*18));
    return true;
end
--************************************************************************--
--** ISRichTextPanel:paginate
--**
--** Splits multiline text up into seperate lines, and positions images to be
--** rendered
--************************************************************************--
function ISRichTextPanel:paginate()
	local lines = 1;
	self.textDirty = false;
	self.imageCount = 1;
	self.font = self.defaultFont;
	self.fonts = {};
	self.images = {}
	self.imageX = {}
	self.imageY = {}
	self.rgb = {};
	self.rgbCurrent = { r = 1, g = 1, b = 1 }
	self.rgbStack = {}
	self.orient = {}
	self.indent = 0

	self.imageW = {}
	self.imageH = {}

	self.lineY = {}
	self.lineX = {}
	self.lines = {}

	self.keybinds = {}

    self.videoCount = 1;
	self.videos = {}
	self.videoX = {}
    self.videoY = {}
    self.videoW = {}
    self.videoH = {}

	local bDone = false;
	local leftText = self:replaceKeyNames(self.text) .. ' ';
	local cur = 0;
	local y = 0;
	local x = 0;
	local lineImageHeight = 0;
	leftText = leftText:gsub("\n", " <LINE> ")
	if self.maxLines > 0 then
		local lines = leftText:split("<LINE>")
		for i=1,(#lines - self.maxLines) do
			table.remove(lines,1)
		end
		leftText = ' '
		for k,v in ipairs(lines) do
			leftText = leftText..v.." <LINE> "
		end
	end
	local maxLineWidth = self.maxLineWidth or (self.width - self.marginRight - self.marginLeft)
	-- Always go through at least once.
	while not bDone do
		cur = string.find(leftText, " ", cur+1);
		if cur ~= nil then
--			while string.sub(leftText, cur, cur)== " " do
--				cur = cur + 1
--			end
--			cur = cur - 1
			local token = string.sub(leftText, 0, cur);
			if string.find(token, "<") and string.find(token, ">") then -- handle missing ' ' after '>'
				cur = string.find(token, ">") + 1;
				token = string.sub(leftText, 0, cur - 1);
			end
			leftText = string.sub(leftText, cur);
			cur = 1
			if string.find(token, "<") and string.find(token, ">") then
				if not self.lines[lines] then
					self.lines[lines] = ''
					self.lineX[lines] = x
					self.lineY[lines] = y
				end
				lines = lines + 1
				local st = string.find(token, "<");
				local en = string.find(token, ">");
				local escSeq = string.sub(token, st+1, en-1);
				local lineHeight = getTextManager():getFontFromEnum(self.font):getLineHeight();
				if lineHeight < 10 then
					lineHeight = 10;
				end
				if lineHeight < lineImageHeight then
					lineHeight = lineImageHeight;
				end
				self.currentLine = lines;
				x, y, lineImageHeight = self:processCommand(escSeq, x, y, lineImageHeight, lineHeight);
			else
				if token:contains("&lt;") then
					token = token:gsub("&lt;", "<")
				end
				if token:contains("&gt;") then
					token = token:gsub("&gt;", ">")
				end
				local chunkText = self.lines[lines] or ''
				local chunkX = self.lineX[lines] or x
				if chunkText == '' then
					chunkText = string.trim(token)
				elseif string.trim(token) ~= '' then
					chunkText = chunkText..' '..string.trim(token)
				end
				local pixLen = getTextManager():MeasureStringX(self.font, chunkText);
				if chunkX + pixLen > maxLineWidth then
					if self.lines[lines] and self.lines[lines] ~= '' then
						lines = lines + 1;
					end
					local lineHeight = getTextManager():getFontFromEnum(self.font):getLineHeight();
					if lineHeight < lineImageHeight then
						lineHeight = lineImageHeight;
					end
					lineImageHeight = 0;
					y = y + lineHeight;
					x = 0;
					self.lines[lines] = string.trim(token)
					if self.lines[lines] ~= "" then
						x = self.indent
					end
					self.lineX[lines] = x
					self.lineY[lines] = y
					x = x + getTextManager():MeasureStringX(self.font, self.lines[lines])
				else
					if not self.lines[lines] then
						self.lines[lines] = ''
						self.lineX[lines] = x
						self.lineY[lines] = y
					end
					self.lines[lines] = chunkText
					if self.lineX[lines] == 0 and self.lines[lines] ~= "" then
						self.lineX[lines] = self.indent
					end
					x = self.lineX[lines] + pixLen
				end
			end
		else
			if string.trim(leftText) ~= '' then
				local str = leftText
				if str:contains("&lt;") then
					str = str:gsub("&lt;", "<")
				end
				if str:contains("&gt;") then
					str = str:gsub("&gt;", ">")
				end
				self.lines[lines] = string.trim(str);
				if x == 0 and self.lines[lines] ~= "" then
					x = self.indent
				end
				self.lineX[lines] = x;
				self.lineY[lines] = y;
				local lineHeight = getTextManager():getFontFromEnum(self.font):getLineHeight();
				y = y + lineHeight
			elseif self.lines[lines] and self.lines[lines] ~= '' then
				local lineHeight = getTextManager():getFontFromEnum(self.font):getLineHeight();
				if lineHeight < lineImageHeight then
					lineHeight = lineImageHeight;
				end
				y = y + lineHeight
			end
			bDone = true;
		end
	end

	if self.autosetheight then
		self:setHeight(self.marginTop + y + self.marginBottom);
	end

	self:setScrollHeight(self.marginTop + y + self.marginBottom);
end

function ISRichTextPanel:setContentTransparency(alpha)
    self.contentTransparency = alpha;
end

--************************************************************************--
--** ISRichTextPanel:render
--**
--************************************************************************--
function ISRichTextPanel:render()

    self.r = 1;
    self.g = 1;
    self.b = 1;

	if self.lines == nil then
		return;
	end

	if self.keybinds then
		for binding,text in pairs(self.keybinds) do
			if getKeyName(getCore():getKey(binding)) ~= text then
				self.textDirty = true
				break
			end
		end
	end

	if self.clip then self:setStencilRect(0, 0, self.width, self.height) end
	if self.textDirty then
		self:paginate();
	end
	--ISPanel.render(self);
    for c,v in ipairs(self.images) do
        self:drawTextureScaled(v, self.imageX[c] + self.marginLeft, self.imageY[c] + self.marginTop, self.imageW[c], self.imageH[c], self.contentTransparency, 1, 1, 1);
    end

    for c,v in ipairs(self.videos) do
        v:RenderFrame()
        self:drawTextureScaled(v, self.videoX[c] + self.marginLeft, self.videoY[c] + self.marginTop, self.videoW[c], self.videoH[c], self.contentTransparency, 1, 1, 1);
    end

    self.font = self.defaultFont
    local orient = "left";
	local c = 1
	while c <= #self.lines do
		local v = self.lines[c]
		
		if self.lineY[c] + self.marginTop + self:getYScroll() >= self:getHeight() then
			break
		end

		if self.rgb[c] then
			self.r = self.rgb[c].r;
			self.g = self.rgb[c].g;
			self.b = self.rgb[c].b;
		end

		if self.orient[c] then
			orient = self.orient[c];
		end

		if self.fonts[c] then
			self.font = self.fonts[c];
		end

		if self.marginTop + self:getYScroll() + self.lineY[c] + getTextManager():getFontHeight(self.font) > 0 then
		
			local r = self.r;
			local b = self.b;
			local g = self.g;

			if v:contains("&lt;") then
				v = v:gsub("&lt;", "<")
			end
			if v:contains("&gt;") then
				v = v:gsub("&gt;", ">")
			end

			if string.trim(v) ~= "" then
				if orient == "centre" then
					local lineY = self.lineY[c]
					local lineLength = 0
					local c2 = c
					while (c2 <= #self.lines) and (self.lineY[c2] == lineY) do
						local font = self.fonts[c2] or self.font
						lineLength = lineLength + getTextManager():MeasureStringX(font, string.trim(self.lines[c2]))
						c2 = c2 + 1
					end
					local lineX = self.marginLeft + (self.width - self.marginLeft - self.marginRight - lineLength) / 2
					while (c <= #self.lines) and (self.lineY[c] == lineY) do
						if self.rgb[c] then
							self.r = self.rgb[c].r;
							self.g = self.rgb[c].g;
							self.b = self.rgb[c].b;
						end
						local r = self.r;
						local b = self.b;
						local g = self.g;
						if self.orient[c] then
							orient = self.orient[c];
						end
						if self.fonts[c] then
							self.font = self.fonts[c];
						end
						self:drawText(string.trim(self.lines[c]), lineX + self.lineX[c], self.lineY[c] + self.marginTop, r, g, b, self.contentTransparency, self.font)
--						lineX = lineX + getTextManager():MeasureStringX(self.font, self.lines[c])
						c = c + 1
					end
					c = c - 1
				elseif orient == "right" then
					self:drawTextRight( string.trim(v), self.lineX[c] + self.marginLeft, self.lineY[c] + self.marginTop, r, g, b,self.contentTransparency, self.font);
				else
					self:drawText( string.trim(v), self.lineX[c] + self.marginLeft, self.lineY[c] + self.marginTop, r, g, b,self.contentTransparency, self.font);
				end

--				self:drawRect(self.lineX[c] + self.marginLeft, self.lineY[c] + self.marginTop, self.width, 1, 1.0, 0.5, 0.5, 0.5)
			end
		end
		c = c + 1
	end

	if ISRichTextPanel.drawMargins then
		self:drawRectBorder(0, 0, self.width, self:getScrollHeight(), 0.5,1,1,1)
		self:drawRect(self.marginLeft, 0, 1, self:getScrollHeight(), 1,1,1,1)
		local maxLineWidth = self.maxLineWidth or (self.width - self.marginRight - self.marginLeft)
--		self:drawRect(self.marginLeft + maxLineWidth, 0, 1, self:getScrollHeight(), 1,1,1,1)
		self:drawRect(self.width - self.marginRight, 0, 1, self:getScrollHeight(), 1,1,1,1)
		self:drawRect(0, self.marginTop, self.width, 1, 1,1,1,1)
		self:drawRect(0, self:getScrollHeight() - self.marginBottom, self.width, 1, 1,1,1,1)
	end

	if self.clip then self:clearStencilRect() end
	--self:setScrollHeight(y);
end

function ISRichTextPanel:onResize()
  --  ISUIElement.onResize(self);
	self.width = self:getWidth();
	self.height = self:getHeight();
    self.textDirty = true;
    self:updateScrollbars()
end

function ISRichTextPanel:setMargins(left, top, right, bottom)
	self.marginLeft = left
	self.marginTop = top
	self.marginRight = right
	self.marginBottom = bottom
end

function ISRichTextPanel:doRightJoystickScrolling(joypadData, dx, dy)
	dx = dx or 20
	dy = dy or 20
	local axisY = getJoypadAimingAxisY(joypadData.id)
	if axisY > 0.75 then
		self:setYScroll(self:getYScroll() - dy * UIManager.getMillisSinceLastRender() / 33.3)
	end
	if axisY < -0.75 then
		self:setYScroll(self:getYScroll() + dy * UIManager.getMillisSinceLastRender() / 33.3)
	end
	local axisX = getJoypadAimingAxisX(joypadData.id)
	if axisX > 0.75 then
		self:setXScroll(self:getXScroll() - dx * UIManager.getMillisSinceLastRender() / 33.3)
	end
	if axisX < -0.75 then
		self:setXScroll(self:getXScroll() + dx * UIManager.getMillisSinceLastRender() / 33.3)
	end
end

--************************************************************************--
--** ISRichTextPanel:new
--**
--************************************************************************--
function ISRichTextPanel:new (x, y, width, height)
	local o = {}
	--o.data = {}
	o = ISPanel:new(x, y, width, height);
	setmetatable(o, self);
    self.__index = self;
	o.x = x;
	o.y = y;
    o.contentTransparency = 1.0;
    o.backgroundColor = {r=0, g=0, b=0, a=0.5};
    o.borderColor = {r=0, g=0, b=0, a=0.0};
    o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
	o.marginLeft = 20;
	o.marginTop = 10;
	o.marginRight = 10;
	o.marginBottom = 10;
	o.autosetheight = true;
	o.text = ""
	o.textDirty = false;
	o.textR = 1;
	o.textG = 1;
	o.textB = 1;
	o.clip = false
	o.maxLines = 0
	o.defaultFont = UIFont.NewSmall
	return o;
end

