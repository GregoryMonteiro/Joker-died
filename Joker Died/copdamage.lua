_G.JokerDied = _G.JokerDied or {}
JokerDied.peer_joker_qty = {}

if _G["CopDamage"] ~= nil then
    -- If a converted cop dies, unregister them from the converts list.
    Hooks:PostHook(CopDamage, "_on_death", "TESTE_RemoveJokerOnDeath", function(self)
        local unit = self._unit
        local peer_id = unit:base().joker_owner_peer_id_TESTE
        if peer_id then
            if table.contains(JokerDied.peer_joker_qty[peer_id], tostring(unit:key())) then
                table.remove(JokerDied.peer_joker_qty[peer_id], tablefind(JokerDied.peer_joker_qty[peer_id], tostring(unit:key())))
            end

            local peer = getPeer(peer_id)
            if peer_id == peer:id() then--se o jogador sofrer um disconect essa igualdade não vai se confirmar pois vai retornar o id do host
                local peer_name = peer:name()
                message(
                    string.format(
                        "%s's joker died (%s joker left)", 
                        peer_name,
                        (#JokerDied.peer_joker_qty[peer_id])
                    ), 1
                )
            end
        end
    end)
end


if _G["CopBrain"] ~= nil then
    -- On convert, register the unit as a joker
    Hooks:PostHook(CopBrain, "convert_to_criminal", "TESTE_registerjoker", function(self, mastermind_criminal)
        -- Assign the converter's peer ID as owner
        if alive(mastermind_criminal) then
            local unit = self._unit
            local peer_id = managers.network:session():peer_by_unit(mastermind_criminal):id() or 1
            unit:base().joker_owner_peer_id_TESTE = peer_id
            insert_peer_joker_qty(peer_id,unit)
        end
    end)
end

if _G["GroupAIStateBase"] ~= nil then
    Hooks:PostHook(GroupAIStateBase, "convert_hostage_to_criminal", "TESTE_converthostagetocriminal", function(self, unit, peer_unit)
        local player_unit = peer_unit or managers.player:player_unit()
        local unit_data = self._police[unit:key()]
        if unit_data and alive(player_unit) then
            local peer_id = player_unit:network() and player_unit:network():peer() and player_unit:network():peer():id()
            unit:base().joker_owner_peer_id_TESTE = peer_id
            insert_peer_joker_qty(peer_id,unit)
        end
    end)
end

if _G["UnitNetworkHandler"] ~= nil then
    Hooks:PostHook(UnitNetworkHandler, "mark_minion", "TESTE_unitnetwork_markminion_applycontours", function(self, unit, minion_owner_peer_id)
        -- I'm not paranoid, this really did happen
        if not unit or not alive(unit) then
            return
        end

        unit:base().joker_owner_peer_id_TESTE = minion_owner_peer_id
        insert_peer_joker_qty(minion_owner_peer_id,unit)
    end)
end

function getPeer(peer_id)
    local session = managers.network:session()
    return session:peer(peer_id) or session:local_peer()
end

function message(message, type, color)
    if type == 1 then--to all
        managers.chat:send_message(ChatManager.GAME, (managers.network.account:username() or "Offline"), message)
    else--only me
        managers.chat:_receive_message(1, "TESTE", tostring(message), color or Color("2980b9"))
    end
end

function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

function insert_peer_joker_qty(peer_id,unit)
    if JokerDied.peer_joker_qty[peer_id] == nil then
        JokerDied.peer_joker_qty[peer_id] = {}
    end

    if not table.contains(JokerDied.peer_joker_qty[peer_id], tostring(unit:key())) then
        table.insert(JokerDied.peer_joker_qty[peer_id], tostring(unit:key()))
    end
end