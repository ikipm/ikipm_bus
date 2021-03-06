ESX = nil

showtext = true
point = ""
onRoute = false
destinationSelected = ""

local options ={}

-- Load ESX
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent(Config.ESXShared, function(obj) ESX = obj end)
		Citizen.Wait(100)
	end
end)

-- Add stations to options variable
Citizen.CreateThread(function()
    for index, value in pairs(Config.Locations) do
        table.insert(options, {label = value.Name, value = index})
    end
end)

-- Create Schedules
Citizen.CreateThread(function()
    while true do
        Wait(10)
        if showtext then
            for index, value in pairs(Config.Locations) do
                if #(value.Schedule - GetEntityCoords(PlayerPedId())) <= 3 then
                    DrawText3D(value.Schedule.x, value.Schedule.y, value.Schedule.z, _U("schedule"))
                    if IsControlJustReleased(0, 38) then
                        point = value
                        showtext = false
                        openStationMenu()
                    end
                end
            end
        end
    end
end)

-- Create blips
Citizen.CreateThread(function()
	for index, value in pairs(Config.Locations) do
		local blip = AddBlipForCoord(value.Schedule)

		SetBlipSprite (blip, Config.BlipSprite)
		SetBlipDisplay(blip, 2)
		SetBlipScale  (blip, Config.BlipScale)
		SetBlipColour (blip, Config.BlipColour)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentSubstringPlayerName(_U("blip"))
		EndTextCommandSetBlipName(blip)
	end
end)


---------------
-- Functions --
---------------

function openStationMenu()
    ESX.UI.Menu.Open( "default", GetCurrentResourceName(), "bus", {
	title    = _U("menu_title"),
	align = "bottom-right",
	elements = options
    }, function(data, menu) -- Options and functions
        menu.close()
        destinationSelected = data.current.value
        createRoute(point.Departure, point.DepHead, Config.Locations[destinationSelected].Arrival, Config.Locations[destinationSelected].Price)
        showtext = true
    end, function(data, menu) -- Close the menu
	menu.close()
        showtext = true
    end)
end

function createRoute(departure, point, destination, money)
    onRoute = true
    player = PlayerPedId()

    ESX.Game.SpawnVehicle(Config.Vehicle, departure, point, function(vehicle)
        TaskWarpPedIntoVehicle(player, vehicle, 0)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)

        -- Create NPC
        npc = CreatePed(vehicle, -1, Config.NPC)
        SetEntityInvincible(npc, true)
        SetDriverAbility(npc, 1.0)
        SetDriverAggressiveness(npc, 0.0)

        -- Drive to coords
        TaskVehicleDriveToCoordLongrange(npc, vehicle, destination.x, destination.y, destination.z, Config.Speed, 786603, 10.0)

        Citizen.CreateThread(function()
            while onRoute do
                Wait(5000)
                if #(destination - GetEntityCoords(player)) <= 15 and onRoute then
                    FinRoute(vehicle, npc, money)
                    ESX.ShowNotification(_U("success", money))
                elseif not IsPedInVehicle(player, vehicle, true) and onRoute then
                    FinRoute(vehicle, npc, money)
                    ESX.ShowNotification(_U("error", money))
                end
            end
        end)
    end)
end

function DrawText3D(x, y, z, text)
    	coords = vector3(x, y, z)
	SetTextScale(0.35, 0.35)
    	SetTextFont(4)
    	SetTextProportional(1)
    	SetTextColour(255, 255, 255, 215)
    	SetTextEntry("STRING")
	SetTextCentre(true)
    	AddTextComponentString(text)
    	SetDrawOrigin(x,y,z, 0)
    	DrawText(0.0, 0.0)
    	local factor = (string.len(text)) / 370
    	DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    	ClearDrawOrigin()
end

function CreatePed(vehicle, pos, model)
	local model = GetHashKey(model)

	if DoesEntityExist(vehicle) then
		if IsModelValid(model) then
			RequestModel(model)
			while not HasModelLoaded(model) do
				Wait(100)
			end

			local ped = CreatePedInsideVehicle(vehicle, 26, model, pos, true, false)
			SetBlockingOfNonTemporaryEvents(ped, true)
			SetEntityAsMissionEntity(ped, true, true)

			SetModelAsNoLongerNeeded(model)
			return ped
		end
	end
end

function FinRoute(vehicle, npc, money)
    onRoute = false

    DeletePed(npc)
    ESX.Game.DeleteVehicle(vehicle)
    TriggerServerEvent('ikipm_bus:getMoney', money)
end
