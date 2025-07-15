local api = getfenv().api or {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatService = game:GetService("Chat")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TextChatService = game:GetService("TextChatService")
local Heartbeat = RunService.Heartbeat

local framework = {
    connections = {},   
    elements = {},     
    ui = {},     
    antiSitActive = false,
    spinActive = false,
    multiToolActive = false,
    equippedTools = {},
    isHoldingKey = false
}

local skeptaTab = api:AddTab("skepta")

do
    local creditsGroup = skeptaTab:AddRightGroupbox("credits")
    
    creditsGroup:AddLabel(
        'script by: @daskepta', true
    )
end

do
    local updatesGroup = skeptaTab:AddRightGroupbox("update logs")
    
    updatesGroup:AddLabel(
        'update logs:\n' ..
        '[+] added weapons to auto buy\n' ..
        '[+] auto grab feature with orbit protection\n' ..
        '[+] auto grab (knocked players only)\n' ..
        '[+] spinbot with keybind support\n' ..
        '[+] removed auto stomp feature\n' ..
        '[+] improved grab mechanics with G key\n' ..
        '[+] custom hit sounds support\n' ..
        '[+] auto equip mask/armor buttons\n' ..
	'find any bugs? dm me. have any suggestions? @daskepta on discord', true
    )
end

local function find_first_child(obj, name)
    return obj and obj:FindFirstChild(name)
end

local function isPlayerKnocked(player)
    if not player or not player.Character then return false end
    
    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
    if not bodyEffects or not bodyEffects:FindFirstChild("K.O") then return false end
    
    return bodyEffects["K.O"].Value
end

do
    local combatGroup = skeptaTab:AddLeftGroupbox("combat")
    
    local gunShops = {
        -- Main Gun Shop
        ["[LMG]"] = CFrame.new(-577, 7.9, -716),
        ["[Rifle]"] = CFrame.new(-583, 7.9, -711),
        ["[AUG]"] = CFrame.new(-583, 7.9, -722),
        ["[Shotgun]"] = CFrame.new(-578, 7.9, -727),
        ["[SMG]"] = CFrame.new(-572, 7.9, -727),
        ["[Revolver]"] = CFrame.new(-567, 7.9, -727),
        ["[Silencer]"] = CFrame.new(-567, 7.9, -716),
        ["[Glock]"] = CFrame.new(-567, 7.9, -722),
        ["[Taser]"] = CFrame.new(-567, 7.9, -711),
        ["[TacticalShotgun]"] = CFrame.new(-572, 7.9, -711),
        ["[AR]"] = CFrame.new(-572, 7.9, -716),
        ["[AK47]"] = CFrame.new(-572, 7.9, -722),
        ["[Flamethrower]"] = CFrame.new(-578, 7.9, -711),
        ["[RPG]"] = CFrame.new(-578, 7.9, -716),
        ["[Minigun]"] = CFrame.new(-578, 7.9, -722),
        
        -- Melee Weapons
        ["[Knife]"] = CFrame.new(-628, 8, -785),
        ["[Bat]"] = CFrame.new(-625, 8, -785),
        ["[Crowbar]"] = CFrame.new(-622, 8, -785),
        ["[Hammer]"] = CFrame.new(-619, 8, -785),
        ["[Machete]"] = CFrame.new(-616, 8, -785),
        ["[Katana]"] = CFrame.new(-613, 8, -785),
        ["[Pipe]"] = CFrame.new(-610, 8, -785),
        ["[Wrench]"] = CFrame.new(-607, 8, -785),
        ["[Chainsaw]"] = CFrame.new(-604, 8, -785),
        ["[Pickaxe]"] = CFrame.new(-601, 8, -785),
        ["[Shovel]"] = CFrame.new(-598, 8, -785),
        ["[Axe]"] = CFrame.new(-595, 8, -785),
        ["[Sledgehammer]"] = CFrame.new(-592, 8, -785),
        ["[Cleaver]"] = CFrame.new(-589, 8, -785),
        ["[Spear]"] = CFrame.new(-586, 8, -785)
    }
    
    local allShops = {
        -- Ranged Weapons
        ["[LMG]"] = CFrame.new(-577, 7.9, -716),
        ["[Rifle]"] = CFrame.new(-583, 7.9, -711),
        ["[AUG]"] = CFrame.new(-583, 7.9, -722),
        ["[Shotgun]"] = CFrame.new(-578, 7.9, -727),
        ["[SMG]"] = CFrame.new(-572, 7.9, -727),
        ["[Revolver]"] = CFrame.new(-567, 7.9, -727),
        ["[Silencer]"] = CFrame.new(-567, 7.9, -716),
        ["[Glock]"] = CFrame.new(-567, 7.9, -722),
        ["[Taser]"] = CFrame.new(-567, 7.9, -711),
        ["[TacticalShotgun]"] = CFrame.new(-572, 7.9, -711),
        ["[AR]"] = CFrame.new(-572, 7.9, -716),
        ["[AK47]"] = CFrame.new(-572, 7.9, -722),
        ["[Flamethrower]"] = CFrame.new(-578, 7.9, -711),
        ["[RPG]"] = CFrame.new(-578, 7.9, -716),
        ["[Minigun]"] = CFrame.new(-578, 7.9, -722),
        
        -- Melee Weapons
        ["[Knife]"] = CFrame.new(-628, 8, -785),
        ["[Bat]"] = CFrame.new(-625, 8, -785),
        ["[Crowbar]"] = CFrame.new(-622, 8, -785),
        ["[Hammer]"] = CFrame.new(-619, 8, -785),
        ["[Machete]"] = CFrame.new(-616, 8, -785),
        ["[Katana]"] = CFrame.new(-613, 8, -785),
        ["[Pipe]"] = CFrame.new(-610, 8, -785),
        ["[Wrench]"] = CFrame.new(-607, 8, -785),
        ["[Chainsaw]"] = CFrame.new(-604, 8, -785),
        ["[Pickaxe]"] = CFrame.new(-601, 8, -785),
        ["[Shovel]"] = CFrame.new(-598, 8, -785),
        ["[Axe]"] = CFrame.new(-595, 8, -785),
        ["[Sledgehammer]"] = CFrame.new(-592, 8, -785),
        ["[Cleaver]"] = CFrame.new(-589, 8, -785),
        ["[Spear]"] = CFrame.new(-586, 8, -785),
        
        -- Food & Drinks
        ["[Chicken]"] = CFrame.new(-335, 23, -298),
        ["[Hamburger]"] = CFrame.new(-338, 23, -299),
        ["[Pizza]"] = CFrame.new(-332, 23, -300),
        ["[Cranberry]"] = CFrame.new(-340, 23, -297),
        ["[Lemonade]"] = CFrame.new(-329, 23, -296),
        ["[Donut]"] = CFrame.new(-334, 23, -304),
        ["[Sandwich]"] = CFrame.new(-331, 23, -302),
        ["[Chips]"] = CFrame.new(-337, 23, -301),
        ["[Soda]"] = CFrame.new(-333, 23, -298),
        ["[Coffee]"] = CFrame.new(-336, 23, -295),
        
        -- Masks & Accessories
        ["[Mask]"] = CFrame.new(-324, 22, -85),
        ["[Ski Mask]"] = CFrame.new(-324, 22, -85),
        ["[Durag]"] = CFrame.new(-204, 22, -89),
        ["[Bandana]"] = CFrame.new(-198, 22, -89),
        ["[Letterman]"] = CFrame.new(-200, 22, -85),
        ["[Hoodie]"] = CFrame.new(-202, 22, -87),
        ["[Cap]"] = CFrame.new(-196, 22, -87),
        ["[Beanie]"] = CFrame.new(-194, 22, -85),
        
        ["[Medkit]"] = CFrame.new(-630, 8, -780)
    }
    
    local whitelistedPlayers = {}
    
    local function isWhitelisted(player)
        if not player then return false end
        return whitelistedPlayers[player.Name] or whitelistedPlayers[player.DisplayName] or false
    end
    
    local function findKnockedPlayer()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and 
               player.Character and 
               player.Character:FindFirstChild("HumanoidRootPart") and
               not isWhitelisted(player) and 
               isPlayerKnocked(player) then
                return player
            end
        end
        return nil
    end
    
    local function findTargetPlayer()
        if Toggles and Toggles.use_silent_aim and Toggles.use_silent_aim.Value and api.Target and api.Target.silent and api.Target.silent.player then
            local target = api.Target.silent.player
            if target ~= LocalPlayer and 
               target.Character and 
               target.Character:FindFirstChild("HumanoidRootPart") and
               not isWhitelisted(target) and
               not isPlayerKnocked(target) then
                return target
            end
        end
        
        local closestPlayer = nil
        local closestDistance = math.huge
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and 
               player.Character and 
               player.Character:FindFirstChild("HumanoidRootPart") and
               player.Character:FindFirstChildOfClass("Humanoid") and
               player.Character:FindFirstChildOfClass("Humanoid").Health > 0 and
               not isWhitelisted(player) and
               not isPlayerKnocked(player) then
                
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
        
        return closestPlayer
    end
    
    local function buyWeapon(weaponName)
        if not weaponName or not gunShops[weaponName] then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local originalPosition = char.HumanoidRootPart.CFrame
        
        char.HumanoidRootPart.CFrame = gunShops[weaponName]
        task.wait(0.5)
        
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("Part") and part.Name == "BuyButton" and part:FindFirstChild("SurfaceGui") then
                local surfaceGui = part:FindFirstChild("SurfaceGui")
                if surfaceGui and surfaceGui:FindFirstChild("TextLabel") then
                    local textLabel = surfaceGui:FindFirstChild("TextLabel")
                    if textLabel and string.find(textLabel.Text, weaponName) then
                        char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 0, -3)
                        task.wait(0.2)
                        
                        if part:FindFirstChild("ClickDetector") then
                            fireclickdetector(part.ClickDetector)
                            task.wait(0.5)
                        end
                        break
                    end
                end
            end
        end
        
        char.HumanoidRootPart.CFrame = originalPosition
        
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool.Name == weaponName then
                return true
            end
        end
        
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == weaponName then
                return true
            end
        end
        
        return false
    end
    
    local function buyItem(itemName)
        if not itemName or not allShops[itemName] then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local originalPosition = char.HumanoidRootPart.CFrame
        
        char.HumanoidRootPart.CFrame = allShops[itemName]
        task.wait(0.5)
        
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("Part") and part.Name == "BuyButton" and part:FindFirstChild("SurfaceGui") then
                local surfaceGui = part:FindFirstChild("SurfaceGui")
                if surfaceGui and surfaceGui:FindFirstChild("TextLabel") then
                    local textLabel = surfaceGui:FindFirstChild("TextLabel")
                    if textLabel and string.find(textLabel.Text, itemName) then
                        char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 0, -3)
                        task.wait(0.2)
                        
                        if part:FindFirstChild("ClickDetector") then
                            fireclickdetector(part.ClickDetector)
                            task.wait(0.5)
                        end
                        break
                    end
                end
            end
        end
        
        char.HumanoidRootPart.CFrame = originalPosition
        
        -- Check if item was purchased
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool.Name == itemName then
                return true
            end
        end
        
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == itemName then
                return true
            end
        end
        
        -- Check player's character for wearable items
        for _, accessory in pairs(char:GetChildren()) do
            if accessory:IsA("Accessory") and string.find(accessory.Name, itemName) then
                return true
            end
        end
        
        return false
    end
    
    local function getWeapon()
        local selectedWeapon = Options.auto_stomp_weapon.Value
        
        if selectedWeapon == "Ragebot Only" then
            return true
        end
        
        local char = LocalPlayer.Character
        if not char then return nil end
        
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == selectedWeapon then
                return tool
            end
        end
        
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool.Name == selectedWeapon then
                tool.Parent = char
                task.wait(0.1)
                return tool
            end
        end
        
        local fallbackWeapons = {"[LMG]", "[Rifle]", "[AUG]", "[Shotgun]", "[SMG]", "[AR]", "[AK47]", "[Glock]", "[Revolver]"}
        for _, weaponName in ipairs(fallbackWeapons) do
            if weaponName ~= selectedWeapon then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == weaponName then
                        return tool
                    end
                end
                
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool.Name == weaponName then
                        tool.Parent = char
                        task.wait(0.1)
                        return tool
                    end
                end
            end
        end
        
        if Toggles.auto_buy_toggle and Toggles.auto_buy_toggle.Value then
            if buyWeapon(selectedWeapon) then
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool.Name == selectedWeapon then
                        tool.Parent = char
                        task.wait(0.1)
                        return tool
                    end
                end
            end
        end
        
        return nil
    end
    
    local function reloadWeapon(weapon)
        if not weapon or not Toggles.auto_reload or not Toggles.auto_reload.Value or weapon == true then return end
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        task.wait(0.2)
    end
    
    local silentBlockToggle = combatGroup:AddToggle("god_block", {
        Text = "god block",
        Default = true,
    })
    
    table.insert(framework.connections, RunService.Heartbeat:Connect(function()
        if silentBlockToggle.Value then
            local char = LocalPlayer.Character
            if not char then return end

            game.ReplicatedStorage.MainEvent:FireServer("Block", true)

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, anim in ipairs(hum:GetPlayingAnimationTracks()) do
                    if anim.Animation.AnimationId:match("2788354405") then 
                        anim:Stop()
                    end
                end
            end

            local effects = char:FindFirstChild("BodyEffects")
            if effects and effects:FindFirstChild("Block") then
                effects.Block:Destroy()
            end
        end
    end))
    
    combatGroup:AddToggle("spinbot_toggle", {
        Text = "Spinbot",
        Default = false,
        Tooltip = "Rapidly spin your character to dodge bullets (Hold X key)"
    })
    
    combatGroup:AddLabel("Hold X key to activate spinbot", true)
    
    local spinbotConnection = nil
    local spinbotKeyHeld = false
    
    table.insert(framework.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.X and Toggles.spinbot_toggle.Value then
            spinbotKeyHeld = true
            if spinbotConnection then spinbotConnection:Disconnect() end
            
            spinbotConnection = RunService.Heartbeat:Connect(function()
                if not spinbotKeyHeld then 
                    spinbotConnection:Disconnect()
                    return 
                end
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(30), 0)
                end
            end)
            
            table.insert(framework.connections, spinbotConnection)
            api:Notify("Spinbot: ACTIVE", 1)
        end
    end))
    
    table.insert(framework.connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.X then
            spinbotKeyHeld = false
            if spinbotConnection then
                spinbotConnection:Disconnect()
                spinbotConnection = nil
            end
            if Toggles.spinbot_toggle.Value then
                api:Notify("Spinbot: INACTIVE", 1)
            end
        end
    end))
    
    combatGroup:AddDivider("Auto Buy System")
    
    local autoBuyCategories = {
        ["Ranged Weapons"] = {"[LMG]", "[Rifle]", "[AUG]", "[Shotgun]", "[TacticalShotgun]", "[SMG]", "[Revolver]", "[Silencer]", "[Glock]", "[Taser]", "[AR]", "[AK47]", "[Flamethrower]", "[RPG]", "[Minigun]"},
        ["Melee Weapons"] = {"[Knife]", "[Bat]", "[Crowbar]", "[Hammer]", "[Machete]", "[Katana]", "[Pipe]", "[Wrench]", "[Chainsaw]", "[Pickaxe]", "[Shovel]", "[Axe]", "[Sledgehammer]", "[Cleaver]", "[Spear]"},
        ["Food & Drinks"] = {"[Chicken]", "[Hamburger]", "[Pizza]", "[Cranberry]", "[Lemonade]", "[Donut]", "[Sandwich]", "[Chips]", "[Soda]", "[Coffee]"},
        ["Masks & Accessories"] = {"[Mask]", "[Ski Mask]", "[Durag]", "[Bandana]", "[Letterman]", "[Hoodie]", "[Cap]", "[Beanie]"},
        ["Drugs"] = {"[Lean]", "[Adderall]", "[Cocaine]", "[Mushrooms]", "[Weed]", "[Xanax]", "[Heroin]", "[Molly]"},
        ["Equipment"] = {"[Armor]", "[Phone]", "[LockPick]", "[SprayPaint]", "[Handcuffs]", "[Flashlight]", "[Binoculars]", "[Medkit]"}
    }
    
    combatGroup:AddDropdown("auto_buy_category", {
        Text = "Item Category",
        Default = 1,
        Values = {"Ranged Weapons", "Melee Weapons", "Food & Drinks", "Masks & Accessories", "Drugs", "Equipment"},
        Tooltip = "Select category of items to auto buy"
    })
    
    combatGroup:AddDropdown("auto_buy_item", {
        Text = "Item Selection",
        Default = 1,
        Values = autoBuyCategories["Ranged Weapons"],
        Tooltip = "Select specific item to auto buy"
    })
    
    Options.auto_buy_category:OnChanged(function(value)
        local items = autoBuyCategories[value] or {}
        Options.auto_buy_item:SetValues(items)
        Options.auto_buy_item:SetValue(items[1] or "")
    end)
    
    combatGroup:AddButton("Buy Selected Item", function()
        local selectedItem = Options.auto_buy_item.Value
        if selectedItem and selectedItem ~= "" then
            api:Notify("Attempting to buy " .. selectedItem, 1)
            if buyItem(selectedItem) then
                api:Notify("Successfully bought " .. selectedItem, 2)
            else
                api:Notify("Failed to buy " .. selectedItem, 2)
            end
        else
            api:Notify("No item selected", 2)
        end
    end)
    
    combatGroup:AddButton("Buy All Category Items", function()
        local category = Options.auto_buy_category.Value
        local items = autoBuyCategories[category] or {}
        
        api:Notify("Buying all " .. category .. " items...", 2)
        
        task.spawn(function()
            for _, item in pairs(items) do
                api:Notify("Buying " .. item, 1)
                if buyItem(item) then
                    api:Notify("✓ " .. item, 1)
                else
                    api:Notify("✗ " .. item, 1)
                end
                task.wait(1)
            end
            api:Notify("Finished buying " .. category .. " items", 2)
        end)
    end)
    
    combatGroup:AddButton("Buy All Weapons", function()
        api:Notify("Buying all weapons...", 2)
        
        task.spawn(function()
            local allWeapons = {}
            for _, weapon in pairs(autoBuyCategories["Ranged Weapons"]) do
                table.insert(allWeapons, weapon)
            end
            for _, weapon in pairs(autoBuyCategories["Melee Weapons"]) do
                table.insert(allWeapons, weapon)
            end
            
            for _, weapon in pairs(allWeapons) do
                api:Notify("Buying " .. weapon, 1)
                if buyItem(weapon) then
                    api:Notify("✓ " .. weapon, 1)
                else
                    api:Notify("✗ " .. weapon, 1)
                end
                task.wait(0.8)
            end
            api:Notify("Finished buying all weapons", 2)
        end)
    end)
    
    combatGroup:AddDivider("Custom Hit Sounds")
    
    -- Register custom hit sounds using the API
    if api.Sounds then
        api.Sounds:Register("headshot", "rbxassetid://131961136")
        api.Sounds:Register("hitmarker", "rbxassetid://160432334")
        api.Sounds:Register("bell", "rbxassetid://131961136")
        api.Sounds:Register("minecraft", "rbxassetid://4018633470")
        api.Sounds:Register("osu", "rbxassetid://7147454322")
        api.Sounds:Register("cod", "rbxassetid://160432334")
        api.Sounds:Register("rust", "rbxassetid://1255040462")
        api.Sounds:Register("bubble", "rbxassetid://198598793")
    end
    
    combatGroup:AddLabel("Custom hit sounds registered to visuals tab", true)
    
    combatGroup:AddDivider("Auto Grab")
    
    local autoGrabActive = false
    local autoGrabConnection = nil
    local grabSafePosition = nil
    local orbitAngle = 0
    local grabbedPlayer = nil
    local isGrabbing = false
    
    local function getLMGWeapon()
        local char = LocalPlayer.Character
        if not char then return nil end
        
        -- Check if already equipped
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "[LMG]" then
                return tool
            end
        end
        
        -- Check backpack
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool.Name == "[LMG]" then
                tool.Parent = char
                task.wait(0.1)
                return tool
            end
        end
        
        -- Auto buy if enabled
        if Toggles.auto_buy_toggle and Toggles.auto_buy_toggle.Value then
            if buyWeapon("[LMG]") then
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool.Name == "[LMG]" then
                        tool.Parent = char
                        task.wait(0.1)
                        return tool
                    end
                end
            end
        end
        
        return nil
    end
    
    local function orbitAroundPlayer(player, radius)
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local targetHRP = player.Character.HumanoidRootPart
        orbitAngle = orbitAngle + math.rad(15) -- Increase orbit speed
        
        local orbitX = math.cos(orbitAngle) * radius
        local orbitZ = math.sin(orbitAngle) * radius
        
        local orbitPosition = targetHRP.Position + Vector3.new(orbitX, 2, orbitZ)
        char.HumanoidRootPart.CFrame = CFrame.new(orbitPosition, targetHRP.Position)
    end
    
    local function performGrab(player)
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local targetHRP = player.Character.HumanoidRootPart
        
        -- Must be knocked first
        if not isPlayerKnocked(player) then
            return false
        end
        
        -- Get right next to the knocked player
        char.HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 1, 2), targetHRP.Position)
        task.wait(0.3)
        
        -- Use G key to grab (proper Da Hood method)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        task.wait(0.4)
        
        -- Check if grab was successful
        local bodyEffects = player.Character:FindFirstChild("BodyEffects")
        if bodyEffects then
            -- Check for grabbed state
            if bodyEffects:FindFirstChild("Grabbed") and bodyEffects.Grabbed.Value then
                return true
            end
            -- Check if player is being carried
            if bodyEffects:FindFirstChild("BeingCarried") and bodyEffects.BeingCarried.Value then
                return true
            end
        end
        
        -- Check if player is connected to us (another way to detect grab)
        local attachment = player.Character:FindFirstChild("GRABBING_CONSTRAINT")
        if attachment then
            return true
        end
        
        return false
    end
    
    local function transportPlayer(player)
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        if not grabSafePosition then
            grabSafePosition = char.HumanoidRootPart.CFrame
        end
        
        -- Transport while orbiting to avoid getting hit
        local targetHRP = player.Character.HumanoidRootPart
        local startPos = targetHRP.Position
        local endPos = grabSafePosition.Position
        
        local distance = (endPos - startPos).Magnitude
        local steps = math.max(10, math.floor(distance / 5))
        
        for i = 1, steps do
            if not autoGrabActive or not player.Character then break end
            
            local alpha = i / steps
            local lerpedPosition = startPos:lerp(endPos, alpha)
            
            -- Orbit around the lerped position while transporting
            orbitAroundPlayer({Character = {HumanoidRootPart = {Position = lerpedPosition}}}, 4)
            
            -- Move the grabbed player with us
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local offsetPosition = lerpedPosition + Vector3.new(0, 2, 0)
                player.Character.HumanoidRootPart.CFrame = CFrame.new(offsetPosition)
            end
            
            task.wait(0.05)
        end
        
        -- Final positioning
        if grabSafePosition then
            char.HumanoidRootPart.CFrame = grabSafePosition
        end
        
        return true
    end
    
    local function releaseGrab()
        if not isGrabbing then return end
        
        -- Use G key to release (proper Da Hood method)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        
        isGrabbing = false
        grabbedPlayer = nil
        orbitAngle = 0
    end
    
    local function killWithLMG(target)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local lmg = getLMGWeapon()
        if not lmg then return false end
        
        local targetHRP = target.Character.HumanoidRootPart
        local targetPos = targetHRP.Position
        
        -- Orbit around target while shooting
        local shootTime = 0
        local maxShootTime = 3
        
        while shootTime < maxShootTime and not isPlayerKnocked(target) and autoGrabActive do
            orbitAroundPlayer(target, 8)
            
            -- Shoot at target
            for i = 1, 3 do
                if isPlayerKnocked(target) then break end
                lmg:Activate()
                task.wait(0.05)
            end
            
            shootTime = shootTime + 0.2
            task.wait(0.1)
        end
        
        -- Reload if needed
        if Toggles.auto_reload and Toggles.auto_reload.Value then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
            task.wait(0.3)
        end
        
        return isPlayerKnocked(target)
    end
    
    local function autoGrabLoop()
        while autoGrabActive do
            task.spawn(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                
                -- Set safe position if not set
                if not grabSafePosition then
                    grabSafePosition = char.HumanoidRootPart.CFrame
                end
                
                -- Find knocked player only (no killing)
                local knockedPlayer = findKnockedPlayer()
                if knockedPlayer and not isWhitelisted(knockedPlayer) then
                    local originalPosition = char.HumanoidRootPart.CFrame
                    
                    -- Only grab already knocked players
                    api:Notify("Attempting to grab " .. knockedPlayer.Name, 1)
                    
                    if performGrab(knockedPlayer) then
                        isGrabbing = true
                        grabbedPlayer = knockedPlayer
                        api:Notify("Successfully grabbed " .. knockedPlayer.Name, 2)
                        
                        -- Transport player to safe position
                        if transportPlayer(knockedPlayer) then
                            api:Notify("Successfully transported " .. knockedPlayer.Name, 2)
                        else
                            api:Notify("Failed to transport " .. knockedPlayer.Name, 2)
                        end
                        
                        -- Release grab after transport
                        task.wait(1)
                        releaseGrab()
                    else
                        api:Notify("Failed to grab " .. knockedPlayer.Name, 2)
                    end
                    
                    -- Return to original position if not grabbing
                    if not isGrabbing and char:FindFirstChild("HumanoidRootPart") and originalPosition then
                        char.HumanoidRootPart.CFrame = originalPosition
                    end
                end
            end)
            
            task.wait(1) -- Delay between grab attempts
        end
    end
    
    combatGroup:AddToggle("auto_grab", {
        Text = "Auto Grab",
        Default = false,
        Tooltip = "Automatically grabs knocked players and transports them (no killing)",
        Callback = function(state)
            autoGrabActive = state
            
            if state then
                -- Set safe position to current position
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    grabSafePosition = char.HumanoidRootPart.CFrame
                end
                
                -- Reset grab state
                isGrabbing = false
                grabbedPlayer = nil
                orbitAngle = 0
                
                api:Notify("Auto Grab: ON (knocked players only)", 2)
                task.spawn(autoGrabLoop)
            else
                api:Notify("Auto Grab: OFF", 2)
                
                -- Release any active grab
                if isGrabbing then
                    releaseGrab()
                end
                
                grabSafePosition = nil
            end
        end
    })
    
    combatGroup:AddButton("Set Grab Position", function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            grabSafePosition = char.HumanoidRootPart.CFrame
            api:Notify("Grab position set to current location", 2)
        end
    end)
    
    combatGroup:AddButton("Release Grab", function()
        if isGrabbing then
            releaseGrab()
            api:Notify("Released grab", 2)
        else
            api:Notify("Not currently grabbing anyone", 2)
        end
    end)
    
    combatGroup:AddButton("Test Grab (Closest Knocked)", function()
        local knockedPlayer = findKnockedPlayer()
        if knockedPlayer then
            api:Notify("Testing grab on " .. knockedPlayer.Name, 2)
            if performGrab(knockedPlayer) then
                api:Notify("Test grab successful!", 2)
                isGrabbing = true
                grabbedPlayer = knockedPlayer
                
                -- Auto-release after 3 seconds
                task.wait(3)
                releaseGrab()
                api:Notify("Auto-released test grab", 2)
            else
                api:Notify("Test grab failed", 2)
            end
        else
            api:Notify("No knocked players found nearby", 2)
        end
    end)
    
    -- ...existing code...
