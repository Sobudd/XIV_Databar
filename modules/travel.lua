local AddOnName, XIVBar = ...;
local _G = _G;
local xb = XIVBar;
local L = XIVBar.L;

-- Compatibility: some WoW environments move spell APIs under C_Spell.
local GetSpellCooldown = _G.GetSpellCooldown or (C_Spell and C_Spell.GetSpellCooldown)
if not GetSpellCooldown then
  GetSpellCooldown = function() return 0, 0, 0 end
end

local TravelModule = xb:NewModule("TravelModule", 'AceEvent-3.0')

function TravelModule:GetName()
  return L['Travel'];
end

function TravelModule:OnInitialize()
  self.iconPath = xb.constants.mediaPath..'datatexts\\repair'
  self.garrisonHearth = 110560
  self.arcantinaId = 253629
  self.hearthstones = {
    6948,   -- Hearthstone
    64488,  -- Innkeeper's Daughter
    193588, -- Timewalker's Hearthstone
    190237, -- Broker Translocation Matrix
    188952, -- Dominated Hearthstone
    28585,  -- Ruby Slippers
    54452,  -- Ethereal Portal
    93672,  -- Dark Portal
    142542, -- Tome of Town Portal
    163045, -- Headless Horseman's Hearthstone
    162973, -- Greatfather Winter's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    40582,  -- Scourgestone (Death Knight Starting Campaign)
    172179, -- Eternal Traveler's Hearthstone
    184353, -- Kyrian Hearthstone
    182773, -- Necrolord Hearthstone
    180290, -- Night Fae Hearthstone
    183716, -- Venthyr Sinstone
    142543, -- Scroll of Town Portal
    37118,  -- Scroll of Recall 1
    44314,  -- Scroll of Recall 2
    44315,  -- Scroll of Recall 3
    556,    -- Astral Recall
    168907, -- Holographic Digitalization Hearthstone
    142298, -- Astonishingly Scarlet Slippers
  }

  self.portButtons = {}
  self.extraPadding = (xb.constants.popupPadding * 3)
  self.optionTextExtra = 4
end

-- Skin Support for ElvUI/TukUI
-- Make sure to disable "Tooltip" in the Skins section of ElvUI together with
-- unchecking "Use ElvUI for tooltips" in XIV options to not have ElvUI fuck with tooltips
function TravelModule:SkinFrame(frame, name)
	if self.useElvUI then
		if frame.StripTextures then
			frame:StripTextures()
		end
		if frame.SetTemplate then
			frame:SetTemplate("Transparent")
		end

		local close = _G[name.."CloseButton"] or frame.CloseButton
		if close and close.SetAlpha then
			if ElvUI then
				ElvUI[1]:GetModule('Skins'):HandleCloseButton(close)
			end

			if Tukui and Tukui[1] and Tukui[1].SkinCloseButton then
				Tukui[1].SkinCloseButton(close)
			end
			close:SetAlpha(1)
		end
	end
end

function TravelModule:OnEnable()
  if self.hearthFrame == nil then
    self.hearthFrame = CreateFrame('FRAME', "TravelModule", xb:GetFrame('bar'))
    xb:RegisterFrame('travelFrame', self.hearthFrame)
  end
  self.useElvUI = xb.db.profile.general.useElvUI and (C_AddOns.IsAddOnLoaded('ElvUI') or C_AddOns.IsAddOnLoaded('Tukui'))
  self.hearthFrame:Show()
  self:CreateFrames()
  self:RegisterFrameEvents()
  self:Refresh()
end

function TravelModule:OnDisable()
  self.hearthFrame:Hide()
  self:UnregisterEvent('SPELLS_CHANGED')
  self:UnregisterEvent('BAG_UPDATE_DELAYED')
  self:UnregisterEvent('HEARTHSTONE_BOUND')
end

function TravelModule:CreateFrames()
  self.hearthButton = self.hearthButton or CreateFrame('BUTTON', 'hearthButton', self.hearthFrame, 'SecureActionButtonTemplate')
  self.hearthIcon = self.hearthIcon or self.hearthButton:CreateTexture(nil, 'OVERLAY')
  self.hearthText = self.hearthText or self.hearthButton:CreateFontString(nil, 'OVERLAY')

  self.portButton = self.portButton or CreateFrame('BUTTON', 'portButton', self.hearthFrame, 'SecureActionButtonTemplate')
  self.portIcon = self.portIcon or self.portButton:CreateTexture(nil, 'OVERLAY')
  self.portText = self.portText or self.portButton:CreateFontString(nil, 'OVERLAY')

  -- portPopup removed: we no longer use a separate popup frame for port options
end

