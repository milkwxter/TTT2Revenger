if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_rvng.vmt")
end

function ROLE:PreInitialize()
  self.color = Color(215, 1, 253, 255)

  self.abbr = "rvng" -- abbreviation
  self.surviveBonus = 0 -- bonus multiplier for every survive while another player was killed
  self.scoreKillsMultiplier = 2 -- multiplier for kill of player of another team
  self.scoreTeamKillsMultiplier = -8 -- multiplier for teamkill
  self.unknownTeam = true

  self.defaultTeam = TEAM_INNOCENT

  self.conVarData = {
    pct = 0.17, -- necessary: percentage of getting this role selected (per player)
    maximum = 1, -- maximum amount of roles in a round
    minPlayers = 6, -- minimum amount of players until this role is able to get selected
    credits = 0, -- the starting credits of a specific role
    togglable = true, -- option to toggle a role for a client if possible (F1 menu)
    random = 33,
    traitorButton = 0, -- can use traitor buttons
    shopFallback = SHOP_DISABLED
  }
end

-- now link this subrole with its baserole
function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_INNOCENT)
end

-- local variables that are very important
local loverPly, revengerPly, loverKiller

if SERVER then
	-- Do stuff on respawn and rolechange
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
    -- make a list of all innocent players minus the revenger
    local innocentMinusRevengerList = roles.GetTeamMembers(TEAM_INNOCENT)
    for k, v in pairs(innocentMinusRevengerList) do
      if v:GetSubRole() == ROLE_REVENGER then
        revengerPly = v
        print("Revenger is: " .. revengerPly:Nick())
        table.remove(innocentMinusRevengerList, k)
      end
    end

    -- get a random index from our list
    local randomPlyNumber = math.random(#innocentMinusRevengerList)
    -- iterate through players
    for k, v in pairs(innocentMinusRevengerList) do
      -- find our love target
      if k == randomPlyNumber then
        loverPly = v
        print("Randomly selected player: " .. loverPly:Nick())
      end
		end

    -- tell revenger who they are in love with
    EPOP:AddMessage(revengerPly, {text = "You are in love with " .. loverPly:Nick(), color = REVENGER.color}, "If they are killed by another player, you will gain a damage bonus against their killer and learn their name.", 6, true)
	
    -- add marker vision to the lovey guy
    local mvObject = loverPly:AddMarkerVision("mv_revenger")
    mvObject:SetOwner(ROLE_REVENGER)
    mvObject:SetVisibleFor(VISIBLE_FOR_ROLE)
    mvObject:SyncToClients()
  end

  hook.Add("PlayerDeath", "RevengerGetKiller", function(victim, inflictor, attacker)
    -- only print if the victim was our loverply
    if victim ~= loverPly then return end
    -- only print if attacker is human
    if not IsValid(attacker) or not IsPlayer(attacker) then return end
    -- update our loverKiller value
    loverKiller = attacker
    -- add a EPOP to the revengers screen
    EPOP:AddMessage(revengerPly, {text = "Your love, " .. loverPly:Nick() .. ", has died.", color = REVENGER.color}, "They were killed by " .. loverKiller:Nick() .. "!! Go get revenge!", 6, true)
    -- add a EPOP to the lover killers' screen
    EPOP:AddMessage(loverKiller, {text = "You just broke the Revenger's Heart!", color = REVENGER.color}, revengerPly:Nick() .. " now does extra damage to you. Be careful!", 6, true)
    -- remove wallhax
    victim:RemoveMarkerVision("mv_revenger")
  end)

  -- Reset stuff on death and rolechange and round begin/end
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
    loverPly = nil
    revengerPly = nil
    loverKiller = nil
	end
  hook.Add("TTTBeginRound", "RevengerBeginRound", function()
    loverPly = nil
    revengerPly = nil
    loverKiller = nil
  end)
  hook.Add("TTTEndRound", "RevengerEndRound", function()
    loverPly:RemoveMarkerVision("mv_revenger")
    loverPly = nil
    revengerPly = nil
    loverKiller = nil
  end)

  -- make revenger do extra damage to his lovers' killer
  hook.Add("EntityTakeDamage", "ttt2_revenger_revenge_damage", function(target, dmginfo)
    -- make sure the lover killer exists before we do any math
    if loverKiller == nil then return end

    -- get the attacker
    local attacker = dmginfo:GetAttacker()

    -- make sure the attacker is valid and also the attacker must be an revenger
    if not IsValid(target) or not target:IsPlayer() then return end
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not attacker:GetSubRole() == ROLE_REVENGER then return end
    
    if target == loverKiller then
      dmginfo:SetDamage(dmginfo:GetDamage() * 1.5)
    end
  end)
end

-- actual wallhacks part DONT TOUCH
if CLIENT then
	local TryT = LANG.TryTranslation
	local ParT = LANG.GetParamTranslation

	local materialRat = Material("vgui/ttt/dynamic/roles/icon_rvng.vmt")

	hook.Add("TTT2RenderMarkerVisionInfo", "HUDDrawMarkerVisionRatPlayer", function(mvData)
		local ent = mvData:GetEntity()
		local mvObject = mvData:GetMarkerVisionObject()

    if not mvObject:IsObjectFor(ent, "mv_revenger") then return end

		local distance = math.Round(util.HammerUnitsToMeters(mvData:GetEntityDistance()), 1)

		mvData:EnableText()

		mvData:AddIcon(materialRat)
		mvData:SetTitle("Your lover, " .. ent:Nick())

		mvData:AddDescriptionLine(ParT("marker_vision_distance", {distance = distance}))
		mvData:AddDescriptionLine(TryT(mvObject:GetVisibleForTranslationKey()), COLOR_SLATEGRAY)
	end)
end