end

do
    local playerGroup = skeptaTab:AddRightGroupbox("player management")
    
    playerGroup:AddDivider("Whitelist Management")
    
    playerGroup:AddInput("whitelist_input", {
        Text = "Player Name",
        Default = "",
        Placeholder = "Enter username to whitelist",
        Finished = true
    })
    
    playerGroup:AddButton("Add to Whitelist", function()
        local playerName = Options.whitelist_input.Value
        if playerName ~= "" and not whitelistedPlayers[playerName] then
            whitelistedPlayers[playerName] = true
            api:Notify("Added " .. playerName .. " to whitelist", 2)
        end
    end)
    
    playerGroup:AddButton("Remove from Whitelist", function()
        local playerName = Options.whitelist_input.Value
        if playerName ~= "" and whitelistedPlayers[playerName] then
            whitelistedPlayers[playerName] = nil
            api:Notify("Removed " .. playerName .. " from whitelist", 2)
        end
    end)
    
    playerGroup:AddButton("Clear Whitelist", function()
        whitelistedPlayers = {}
        api:Notify("Whitelist cleared", 2)
    end)
    
    playerGroup:AddDivider("Player Interaction")
    
    local words = {
        "where are you aiming at?",
        "sonned",
        "bad",
        "even my grandma has faster reactions",
        ":clown:",
        "gg = get good",
        "im just better",
        "my gaming chair is just better",
        "clip me",
        "skill",
        ":Skull:",
        "go play adopt me",
        "go play brookhaven",
        "omg you are so good :screm:",
        "awesome",
        "fridge",
        "do not bully pliisss :sobv:",
        "it was your lag ofc",
        "fly high",
        "*cough* *cough*",
        "son",
        "already mad?",
        "please don't report :sobv:",
        "sob harder",
        "UE on top",
        "alt + f4 for better aim",
        "Get sonned",
        "Where are you aiming? 💀",
        "You just got outplayed...",
        "Omg you're so good... said no one ever",
        "You built like Gru, but with zero braincells 💀",
        "Fly high but your aim is still low 😹",
        "Bet you've never heard of UE",
        "UE is best, sorry but its facts",
        "UE > your skills 😭",
        "UE always wins",
        "UE doesn't miss, unlike you 💀",
        "UE made me get ekittens"
    }
    
    local enabled = false
    
    playerGroup:AddToggle("autotrash_e", { 
        Text = "Trash Talk (E key)", 
        Default = false 
    }):OnChanged(function(v)
        enabled = v
    end)
    
    local function SendChatMessage(message)
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.TextChannels.RBXGeneral:SendAsync(message)
        else
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
        end
    end
    
    table.insert(framework.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not enabled then return end
        if input.KeyCode == Enum.KeyCode.E then
            local msg = words[math.random(1, #words)]
            SendChatMessage(msg)
            api:Notify("Trash: " .. msg, 1.5)
        end
    end))
end

do
    local utilGroup = skeptaTab:AddLeftGroupbox("utilities")
    
    utilGroup:AddDivider("Da Hood Utilities")
    
    -- Auto Drug Dealer
    local autoDrugDealerActive = false
    
    local function autoDrugDealerLoop()
        while autoDrugDealerActive do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Look for drug dealer NPCs
                for _, npc in pairs(workspace:GetChildren()) do
                    if npc:IsA("Model") and npc.Name == "DrugDealer" then
                        local npcHrp = npc:FindFirstChild("HumanoidRootPart")
                        if npcHrp then
                            local distance = (char.HumanoidRootPart.Position - npcHrp.Position).Magnitude
                            if distance <= 20 then
                                char.HumanoidRootPart.CFrame = npcHrp.CFrame * CFrame.new(0, 0, -3)
                                task.wait(0.5)
                                
                                -- Look for interaction button
                                for _, part in pairs(npc:GetChildren()) do
                                    if part:IsA("Part") and part:FindFirstChild("ClickDetector") then
                                        fireclickdetector(part.ClickDetector)
                                        task.wait(1)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(2)
        end
    end
    
    utilGroup:AddToggle("auto_drug_dealer", {
        Text = "Auto Drug Dealer",
        Default = false,
        Tooltip = "Automatically interact with drug dealers",
        Callback = function(state)
            autoDrugDealerActive = state
            if state then
                task.spawn(autoDrugDealerLoop)
                api:Notify("Auto Drug Dealer: ON", 2)
            else
                api:Notify("Auto Drug Dealer: OFF", 2)
            end
        end
    })
    
    -- Auto Lockpick
    local autoLockpickActive = false
    
    local function autoLockpickLoop()
        while autoLockpickActive do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Look for lockpickable doors/ATMs
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Part") and (obj.Name == "ATM" or obj.Name == "Door") then
                        local distance = (char.HumanoidRootPart.Position - obj.Position).Magnitude
                        if distance <= 15 then
                            -- Check if we have lockpick
                            local lockpick = char:FindFirstChild("[LockPick]") or LocalPlayer.Backpack:FindFirstChild("[LockPick]")
                            if lockpick then
                                if lockpick.Parent == LocalPlayer.Backpack then
                                    lockpick.Parent = char
                                    task.wait(0.1)
                                end
                                
                                char.HumanoidRootPart.CFrame = obj.CFrame * CFrame.new(0, 0, -3)
                                task.wait(0.5)
                                
                                if lockpick:FindFirstChild("RemoteEvent") then
                                    lockpick.RemoteEvent:FireServer()
                                end
                            end
                        end
                    end
                end
            end
            task.wait(3)
        end
    end
    
    utilGroup:AddToggle("auto_lockpick", {
        Text = "Auto Lockpick",
        Default = false,
        Tooltip = "Automatically lockpick doors and ATMs",
        Callback = function(state)
            autoLockpickActive = state
            if state then
                task.spawn(autoLockpickLoop)
                api:Notify("Auto Lockpick: ON", 2)
            else
                api:Notify("Auto Lockpick: OFF", 2)
            end
        end
    })
    
    -- Auto Mask
    utilGroup:AddButton("Auto Equip Mask", function()
        local char = LocalPlayer.Character
        if char then
            local mask = char:FindFirstChild("[Mask]") or LocalPlayer.Backpack:FindFirstChild("[Mask]")
            if mask then
                if mask.Parent == LocalPlayer.Backpack then
                    mask.Parent = char
                    api:Notify("Equipped mask", 2)
                else
                    api:Notify("Mask already equipped", 2)
                end
            else
                api:Notify("No mask found", 2)
            end
        end
    end)
    
    -- Auto Armor
    utilGroup:AddButton("Auto Equip Armor", function()
        local char = LocalPlayer.Character
        if char then
            local armor = char:FindFirstChild("[Armor]") or LocalPlayer.Backpack:FindFirstChild("[Armor]")
            if armor then
                if armor.Parent == LocalPlayer.Backpack then
                    armor.Parent = char
                    api:Notify("Equipped armor", 2)
                else
                    api:Notify("Armor already equipped", 2)
                end
            else
                api:Notify("No armor found", 2)
            end
        end
    end)
    
    utilGroup:AddDivider("Standard Utilities")
    
    local auraActive = false
    
    local function cashAuraLoop()
        while auraActive do
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")

            local dropFolder = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop")
            if dropFolder then
                for _, moneyDrop in pairs(dropFolder:GetChildren()) do
                    if moneyDrop:IsA("Part") and moneyDrop.Name == "MoneyDrop" then
                        local distance = (hrp.Position - moneyDrop.Position).Magnitude
                        if distance <= 10 then
                            local clickDetector = moneyDrop:FindFirstChildOfClass("ClickDetector")
                            if clickDetector then
                                fireclickdetector(clickDetector)
                            end
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end
    
    utilGroup:AddToggle("cash_aura_toggle", {
        Text = "Cash Aura",
        Default = true,
        Callback = function(state)
            auraActive = state
            if state then
                task.spawn(cashAuraLoop)
            end
        end
    })
    
    if Toggles.cash_aura_toggle and Toggles.cash_aura_toggle.Value then
        auraActive = true
        task.spawn(cashAuraLoop)
    end
    
    local afkConnection
    
    utilGroup:AddToggle("anti_afk", {
        Text = "Anti AFK",
        Default = true,
        Callback = function(state)
            if state then
                afkConnection = LocalPlayer.Idled:Connect(function()
                    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
            else
                if afkConnection then
                    afkConnection:Disconnect()
                    afkConnection = nil
                end
            end
        end
    })
    
    local jerkTool = nil
    local respawnConnection = nil
    
    local function createTool()
        local plr = game:GetService("Players").LocalPlayer
        local pack = plr:WaitForChild("Backpack")

        if jerkTool and jerkTool.Parent == pack then
            return 
        end

        if jerkTool then
            jerkTool:Destroy()
        end

        local existing = workspace:FindFirstChild("aaa")
        if existing then existing:Destroy() end

        local animation = Instance.new("Animation")
        animation.Name = "aaa"
        animation.Parent = workspace
        animation.AnimationId = (plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15)
            and "rbxassetid://698251653" or "rbxassetid://72042024"

        jerkTool = Instance.new("Tool")
        jerkTool.Name = "Jerk"
        jerkTool.RequiresHandle = false
        jerkTool.Parent = pack

        local doing, animTrack = false, nil

        jerkTool.Equipped:Connect(function()
            doing = true
            while doing do
                if not animTrack then
                    local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
                    local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator"))
                    if not animator then break end
                    animTrack = animator:LoadAnimation(animation)
                end
                animTrack:Play()
                animTrack:AdjustSpeed(0.7)
                animTrack.TimePosition = 0.6
                task.wait(0.1)
                while doing and animTrack and animTrack.TimePosition < 0.7 do task.wait(0.05) end
                if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
            end
        end)

        local function stopAnim()
            doing = false
            if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
        end

        jerkTool.Unequipped:Connect(stopAnim)
        local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
        if hum then hum.Died:Connect(stopAnim) end

        respawnConnection = plr.CharacterAdded:Connect(function(char)
            local ff = char:FindFirstChildOfClass("ForceField")
            if ff then ff.AncestryChanged:Wait() end
            removeTool()
            createTool()
        end)
    end

    local function removeTool()
        if jerkTool then
            jerkTool:Destroy()
            jerkTool = nil
        end
        local existing = workspace:FindFirstChild("aaa")
        if existing then existing:Destroy() end
        if respawnConnection then
            respawnConnection:Disconnect()
            respawnConnection = nil
        end
    end
    
    utilGroup:AddToggle("jerk_toggle", {
        Text = "Jerk Tool",
        Default = false,
        Callback = function(state)
            if state then createTool() else removeTool() end
        end
    })
    
    utilGroup:AddToggle("anti_fling", {
        Text = "Anti Fling",
        Default = false,
    })
    
    local originalCollisions = {}

    table.insert(framework.connections, RunService.Heartbeat:Connect(function()
        local toggle = Toggles.anti_fling
        if not toggle or not toggle.Value then
            for player, parts in pairs(originalCollisions) do
                if player and player.Character then
                    for part, properties in pairs(parts) do
                        if part and part:IsA("BasePart") then
                            part.CanCollide = properties.CanCollide
                            if part.Name == "Torso" then
                                part.Massless = properties.Massless
                            end
                        end
                    end
                end
            end
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or not player.Character then continue end

            pcall(function()
                local parts = {}
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        parts[part] = {
                            CanCollide = part.CanCollide,
                            Massless = part.Name == "Torso" and part.Massless or false
                        }
                        part.CanCollide = false
                        if part.Name == "Torso" then
                            part.Massless = true
                        end
                        if toggle.Value then
                            part.Velocity = Vector3.zero
                            part.RotVelocity = Vector3.zero
                        end
                    end
                end
                originalCollisions[player] = parts
            end)
        end
    end))
    
    local joinConn, leaveConn = nil, nil
    
    utilGroup:AddToggle("logs_toggle", {
        Text = "Activity Logs",
        Default = false,
        Tooltip = "Show player join/leave notifications",
        Callback = function(enabled)
            if enabled then
                utilGroup:AddInput("notify_text", {
                    Text = "Notification Text",
                    Default = "{NAME} has {ACTIVITY} the game.",
                    Placeholder = "ex: {NAME}, {ACTIVITY}",
                    Finished = true
                })
                utilGroup:AddSlider("notify_duration", {
                    Text = "Notify Duration",
                    Default = 3,
                    Min = 0.5,
                    Max = 10,
                    Rounding = 1,
                    Suffix = "s"
                })
                joinConn = Players.PlayerAdded:Connect(function(p)
                    api:Notify(Options.notify_text.Value:gsub("{NAME}", p.Name):gsub("{ACTIVITY}", "joined"), Options.notify_duration.Value)
                end)
                leaveConn = Players.PlayerRemoving:Connect(function(p)
                    api:Notify(Options.notify_text.Value:gsub("{NAME}", p.Name):gsub("{ACTIVITY}", "left"), Options.notify_duration.Value)
                end)
                table.insert(framework.connections, joinConn)
                table.insert(framework.connections, leaveConn)
            else
                if joinConn then joinConn:Disconnect() end
                if leaveConn then leaveConn:Disconnect() end
            end
        end
    })
end

do
    local serverGroup = skeptaTab:AddRightGroupbox("server")
    
    serverGroup:AddButton("Voice Chat Unban", function()
        local success, err = pcall(function()
            game:GetService("VoiceChatService"):joinVoice()
        end)
        api:Notify(success and "Reconnected to voice chat" or ("Voice chat failed: " .. tostring(err)), 2)
    end)
    
    serverGroup:AddButton("Rejoin Server", function()
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        api:Notify(success and "Rejoining server" or ("Failed: " .. tostring(err)), 2)
    end)
    
    serverGroup:AddButton("Copy Join Script", function()
        local placeId = game.PlaceId  
        local serverId = game.JobId  
        
        local joinScript = string.format("cloneref(game:GetService('TeleportService')):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)", placeId, serverId)
        
        setclipboard(joinScript)
        
        api:Notify("Copied server join script", 3)
    end)
end

function api.Unload()
    for _, connection in pairs(framework.connections) do
        connection:Disconnect()
    end
    
    if spinbotConnection then
        spinbotConnection:Disconnect()
    end
    
    table.clear(framework.connections)
    table.clear(framework.elements)
    table.clear(framework.ui)
end
