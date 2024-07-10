if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_rvng.vmt")
end

function ROLE:PreInitialize()
  self.color = Color(255, 82, 191, 255)

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
    -- find a random innocent player
    local randomPlyNumber = math.random(#(roles.GetTeamMembers(TEAM_INNOCENT)))
    -- iterate through players
    for k, v in pairs(roles.GetTeamMembers(TEAM_INNOCENT)) do
      -- find our love target
      if k == randomPlyNumber then
        loverPly = v
        print("Randomly selected player: " .. loverPly:Nick())
      end
      -- find the revenger
      if v:GetSubRole() == ROLE_REVENGER then
        revengerPly = v
        print("Revenger is: " .. revengerPly:Nick())
      end
		end

    -- tell revenger who they are in love with
    EPOP:AddMessage(revengerPly, "You are in love with " .. loverPly:Nick(), "If someone kills them, you will track their location!", 6, true)
	end

  hook.Add("PlayerDeath", "RevengerGetKiller", function(victim, inflictor, attacker)
    -- only print if the victim was our loverply
    if victim ~= loverPly then return end
    -- only print if attacker is human
    if not IsValid(attacker) or not IsPlayer(attacker) then return end
    -- update our loverKiller value
    loverKiller = attacker
    -- add a EPOP to the revengers screen
    EPOP:AddMessage(revengerPly, "Your love, " .. loverPly:Nick() .. ", has died.", "They were killed by " .. loverKiller:Nick() .. "!!", 6, true)
  end)

  -- Reset stuff on death and rolechange and round end
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
    loverPly = nil
    revengerPly = nil
    loverKiller = nil
	end
  hook.Add("TTTEndRound", "RevengerEndRound", function()
    loverPly = nil
    revengerPly = nil
    loverKiller = nil
  end)
end