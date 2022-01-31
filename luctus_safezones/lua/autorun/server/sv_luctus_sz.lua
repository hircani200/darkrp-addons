--Luctus Safezones
--Made by OverlordAkise

util.AddNetworkString("luctus_safezone")
util.AddNetworkString("luctus_safezone_delete")

hook.Add("EntityTakeDamage", "luctus_safezones_god", function(ply, dmginfo)
  if ply:IsPlayer() and ply.luctusInSafezone then
    dmginfo:SetDamage(0)
  end
end)

hook.Add("PlayerSpawnObject", "luctus_safezones_nospawning", function(ply, model, skinNumber )
  if ply.luctusInSafezone then
    return false
  end
end)

hook.Add("PlayerInitialSpawn", "luctus_safezone_init", function(ply)
  local res = sql.Query("CREATE TABLE IF NOT EXISTS luctus_safezones(pos_one VARCHAR(200), pos_two VARCHAR(200))")
  if res == false then 
    print("[luctus_safezones] ERROR DURING TABLE CREATION!")
    print(sql.LastError())
    return
  end
  if res == nil then print("[luctus_safezones] PreInit Done!") end
  
  res = sql.Query("SELECT *,rowid FROM luctus_safezones")
  if res == false then
    print("[luctus_safezones] ERROR DURING SAFEZONE LOADING FROM DB!")
    print(sql.LastError())
    return
  end
  
  if res and #res > 0 then
    for k,v in pairs(res) do
      p1 = Vector(v["pos_one"])
      p2 = Vector(v["pos_two"])
      local ent = ents.Create("luctus_safezone")
      ent:SetPos( (p1 + p2) / 2 )
      ent.min = p1
      ent.max = p2
      ent:Spawn()
      ent:SetID(v["rowid"])
    end
  end
  print("[luctus_safezones] Safezones spawned!")
  hook.Remove("PlayerInitialSpawn", "luctus_safezone_init")
end)

function luctusLeftSafezone(ply)
  ply.luctusInSafezone = false
  net.Start("luctus_safezone")
    net.WriteBool(false)
  net.Send(ply)
end

function luctusEnteredSafezone(ply)
  ply.luctusInSafezone = true
  net.Start("luctus_safezone")
    net.WriteBool(true)
  net.Send(ply)
end

function luctusSaveSafezone(posone, postwo)
  local res = sql.Query("INSERT INTO luctus_safezones VALUES("..sql.SQLStr(posone)..", "..sql.SQLStr(postwo)..")")
  if res == false then 
    print("[luctus_safezones] ERROR DURING SAVING SAFEZONE!")
    print(sql.LastError())
    return
  end
  if res == nil then print("[luctus_safezones] Safezone saved successfully!") end
  
  local ent = ents.Create("luctus_safezone")
  ent:SetPos( (posone + postwo) / 2 )
  ent.min = posone
  ent.max = postwo
  ent:Spawn()
  
  res = sql.QueryRow("SELECT rowid FROM luctus_safezones ORDER BY rowid DESC limit 1")
  if res == false then 
    print("[luctus_safezones] ERROR DURING SETTING SAFEZONE ID!")
    print(sql.LastError())
    return
  end
  ent:SetID(tonumber(res["rowid"]))
end

net.Receive("luctus_safezone_delete", function(len, ply)
  if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end
  local rowid = net.ReadString()
  if not tonumber(rowid) then return end
  res = sql.QueryRow("DELETE FROM luctus_safezones WHERE rowid = "..rowid)
  if res == false then 
    print("[luctus_safezones] ERROR DURING SETTING SAFEZONE ID!")
    print(sql.LastError())
    return
  end
  print("[luctus_safezones] DB Successfully deleted safezone!")
  
  for i=1,#ents.GetAll() do
    if ents.GetAll()[i]:GetClass() == "luctus_safezone" and ents.GetAll()[i]:GetID() == tonumber(rowid) then
      ents.GetAll()[i]:Remove()
      break
    end
  end
  print("[luctus_safezones] Successfully removed safezone from map!")
end)

print("[luctus_safezones] SV loaded!")