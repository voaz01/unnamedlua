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
        '[+] players section with spectate/whitelist/teleport\n' ..
        '[+] enhanced whitelist protection system\n' ..
        '[+] configurable spinbot key binding\n' ..
        '[+] removed auto buy system (didn\'t work)\n' ..
        '[+] auto grab feature with orbit protection\n' ..
        '[+] auto grab (knocked players only)\n' ..
        '[+] improved grab mechanics with G key\n' ..
        '[+] custom hit sounds support\n' ..
        '[+] da hood utilities and features\n' ..
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
        local selectedWeapon = "[LMG]" -- Default weapon since auto_stomp_weapon option doesn't exist
        
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
        
        -- Auto buy weapons is always enabled since toggle doesn't exist
        if buyWeapon(selectedWeapon) then
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool.Name == selectedWeapon then
                    tool.Parent = char
                    task.wait(0.1)
                    return tool
                end
            end
        end
        
        return nil
    end
    
    local function reloadWeapon(weapon)
        if not weapon or weapon == true then return end
        
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
    
    local spinbotActive = false
    local spinbotConnection = nil
    
    local function toggleSpinbot()
        spinbotActive = not spinbotActive
        
        if spinbotActive then
            if spinbotConnection then spinbotConnection:Disconnect() end
            
            spinbotConnection = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(30), 0)
                end
            end)
            
            table.insert(framework.connections, spinbotConnection)
            api:Notify("Spinbot: ACTIVE", 1)
        else
            if spinbotConnection then
                spinbotConnection:Disconnect()
                spinbotConnection = nil
            end
            api:Notify("Spinbot: INACTIVE", 1)
        end
    end
    
    combatGroup:AddToggle("spinbot_toggle", {
        Text = "Spinbot",
        Default = false,
        Tooltip = "Toggle to enable/disable spinbot functionality"
    })
    
    combatGroup:AddKeybind("spinbot_key", {
        Text = "Spinbot Toggle Key",
        Default = "X",
        Mode = api.KeybindModes.Toggle,
        Tooltip = "Press to toggle spinbot on/off",
        Callback = function()
            if Toggles.spinbot_toggle.Value then
                toggleSpinbot()
            end
        end
    })
    
    
    if api.Keybinds then
        api.Keybinds:Register("Spinbot", "spinbot_key", "Toggle spinbot")
    end
    
    combatGroup:AddDivider("Custom Hit Sounds")
    
    
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
        
       
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "[LMG]" then
                return tool
            end
        end
        
        
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool.Name == "[LMG]" then
                tool.Parent = char
                task.wait(0.1)
                return tool
            end
        end
        
        
        if buyWeapon("[LMG]") then
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool.Name == "[LMG]" then
                    tool.Parent = char
                    task.wait(0.1)
                    return tool
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
        
        if not isPlayerKnocked(player) then
            return false
        end
        
        char.HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 1, 2), targetHRP.Position)
        task.wait(0.3)
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        task.wait(0.4)
        
        local bodyEffects = player.Character:FindFirstChild("BodyEffects")
        if bodyEffects then
            if bodyEffects:FindFirstChild("Grabbed") and bodyEffects.Grabbed.Value then
                return true
            end
            if bodyEffects:FindFirstChild("BeingCarried") and bodyEffects.BeingCarried.Value then
                return true
            end
        end
        
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
        
        
        local targetHRP = player.Character.HumanoidRootPart
        local startPos = targetHRP.Position
        local endPos = grabSafePosition.Position
        
        local distance = (endPos - startPos).Magnitude
        local steps = math.max(10, math.floor(distance / 5))
        
        for i = 1, steps do
            if not autoGrabActive or not player.Character then break end
            
            local alpha = i / steps
            local lerpedPosition = startPos:lerp(endPos, alpha)
            
            
            orbitAroundPlayer({Character = {HumanoidRootPart = {Position = lerpedPosition}}}, 4)
            
            
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local offsetPosition = lerpedPosition + Vector3.new(0, 2, 0)
                player.Character.HumanoidRootPart.CFrame = CFrame.new(offsetPosition)
            end
            
            task.wait(0.05)
        end
        
        
        if grabSafePosition then
            char.HumanoidRootPart.CFrame = grabSafePosition
        end
        
        return true
    end
    
    local function releaseGrab()
        if not isGrabbing then return end
        
        
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
        
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        task.wait(0.3)
        
        return isPlayerKnocked(target)
    end
    
    local function autoGrabLoop()
        while autoGrabActive do
            task.spawn(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                
                
                if not grabSafePosition then
                    grabSafePosition = char.HumanoidRootPart.CFrame
                end
                
                
                local knockedPlayer = findKnockedPlayer()
                if knockedPlayer and not isWhitelisted(knockedPlayer) then
                    local originalPosition = char.HumanoidRootPart.CFrame
                    
                    
                    api:Notify("Attempting to grab " .. knockedPlayer.Name, 1)
                    
                    if performGrab(knockedPlayer) then
                        isGrabbing = true
                        grabbedPlayer = knockedPlayer
                        api:Notify("Successfully grabbed " .. knockedPlayer.Name, 2)
                        
                        
                        if transportPlayer(knockedPlayer) then
                            api:Notify("Successfully transported " .. knockedPlayer.Name, 2)
                        else
                            api:Notify("Failed to transport " .. knockedPlayer.Name, 2)
                        end
                        
                        
                        task.wait(1)
                        releaseGrab()
                    else
                        api:Notify("Failed to grab " .. knockedPlayer.Name, 2)
                    end
                    
                    
                    if not isGrabbing and char:FindFirstChild("HumanoidRootPart") and originalPosition then
                        char.HumanoidRootPart.CFrame = originalPosition
                    end
                end
            end)
            
            task.wait(1) 
        end
    end
    
    combatGroup:AddToggle("auto_grab", {
        Text = "Auto Grab",
        Default = false,
        Tooltip = "Automatically grabs knocked players and transports them (no killing)",
        Callback = function(state)
            autoGrabActive = state
            
            if state then
                
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    grabSafePosition = char.HumanoidRootPart.CFrame
                end
                
                
                isGrabbing = false
                grabbedPlayer = nil
                orbitAngle = 0
                
                api:Notify("Auto Grab: ON (knocked players only)", 2)
                task.spawn(autoGrabLoop)
            else
                api:Notify("Auto Grab: OFF", 2)
                
                
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
    
    
    local originalFireServer = game.ReplicatedStorage.MainEvent.FireServer
    
    game.ReplicatedStorage.MainEvent.FireServer = function(self, action, ...)
        local args = {...}
        
        
        if action == "MOUSE" or action == "UpdateMousePos" or action == "Hit" or action == "Damage" then
            local targetPlayer = args[2]
            if targetPlayer and typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then
                if isWhitelisted(targetPlayer) then
                    api:Notify("Blocked action against whitelisted player: " .. targetPlayer.Name, 1)
                    return
                end
            end
        end
        
        return originalFireServer(self, action, ...)
    end
    
    -- Hook weapon activation to prevent hitting whitelisted players
    local function hookWeaponActivation(tool)
        if tool and tool:IsA("Tool") then
            local originalActivate = tool.Activate
            tool.Activate = function(...)
                -- Check if we're targeting a whitelisted player
                local mouse = LocalPlayer:GetMouse()
                if mouse and mouse.Target then
                    local targetCharacter = mouse.Target.Parent
                    if targetCharacter and targetCharacter:FindFirstChild("Humanoid") then
                        local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
                        if targetPlayer and isWhitelisted(targetPlayer) then
                            api:Notify("Cannot attack whitelisted player: " .. targetPlayer.Name, 1)
                            return
                        end
                    end
                end
                
                return originalActivate(...)
            end
        end
    end
    
    
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        hookWeaponActivation(tool)
    end
    
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            hookWeaponActivation(tool)
        end
    end
    
    
    table.insert(framework.connections, LocalPlayer.Backpack.ChildAdded:Connect(hookWeaponActivation))
    table.insert(framework.connections, LocalPlayer.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                hookWeaponActivation(child)
            end
        end)
    end))
    
    
    local hudTargetEnabled = true
    local targetInfo = {
        player = nil,
        health = 0,
        maxHealth = 100,
        distance = 0
    }
    
    local hudFrame = Instance.new("ScreenGui")
    hudFrame.Name = "TargetHUD"
    hudFrame.Parent = game.CoreGui
    hudFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 220, 0, 80)
    mainFrame.Position = UDim2.new(0.5, -110, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.Visible = false
    mainFrame.Parent = hudFrame
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = mainFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 50, 50)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = mainFrame
    
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Name = "TargetLabel"
    targetLabel.Size = UDim2.new(0, 200, 0, 25)
    targetLabel.Position = UDim2.new(0.5, -100, 0, 5)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "TARGET"
    targetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    targetLabel.TextSize = 16
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.Parent = mainFrame
    
    local playerName = Instance.new("TextLabel")
    playerName.Name = "PlayerName"
    playerName.Size = UDim2.new(0, 200, 0, 20)
    playerName.Position = UDim2.new(0.5, -100, 0, 25)
    playerName.BackgroundTransparency = 1
    playerName.Text = "No Target"
    playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerName.TextSize = 14
    playerName.Font = Enum.Font.Gotham
    playerName.Parent = mainFrame
    
    local healthBG = Instance.new("Frame")
    healthBG.Name = "HealthBG"
    healthBG.Size = UDim2.new(0, 200, 0, 10)
    healthBG.Position = UDim2.new(0.5, -100, 0, 50)
    healthBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBG.BorderSizePixel = 0
    healthBG.Parent = mainFrame
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBG
    
    local UICorner2 = Instance.new("UICorner")
    UICorner2.CornerRadius = UDim.new(0, 3)
    UICorner2.Parent = healthBG
    
    local UICorner3 = Instance.new("UICorner")
    UICorner3.CornerRadius = UDim.new(0, 3)
    UICorner3.Parent = healthBar
    
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(0, 200, 0, 15)
    healthText.Position = UDim2.new(0.5, -100, 0, 60)
    healthText.BackgroundTransparency = 1
    healthText.Text = "0/100 HP"
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 12
    healthText.Font = Enum.Font.Gotham
    healthText.Parent = mainFrame
    
    combatGroup:AddToggle("target_hud", {
        Text = "Target HUD",
        Default = true,
        Tooltip = "Display information about your current target",
        Callback = function(state)
            hudTargetEnabled = state
            mainFrame.Visible = false
        end
    })
    
    table.insert(framework.connections, RunService.RenderStepped:Connect(function()
        if not hudTargetEnabled then 
            mainFrame.Visible = false
            return 
        end
        
        local targetPlayer = nil
        
        if Toggles and Toggles.use_silent_aim and Toggles.use_silent_aim.Value and api.Target and api.Target.silent and api.Target.silent.player then
            targetPlayer = api.Target.silent.player
        end
        
        if not targetPlayer then
            targetPlayer = findTargetPlayer()
        end
        
        if targetPlayer and targetPlayer.Character and 
           targetPlayer.Character:FindFirstChild("Humanoid") and 
           targetPlayer.Character:FindFirstChild("HumanoidRootPart") and 
           LocalPlayer.Character and 
           LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            
            local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude
            
            targetInfo.player = targetPlayer
            targetInfo.health = humanoid.Health
            targetInfo.maxHealth = humanoid.MaxHealth
            targetInfo.distance = distance
            
            mainFrame.Visible = true
            playerName.Text = targetPlayer.Name
            healthBar.Size = UDim2.new(targetInfo.health / targetInfo.maxHealth, 0, 1, 0)
            healthText.Text = math.floor(targetInfo.health) .. "/" .. math.floor(targetInfo.maxHealth) .. " HP | " .. math.floor(distance) .. "m"
            
            local healthPercent = targetInfo.health / targetInfo.maxHealth
            if healthPercent <= 0.25 then
                healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
            elseif healthPercent <= 0.5 then
                healthBar.BackgroundColor3 = Color3.fromRGB(255, 150, 50) 
            else
                healthBar.BackgroundColor3 = Color3.fromRGB(50, 255, 50) 
            end
            
            
            if isPlayerKnocked(targetPlayer) then
                UIStroke.Color = Color3.fromRGB(255, 215, 0) 
                targetLabel.Text = "KNOCKED"
                targetLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            else
                UIStroke.Color = Color3.fromRGB(255, 50, 50) 
                targetLabel.Text = "TARGET"
                targetLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        else
            mainFrame.Visible = false
        end
    end))
