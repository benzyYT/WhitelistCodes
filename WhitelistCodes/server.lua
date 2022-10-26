-- CREDITS
-- benzyYT       | Rewrote complete code to make it work the way I want it. Before I rewrote it, it was a standard password script with no database queries or discord bot compatibility.
-- Enfer         | Some bits of code.
-- Frazzle       | Basically 100% of the code that makes the passwords work (https://gist.github.com/FrazzIe/f59813c137496cd94657e6de909775aa)




Config = {}
Config.Active	    = true							-- Whether the system should be on
Config.Attempts		= 3								-- How many attempts the player has
Config.DeferralWait	= 0.5							-- This defines the time the user has to wait but it doesn't work out very well! (TODO: Fix this)




local lastDeferral = {}
local attempts = {}
local passwordCard = {["type"]="AdaptiveCard",["$schema"]="http://adaptivecards.io/schemas/adaptive-card.json",["version"]="1.5",["body"]={{["type"]="Container",["items"]={{["type"]="TextBlock",["text"]="Whitelist Code",["wrap"]=true},{["type"]="Input.Text",["placeholder"]="Whitelistcode eingeben",["style"]="Password",["id"]="password"},{["type"]="Container",["isVisible"]=false,["items"]={{["type"]="TextBlock",["text"]="Ungültiger Code",["wrap"]=true,["weight"]="Bolder"}}}}},{["type"]="ActionSet",["actions"]={{["type"]="Action.Submit",["title"]="Fertig"}}}}}

local license  = false



AddEventHandler("playerConnecting", function(name)
	for k,v in pairs(GetPlayerIdentifiers(source))do
			
		if string.sub(v, 1, string.len("license:")) == "license:" then
			license = v
			dt_coc = v:gsub('%license:', '')
		end
	end
end)




AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)


	local player = source
	local identifiers = GetPlayerIdentifiers(player)
	local identifiersNum = #GetPlayerIdentifiers(player)
	local allowed = false
	local newInfo = ""
	local oldInfo = ""


	if not Config.Active then
		return
	end


	deferrals.defer()
	lastDeferral["id" .. player] = os.clock()


	while lastDeferral["id" .. player] + Config.DeferralWait > os.clock() do
		Citizen.Wait(10)
	end
	deferrals.update("Daten werden geladen...")
	lastDeferral["id" .. player] = os.clock()


	if Config.Active then
		local function passwordCardCallback(data, rawData)
			local match = false

			if data then
				if data.password then
					local result = MySQL.scalar.await('SELECT 1 FROM codes WHERE code = ? AND used = 0;', { data.password })
					
					if result then
						MySQL.prepare('UPDATE `codes` SET `used` = 1 WHERE `codes`.`code` = ?;', { data.password })
						MySQL.prepare('INSERT INTO `codeswhitelist`(`identifier`) VALUES (?);', { dt_coc })
						match = true
					end
				end
			end

			if not match then
				if not attempts[player] then
					attempts[player] = 1
				else
					attempts[player] = attempts[player] + 1
				end

				if attempts[player] < Config.Attempts then
					showPasswordCard(player, deferrals, passwordCardCallback, true, attempts[player])
				else
					while lastDeferral["id" .. player] + Config.DeferralWait > os.clock() do
						Citizen.Wait(10)
					end
					deferrals.done("Du bist "..Config.Attempts.." Mal fehlgeschlagen, bitte versuche es erneut.")
				end
			else
				while lastDeferral["id" .. player] + Config.DeferralWait > os.clock() do
					Citizen.Wait(10)
				end
				deferrals.done()
			end
		end
		
		local cres = MySQL.scalar.await('SELECT 1 FROM codeswhitelist WHERE identifier = ?', { dt_coc })
		
		if cres then
			deferrals.done()
		else
			showPasswordCard(player, deferrals, passwordCardCallback)
		end
	end
end)
			
		

function showPasswordCard(player, deferrals, callback, showError, numAttempts)
	local card = passwordCard
	card.body[1].items[3].isVisible = showError and true or false
	if showError and numAttempts then
		if numAttempts <= 1 then
			card.body[1].items[3].items[1].text = "Ungültiger Code! ("..(Config.Attempts - numAttempts).." Versuche verbleiben!)"
		else
			card.body[1].items[3].items[1].text = "Ungültiger Code! ("..(Config.Attempts - numAttempts).." Versuche verbleiben!)"
		end
	end
	while lastDeferral["id" .. player] + Config.DeferralWait > os.clock() do
		Citizen.Wait(10)
	end
	deferrals.presentCard(card, callback)
	lastDeferral["id" .. player] = os.clock()
end
