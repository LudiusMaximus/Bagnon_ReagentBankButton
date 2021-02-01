local Addon = Bagnon
local L = LibStub('AceLocale-3.0'):GetLocale("Bagnon")


local ReagentbankToggle = Addon.Tipped:NewClass('ReagentbankToggle', 'CheckButton', true)


--[[ Constructor ]]--

function ReagentbankToggle:New(...)
  local b = self:Super(ReagentbankToggle):New(...)
  b:SetScript('OnHide', b.UnregisterAll)
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
    local reagentBagButton = Addon.Bag(self:GetParent(), REAGENTBANK_CONTAINER)
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

  local reagentBagButton = Addon.Bag(self:GetParent(), REAGENTBANK_CONTAINER)

  -- The focus is only helpful if you have the reagent bank included in your
  -- normal bank. For an exclusive reagent bank it is anoying.
  local profile = self:GetProfile()
  if not profile.exclusiveReagent then
    reagentBagButton:SetFocus(true)
  end

  GameTooltip:SetOwner(self, self:GetRight() > (GetScreenWidth() / 2) and 'ANCHOR_LEFT' or 'ANCHOR_RIGHT')
  GameTooltip:SetText(REAGENT_BANK)

  if reagentBagButton:IsPurchasable() then
    GameTooltip:AddLine(L.TipPurchaseBag:format(L.Click))
    SetTooltipMoney(GameTooltip, reagentBagButton:GetInfo().cost)
  else
    GameTooltip:AddLine((reagentBagButton:IsToggled() and L.TipHideBag or L.TipShowBag):format(L.LeftClick), 1,1,1)
    GameTooltip:AddLine(L.TipDepositReagents:format(L.RightClick), 1,1,1)
  end

  GameTooltip:Show()
end


function ReagentbankToggle:OnLeave()
  local reagentBagButton = Addon.Bag(self:GetParent(), REAGENTBANK_CONTAINER)

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

  local reagentBagButton = Addon.Bag(self:GetParent(), REAGENTBANK_CONTAINER)

  if reagentBagButton and not reagentBagButton:GetInfo().owned then

    -- If the reagent button was still toggled from watching another character
    -- (both the current and the last watched character having "Character Specific Settings" disabled)
    -- we switch automatically to the normal bank view.
    if self:GetChecked() then
        -- Toggle the bank button.
        Addon.Bag(self:GetParent(), BANK_CONTAINER):OnClick('LeftButton')
        Addon.Bag(self:GetParent(), BANK_CONTAINER):OnLeave()
    end

    SetItemButtonTextureVertexColor(self, 1,0.1,0.1)
    -- self:GetNormalTexture():SetVertexColor(1,0.1,0.1)
  else
    SetItemButtonTextureVertexColor(self, 1,1,1)
    -- self:GetNormalTexture():SetVertexColor(1,1,1)
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

  if self.frameID == 'bank' then
    tinsert(self.menuButtons, self.reagentbankToggle or self:CreateReagentbankToggle())
  end

end


hooksecurefunc(Bagnon.Frame, "ListMenuButtons", AppendReagentBankToggle)