function TravelModule:RegisterFrameEvents()
  self:RegisterEvent('SPELLS_CHANGED', 'Refresh')
  self:RegisterEvent('BAG_UPDATE_DELAYED', 'Refresh')
  self:RegisterEvent('HEARTHSTONE_BOUND', 'Refresh')

  self.hearthButton:EnableMouse(true)
  self.hearthButton:RegisterForClicks('AnyUp', 'AnyDown')
  self.hearthButton:SetAttribute('type', 'macro')

  -- ports: make left-click execute macro (Arcantina)
  self.portButton:EnableMouse(true)
  self.portButton:RegisterForClicks('AnyUp', 'AnyDown')
  self.portButton:SetAttribute('*type1', 'macro')

  self.hearthButton:SetScript('OnLeave', function()
    TravelModule:SetHearthColor()
  end)

  self.portButton:SetScript('OnEnter', function()
    TravelModule:SetPortColor()
    if InCombatLockdown() then return end
    self:ShowTooltip()
  end)

  self.portButton:SetScript('OnLeave', function()
    TravelModule:SetPortColor()
    GameTooltip:Hide()
  end)
end

function TravelModule:UpdatePortOptions()
  -- Restrict port options to only the Arcantina toy teleport (if available)
  local ARC = self.arcantinaId or 253629
  self.portOptions = {}
  if (PlayerHasToy and PlayerHasToy(ARC)) or IsUsableItem(ARC) then
    self.portOptions[ARC] = {portId = ARC, text = GetItemInfo(ARC) or "Personal Key to the Arcantina"}
  end
end

function TravelModule:FormatCooldown(cdTime)
  if cdTime <= 0 then
    return L['Ready']
  end
  local hours = string.format("%02.f", math.floor(cdTime / 3600))
  local minutes = string.format("%02.f", math.floor(cdTime / 60 - (hours * 60)))
  local seconds = string.format("%02.f", math.floor(cdTime - (hours * 3600) - (minutes * 60)))
  local retString = ''
  if tonumber(hours) ~= 0 then
    retString = hours..':'
  end
  if tonumber(minutes) ~= 0 or tonumber(hours) ~= 0 then
    retString = retString..minutes..':'
  end
  return retString..seconds
end

function TravelModule:SetHearthColor()
  if InCombatLockdown() then return; end

  local db = xb.db.profile
  if self.hearthButton:IsMouseOver() then
    self.hearthText:SetTextColor(unpack(xb:HoverColors()))
  else
    self.hearthIcon:SetVertexColor(xb:GetColor('normal'))
    local hearthName = ''
    local hearthActive = true
    for i,v in ipairs(self.hearthstones) do
      if (PlayerHasToy(v) or IsUsableItem(v)) then
        if GetItemCooldown(v) == 0 then
          hearthName, _ = GetItemInfo(v)
          if hearthName ~= nil then
            hearthActive = true
            self.hearthButton:SetAttribute("macrotext", "/cast "..hearthName)
            break
          end
        end
      end -- if toy/item
      if IsPlayerSpell(v) then
        if GetSpellCooldown(v) == 0 then
          hearthName, _ = GetSpellInfo(v)
          hearthActive = true
          self.hearthButton:SetAttribute("macrotext", "/cast "..hearthName)
        end
      end -- if is spell
    end -- for hearthstones
    if not hearthActive then
      self.hearthIcon:SetVertexColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
      self.hearthText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
    else
      self.hearthText:SetTextColor(xb:GetColor('normal'))
    end
  end --else
end

function TravelModule:SetPortColor()
  if InCombatLockdown() then return; end

  local db = xb.db.profile
  local v = self.arcantinaId or 253629

  -- if the arcantina toy/item isn't usable, hide/disable the port button
  if not ((PlayerHasToy and PlayerHasToy(v)) or IsUsableItem(v) or IsPlayerSpell(v)) then
    self.portIcon:SetVertexColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
    self.portText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
    return
  end

  if self.portButton:IsMouseOver() then
    self.portText:SetTextColor(unpack(xb:HoverColors()))
  else
    local hearthName
    local hearthActive = false
    if (PlayerHasToy and PlayerHasToy(v)) or IsUsableItem(v) then
      if GetItemCooldown(v) == 0 then
        hearthActive = true
        -- Hardcode the Arcantina macro to the exact string requested
        if v == (self.arcantinaId or 253629) then
          self.portButton:SetAttribute("macrotext", "/use personal key to the arcantina")
        else
          -- fallback to item use by id for any other item
          self.portButton:SetAttribute("macrotext", "/use "..v)
        end
      end
    end
    if IsPlayerSpell(v) and not hearthActive then
      if GetSpellCooldown(v) == 0 then
        hearthName = GetSpellInfo(v)
        if hearthName then
          hearthActive = true
          self.portButton:SetAttribute("macrotext", "/cast "..hearthName)
        end
      end
    end

    if not hearthActive then
      self.portIcon:SetVertexColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
      self.portText:SetTextColor(db.color.inactive.r, db.color.inactive.g, db.color.inactive.b, db.color.inactive.a)
    else
      self.portIcon:SetVertexColor(xb:GetColor('normal'))
      self.portText:SetTextColor(xb:GetColor('normal'))
    end
  end
