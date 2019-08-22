_addon.author = 'sruon'
_addon.commands = {'autopup','pup'}
_addon.name = 'AutoPUP'
_addon.version = '1.0.0.0'

require('luau')
require('pack')
require 'logger'
packets = require('packets')
texts = require('texts')
config = require('config')

ids = require('pup_ids')
get = require('pup_get')
cast = require('pup_cast')

default = {
	delay=1,
    active=true,
    maneuvers={wind=1,light=1,fire=1},
    box={text={size=10}}
    }

settings = config.load(default)

del = 0
counter = 0
interval = 0.2
last_coords = 'fff':pack(0,0,0)

local display_box = function()
    local str
    if settings.actions then
        str = 'AutoPUP: Actions [On]'
    else
        str = 'AutoPUP: Actions [Off]'
    end
    if not settings.active then return str end
    for k,v in pairs(settings.maneuvers) do
        str = str..'\n %s:[x%d]':format(k:ucfirst(),v)
    end
    return str
end

pup_status = texts.new(display_box(),settings.box,settings)
pup_status:show()

function do_stuff()
    if not settings.actions then return end
    counter = counter + interval
    if counter > del then
        counter = 0
        del = interval
        local play = windower.ffxi.get_player()
        if not play or play.main_job ~= 'PUP' or (play.status ~= 1 and play.status ~= 0) then return end
		if play ~= nil then
			local player_mob = windower.ffxi.get_mob_by_id(play.id)
			if player_mob ~= nil then
				local pet_index = player_mob.pet_index
				if pet_index == nil then return end
            end
		end
        local buffs = get.buffs(play.buffs)
        local ability_recasts = windower.ffxi.get_ability_recasts()
		if buffs.overload then
			if ability_recasts[114] <= 0 then -- Cooldown
				cast.JA('input /ja "Cooldown" <me>')
			end
		end
        if casting or buffs.stun or buffs.sleep or buffs.charm or buffs.terror or buffs.petrification or buffs.overload then return end
        
		local maneuver = cast.check_maneuver(settings.maneuvers,'AoE',buffs,ability_recasts) 
		if maneuver then cast.maneuver(maneuver,'<me>',buffs,ability_recasts) return end
    end
end

do_stuff:loop(interval)

windower.register_event('incoming chunk', function(id,original,modified,injected,blocked)
    if id == 0x028 then
        local packet = packets.parse('incoming', original)
        if packet['Actor'] ~= windower.ffxi.get_mob_by_target('me').id then return false end
        if packet['Category'] == 8 then
            if (packet['Param'] == 24931) then
            -- Begin Casting
                casting = true
            elseif (packet['Param'] == 28787) then
            -- Failed Casting
                casting = false
                del = 2.5
            end
        elseif packet['Category'] == 4 then
            -- Finish Casting
            casting = false
            del = settings.delay
        elseif L{3,5}:contains(packet['Category']) then
            casting = false
        elseif L{7,9}:contains(packet['Category']) then
            casting = true
        end
    elseif id == 0x029 then
        local packet = packets.parse('incoming', original)
        --table.vprint(packet)
    end
end)

windower.register_event('outgoing chunk', function(id,data,modified,is_injected,is_blocked)
    if id == 0x015 then
        is_moving = last_coords ~= modified:sub(5, 16)
        last_coords = modified:sub(5, 16)
    end
end)

function addon_message(str)
    windower.add_to_chat(207, _addon.name..': '..str)
end

windower.register_event('addon command', function(...)
    local commands = {...}
    for x=1,#commands do commands[x] = windower.convert_auto_trans(commands[x]):lower() end
    if not commands[1] or S{'on','off'}:contains(commands[1]) then
        if not commands[1] then
            settings.actions = not settings.actions
        elseif commands[1] == 'on' then
            settings.actions = true
        elseif commands[1] == 'off' then
            settings.actions = false
        end
        addon_message('Actions %s':format(settings.actions and 'On' or 'Off'))
    else
        if commands[1] == 'save' then
            settings:save()
            addon_message('settings Saved.')
        elseif get.maneuvers[commands[1]] and commands[2] then
            local n = tonumber(commands[2])
            if n and n ~= 0 and n <= 3 then
				local total_man = 0
				for k,v in pairs(settings.maneuvers) do
					total_man = total_man + v
				end
				if total_man + n > 3 then
					addon_message('Total maneuvers count (%d) exceeds 3':format(total_man + n))
				else
					settings.maneuvers[commands[1]] = n
					addon_message('%s x%d':format(commands[1],n))
				end
            elseif commands[2] == '0' or commands[2] == 'off' then              
				settings.maneuvers[commands[1]] = nil
				addon_message('%s Off':format(commands[1]))
            elseif n then
                addon_message('Error: %d exceeds the maximum value for %s.':format(n,commands[1]))
            end
        elseif type(settings[commands[1]]) == 'string' and commands[2] then
            local maneuver = get.maneuver(table.concat(commands, ' ',2))
            if maneuver then
                settings[commands[1]] = maneuver.enl
                addon_message('%s is now set to %s':format(commands[1],maneuver.enl))
            else
                addon_message('Invalid maneuver name.')
            end
       elseif type(settings[commands[1]]) == 'number' and commands[2] and tonumber(commands[2]) then
            settings[commands[1]] = tonumber(commands[2])
            addon_message('%s is now set to %d':format(commands[1],settings[commands[1]]))
        elseif type(settings[commands[1]]) == 'boolean' then
            if (not commands[2] and settings[commands[1]] == true) or (commands[2] and commands[2] == 'off') then
                settings[commands[1]] = false
            elseif (not commands[2]) or (commands[2] and commands[2] == 'on') then
                settings[commands[1]] = true
            end
            addon_message('%s %s':format(commands[1],settings[commands[1]] and 'On' or 'Off'))
        elseif commands[1] == 'eval' then
            assert(loadstring(table.concat(commands, ' ',2)))()
        end
    end
    pup_status:text(display_box())
end)

function event_change()
    settings.actions = false
    casting = false
    pup_status:text(display_box())
end

function status_change(new,old)
    casting = false
    if new == 2 or new == 3 then
        event_change()
    end
end

windower.register_event('status change', status_change)
windower.register_event('zone change','job change','logout', event_change)
