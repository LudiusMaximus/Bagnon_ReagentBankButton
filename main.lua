local MODULE =  ...
local ADDON, Addon = MODULE:match("[^_]+"), _G[MODULE:match("[^_]+")]
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Module = Bagnon:NewModule("ReagentBankButton", Addon)


local ReagentbankToggle = Addon:NewClass('ReagentbankToggle', 'CheckButton')

--[[ Constructor ]]--

function ReagentbankToggle:New(parent)
  local b = self:Bind(CreateFrame('CheckButton', nil, parent, ADDON .. self.Name .. 'Template'))
  b:SetScript('OnHide', b.UnregisterSignals)
  b:SetScript('OnClick', b.OnClick)
  b:SetScript('OnEnter', b.OnEnter)
  b:SetScript('OnLeave', b.OnLeave)
  b:SetScript('OnShow', b.OnShow)
  b:RegisterForClicks('anyUp')
  b:Update()

  return b
end


--[[ Events ]]--

function ReagentbankToggle:OnShow()
  self:RegisterFrameSignal('OWNER_CHANGED', 'Update')
  self:RegisterEvent('REAGENTBANK_PURCHASED', 'Update')
  self:Update()
end

function ReagentbankToggle:OnClick(button)
  if button == 'LeftButton' then
    local reagentBagButton = _G[ADDON .. "Bag" .. REAGENTBANK_CONTAINER]
    reagentBagButton:Click(button)

    -- The focus is only helpful if you have the reagent bank included in your
    -- normal bank. For an exclusive reagent bank it is anoying.
    local profile = self:GetProfile()
    if profile.exclusiveReagent then
      reagentBagButton:SetFocus(false)
    end
  else
    DepositReagentBank()
  end
  self:Update()
end

function ReagentbankToggle:OnEnter()
  local reagentBagButton = _G[ADDON .. "Bag" .. REAGENTBANK_CONTAINER]

  -- The focus is only helpful if you have the reagent bank included in your
  -- normal bank. For an exclusive reagent bank it is anoying.
  local profile = self:GetProfile()
  if not profile.exclusiveReagent then
    reagentBagButton:SetFocus(true)
  end

  GameTooltip:SetOwner(self, self:GetRight() > (GetScreenWidth() / 2) and 'ANCHOR_LEFT' or 'ANCHOR_RIGHT')
  GameTooltip:SetText(REAGENT_BANK)
  if reagentBagButton:IsPurchasable() then
    GameTooltip:AddLine(L.TipPurchaseBag)
    SetTooltipMoney(GameTooltip, reagentBagButton:GetCost())
  else
    GameTooltip:AddLine((reagentBagButton:IsToggled() and L.TipHideBag or L.TipShowBag):format(L.LeftClick), 1,1,1)
    GameTooltip:AddLine(L.TipDepositReagents:format(L.RightClick), 1,1,1)
  end

  GameTooltip:Show()
end

function ReagentbankToggle:OnLeave()
  local reagentBagButton = _G[ADDON .. "Bag" .. REAGENTBANK_CONTAINER]
  reagentBagButton:SetFocus(false)

  if GameTooltip:IsOwned(self) then
    GameTooltip:Hide()
  end
end


--[[ API ]]--

function ReagentbankToggle:OpenFrame(id, addon, owner)
  if not addon or LoadAddOn(addon) then
    Addon:CreateFrame(id):SetOwner(owner or self:GetOwner())
    Addon:ShowFrame(id)
  end
end

function ReagentbankToggle:Update()
  self:SetChecked(self:IsReagentbagShown())

  local reagentBagButton = _G[ADDON .. "Bag" .. REAGENTBANK_CONTAINER]
  -- Unfortunately, LibItemCache-2.0 does not yet allow to check 'owned' status of cached bags.
  -- So we assume cached bags as owned like the rest of Bagnon does.
  if reagentBagButton and reagentBagButton:IsPurchasable() then
  
    -- Remove the glow if this was still selected from another character.
    self:SetChecked(false)
  
    self.BagnonReagentbankToggleTexture:SetVertexColor(1,0.1,0.1)
  else
    self.BagnonReagentbankToggleTexture:SetVertexColor(1,1,1)
  end
end

function ReagentbankToggle:IsReagentbagShown()
  local profile = self:GetProfile()
  return not profile.hiddenBags[REAGENTBANK_CONTAINER]
end





function Addon.Frame:CreateReagentbankToggle()
  self.reagentbankToggle = Addon.ReagentbankToggle:New(self)
  return self.reagentbankToggle
end

-- Append the reagent bank button to the menu button list.
local AppendReagentBankToggle = function(self)
  
  if self:GetName() == "BagnonFramebank" then
    tinsert(self.menuButtons, self.reagentbankToggle or self:CreateReagentbankToggle())
  end
end

-- Must always create the bag frame, otherwise the tooltip for the reagent bag button will not work.
local CreateBagFrameForReagentsbankToggle = function(self)
  if self:GetName() == "BagnonFramebank" and not self.bagFrame then
    self:CreateBagFrame()
  end
  
  
  -- Remove the glow if this was still selected from another character.
  local reagentBagButton = _G[ADDON .. "Bag" .. REAGENTBANK_CONTAINER]
  if reagentBagButton and reagentBagButton:IsPurchasable() then
    reagentBagButton:SetChecked(false)
  end
  
  
end

Module.OnEnable = function(self)
  hooksecurefunc(Bagnon.Frame, "ListMenuButtons", AppendReagentBankToggle)
  hooksecurefunc(Bagnon.Frame, "PlaceBagFrame", CreateBagFrameForReagentsbankToggle)
end
