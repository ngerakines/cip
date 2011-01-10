
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end);
f:RegisterEvent("PLAYER_LOGIN");

local isWaiting = nil;
local inCombat = nil;

function f:PLAYER_LOGIN(...)
	local class = select(2, UnitClass("player"));
	f:UnregisterEvent("PLAYER_LOGIN"); self.PLAYER_LOGIN = nil;
	f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function f:COMBAT_LOG_EVENT_UNFILTERED(...)
	if inCombat then return end
	if isWaiting == 1 then return end
	-- print "waiting set"
	isWaiting = 1
	CIP__wait(3, check)
end

function f:PLAYER_REGEN_ENABLED()
	inCombat = nil;
end

function f:PLAYER_REGEN_DISABLED()
	inCombat = 1;
end

function check()
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
		isWaiting = nil
		-- print "waiting unset"
		return
	end
	-- print "should be checking now."
	local ready = true
	if GetNumPartyMembers() > 0 then
		isPartyReady()
	else
		isRaidReady()
	end
	isWaiting = nil;
	-- print "waiting unset"
	-- for each party member
	-- - is health at max
	-- - is mana at max
end

function isRaidReady()
	local ready = true;
	for i = 1, GetNumRaidMembers() do
		if UnitHealth("raid"..i) < UnitHealthMax("raid"..i) then
			local playerName = UnitName("raid"..i);
			ChatFrame1:AddMessage('Not ready: ' .. playerName .. ' (health)');
			ready = false;
		end
		if UnitPower("raid"..i) < UnitPowerMax("raid"..i) then
			local playerName = UnitName("raid"..i);
			ChatFrame1:AddMessage('Not ready: ' .. playerName .. '(power)');
			ready = false;
		end
	end
	return ready;
end

function isPartyReady()
	local ready = true;
	for i = 1, GetNumPartyMembers() do
		local playerName = UnitName("party"..i);
		if UnitHealth("party"..i) < UnitHealthMax("party"..i) then
			-- ChatFrame1:AddMessage('Not ready: ' .. playerName .. '(health)');
			ready = false;
		end
		if UnitPower("party"..i) < UnitPowerMax("party"..i) then
			-- ChatFrame1:AddMessage('Not ready: ' .. playerName .. '(power)');
			ready = false;
		end
	end
	return ready;
end

StaticPopupDialogs["TYLER_IS_A_NUB"] = {
  text = "Your group is ready.",
  button1 = OKAY, timeout = 30, hideOnEscape = 1, showAlert = 1
};

-- pragma mark -

local waitTable = {};
local waitFrame = nil;

function CIP__wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end