end

-- CreatePortPopup removed: popup UI is no longer used.

function TravelModule:Refresh()
  if self.hearthFrame == nil then return; end
  if not self.hearthText then
    self:CreateFrames()
  end

  if not xb.db.profile.modules.travel.enabled then self:Disable(); return; end
  if InCombatLockdown() then
    self.hearthText:SetText(GetBindLocation())
    self.portText:SetText(xb.db.char.portItem.text)
    self:SetHearthColor()
    self:SetPortColor()
    return
  end

  self:UpdatePortOptions()

  local db = xb.db.profile
  --local iconSize = (xb:GetHeight() / 2)
  local iconSize = db.text.fontSize + db.general.barPadding

  self.hearthText:SetFont(xb:GetFont(db.text.fontSize))
  self.hearthText:SetText(GetBindLocation())

  self.hearthButton:SetSize(self.hearthText:GetWidth() + iconSize + db.general.barPadding, xb:GetHeight())
  self.hearthButton:SetPoint("RIGHT")

  self.hearthText:SetPoint("RIGHT")

  self.hearthIcon:SetTexture(xb.constants.mediaPath..'datatexts\\hearth')
  self.hearthIcon:SetSize(iconSize, iconSize)

  self.hearthIcon:SetPoint("RIGHT", self.hearthText, "LEFT", -(db.general.barPadding), 0)

  self:SetHearthColor()

  self.portText:SetFont(xb:GetFont(db.text.fontSize))
  local arc = self.arcantinaId or 253629
  if self.portOptions and self.portOptions[arc] then
    self.portText:SetText(self.portOptions[arc].text)
  else
    self.portText:SetText("")
  end

  self.portButton:SetSize(self.portText:GetWidth() + iconSize + db.general.barPadding, xb:GetHeight())
  self.portButton:SetPoint("LEFT", -(db.general.barPadding), 0)

  self.portText:SetPoint("RIGHT")

  self.portIcon:SetTexture(xb.constants.mediaPath..'datatexts\\garr')
  self.portIcon:SetSize(iconSize, iconSize)

  self.portIcon:SetPoint("RIGHT", self.portText, "LEFT", -(db.general.barPadding), 0)

  self:SetPortColor()

  -- popup removed; nothing to position

  local totalWidth = self.hearthButton:GetWidth() + db.general.barPadding
  self.portButton:Show()
  if self.portButton:IsVisible() then
    totalWidth = totalWidth + self.portButton:GetWidth()
  end
  self.hearthFrame:SetSize(totalWidth, xb:GetHeight())
  self.hearthFrame:SetPoint("RIGHT", -(db.general.barPadding), 0)
  self.hearthFrame:Show()
end

function TravelModule:ShowTooltip()
  GameTooltip:SetOwner(self.portButton, 'ANCHOR_'..xb.miniTextPosition)
  GameTooltip:ClearLines()
  local r, g, b, _ = unpack(xb:HoverColors())
  GameTooltip:AddLine("|cFFFFFFFF[|r"..L['Travel Cooldowns'].."|cFFFFFFFF]|r", r, g, b)
  for i, v in pairs(self.portOptions) do
    if IsUsableItem(v.portId) or IsPlayerSpell(v.portId) then
      if IsUsableItem(v.portId) then
        local _, cd, _ = GetItemCooldown(v.portId)
        local cdString = self:FormatCooldown(cd)
        GameTooltip:AddDoubleLine(v.text, cdString, r, g, b, 1, 1, 1)
      end
      if IsPlayerSpell(v.portId) then
        local _, cd, _ = GetSpellCooldown(v.portId)
        local cdString = self:FormatCooldown(cd)
        GameTooltip:AddDoubleLine(v.text, cdString, r, g, b, 1, 1, 1)
      end
    end
  end
  GameTooltip:Show()
end

function TravelModule:FindFirstOption()
  local firstItem = {portId = 253629, text = GetItemInfo(253629) or "Personal Key to the Arcantina"}
  if self.portOptions then
    for k,v in pairs(self.portOptions) do
      if self:IsUsable(v.portId) then
        firstItem = v
        break
      end
    end
  end
  return firstItem
end

function TravelModule:IsUsable(id)
  return IsUsableItem(id) or IsPlayerSpell(id)
end

function TravelModule:GetDefaultOptions()
  local firstItem = self:FindFirstOption()
  xb.db.char.portItem = xb.db.char.portItem or firstItem
  return 'travel', {
    enabled = true
  }
end

function TravelModule:GetConfig()
  return {
    name = self:GetName(),
    type = "group",
    args = {
      enable = {
        name = ENABLE,
        order = 0,
        type = "toggle",
        get = function() return xb.db.profile.modules.travel.enabled; end,
        set = function(_, val)
          xb.db.profile.modules.travel.enabled = val
          if val then
            self:Enable()
          else
            self:Disable()
          end
        end,
        width = "full"
      }
    }
  }
end
