-- CREDITS
-- benzyYT       | Rewrote complete code to make it work the way I want it. Before I rewrote it, it was a standard password script with no database queries or discord bot compatibility.
-- Enfer         | Some bits of code.
-- Frazzle       | Basically 100% of the code that makes the passwords work (https://gist.github.com/FrazzIe/f59813c137496cd94657e6de909775aa)



-- Config
Config = {}
Config.UseAllowlist	= false								-- Keep the COMPLETE Config as it is it will destroy the script, I will delete the config later, as it is from the script from before.
Config.UsePassword	= true								-- Keep the COMPLETE Config as it is it will destroy the script, I will delete the config later, as it is from the script from before.
Config.Password		= "ThisDoesNotMatter"				-- Keep the COMPLETE Config as it is it will destroy the script, I will delete the config later, as it is from the script from before.
Config.Attempts		= 3									-- Keep the COMPLETE Config as it is it will destroy the script, I will delete the config later, as it is from the script from before.
Config.CleverMode	= false								-- Keep the COMPLETE Config as it is it will destroy the script, I will delete the config later, as it is from the script from before.
Config.DiscordLink	= "ThisDoesNotChangeAnything"		-- Keep the COMPLETE Config as it is it will destroy the script, I will delete the config later, as it is from the script from before.
Config.DeferralWait	= 0.5								-- This defines the time the user has to wait but it doesn't work out very well!
Config.Allowlist	= {}



-- Globals
local lastDeferral = {}
local attempts = {}
local passwordCard = {["type"]="AdaptiveCard",["$schema"]="http://adaptivecards.io/schemas/adaptive-card.json",["version"]="1.5",["body"]={{["type"]="Container",["items"]={{["type"]="TextBlock",["text"]="Password",["wrap"]=true},{["type"]="Input.Text",["placeholder"]="Whitelistcode eingeben",["style"]="Password",["id"]="password"},{["type"]="Container",["isVisible"]=false,["items"]={{["type"]="TextBlock",["text"]="Ungültiger Code",["wrap"]=true,["weight"]="Bolder"}}}}},{["type"]="ActionSet",["actions"]={{["type"]="Action.Submit",["title"]="Fertig"}}}}}

local steamid  = false
local license  = false
local discord  = false
local xbl      = false
local liveid   = false
local ip       = false


AddEventHandler("playerConnecting", function(name)
	for k,v in pairs(GetPlayerIdentifiers(source))do
			
		if string.sub(v, 1, string.len("license:")) == "license:" then
			license = v
			dt_coc = v:gsub('%license:', '')
		end
	end
end)



-- Main logic. Too lazy to make it more efficient and I'm certainly not going to change code that already works.
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)

	-- Locals
	local player = source
	local identifiers = GetPlayerIdentifiers(player)
	local identifiersNum = #GetPlayerIdentifiers(player)
	local allowed = false
	local newInfo = ""
	local oldInfo = ""

	-- Skip all checks if nothing is enabled (TODO: Check if this works or if deferrals.done() is required.)
	if not Config.UseAllowlist and not Config.UsePassword and not Config.CleverMode then
		return
	end

	-- Stopping user from joining
	deferrals.defer()
	lastDeferral["id" .. player] = os.clock()

	-- Updating deferral message to "Please wait..."
	while lastDeferral["id" .. player] + Config.DeferralWait > os.clock() do
		Citizen.Wait(10)
	end
	deferrals.update("Daten werden geladen...")
	lastDeferral["id" .. player] = os.clock()


	-- Password only
	if not Config.UseAllowlist and Config.UsePassword and not Config.CleverMode then
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
			
		




-- Function to show the password card
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