end

do
    local playerGroup = skeptaTab:AddRightGroupbox("players")
    
    playerGroup:AddDivider("Player List")
    
    local playerList = {}
    local selectedPlayer = nil
    
    local function updatePlayerList()
        playerList = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(playerList, player.Name)
            end
        end
        
        if Options.player_dropdown then
            Options.player_dropdown:SetValues(playerList)
            if #playerList > 0 then
                Options.player_dropdown:SetValue(playerList[1])
            end
        end
    end
    
    playerGroup:AddDropdown("player_dropdown", {
        Text = "Select Player",
        Default = 1,
        Values = playerList,
        Tooltip = "Select a player"
    })
    
    Options.player_dropdown:OnChanged(function(value)
        selectedPlayer = value
    end)
    
    playerGroup:AddButton("Spectate Player", function()
        if selectedPlayer then
            local player = Players:FindFirstChild(selectedPlayer)
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
                api:Notify("Spectating " .. selectedPlayer, 2)
            else
                api:Notify("Player not found", 2)
            end
        else
            api:Notify("No player selected", 2)
        end
    end)
    
    playerGroup:AddButton("Whitelist Player", function()
        if selectedPlayer then
            if not whitelistedPlayers[selectedPlayer] then
                whitelistedPlayers[selectedPlayer] = true
                api:Notify("Added " .. selectedPlayer .. " to whitelist", 2)
            else
                api:Notify(selectedPlayer .. " is already whitelisted", 2)
            end
        else
            api:Notify("No player selected", 2)
        end
    end)
    
    playerGroup:AddButton("Teleport to Player", function()
        if selectedPlayer then
            local player = Players:FindFirstChild(selectedPlayer)
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                    api:Notify("Teleported to " .. selectedPlayer, 2)
                else
                    api:Notify("Your character not found", 2)
                end
            else
                api:Notify("Player not found", 2)
            end
        else
            api:Notify("No player selected", 2)
        end
    end)
    
    playerGroup:AddButton("Stop Spectating", function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = char.Humanoid
            api:Notify("Stopped spectating", 2)
        end
    end)
    
    playerGroup:AddButton("Refresh Player List", function()
        updatePlayerList()
        api:Notify("Player list refreshed", 2)
    end)
    
    
    table.insert(framework.connections, Players.PlayerAdded:Connect(function(player)
        task.wait(1) 
        updatePlayerList()
    end))
    
    table.insert(framework.connections, Players.PlayerRemoving:Connect(function(player)
        updatePlayerList()
    end))
    
    
    updatePlayerList()
    
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
    
do
    local utilGroup = skeptaTab:AddLeftGroupbox("utilities")
    
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
    
    
    auraActive = true
    task.spawn(cashAuraLoop)
    
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
