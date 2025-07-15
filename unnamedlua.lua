
local api = getfenv().api or {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

local Framework = {
    connections = {},
    threads = {},
    activeFeatures = {},
    whitelistedPlayers = {},
    lastPositions = {},
    orbitAngles = {}
}

local mainTab = api:AddTab("skepta v2")

do
    local creditsGroup = mainTab:AddRightGroupbox("credits")
    creditsGroup:AddLabel('script by: @daskepta\nv2.0 - completely recoded', true)
end

do
    local updatesGroup = mainTab:AddRightGroupbox("update logs")
    updatesGroup:AddLabel(
        'v2.0 update logs:\n' ..
        '[+] completely recoded entire script\n' ..
        '[+] fixed auto grab with proper G key mechanics\n' ..
        '[+] improved auto stomp positioning\n' ..
        '[+] orbit added\n' ..
        '[+] better weapon management\n' ..
        '[+] optimized performance\n' ..
        '[+] improved error handling\n' ..
        '[+] cleaner code structure\n' ..
        'find bugs? suggestions? dm @daskepta on discord', true
    )
end

local Utils = {}

function Utils.isPlayerValid(player)
    return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid")
end

function Utils.isPlayerKnocked(player)
    if not Utils.isPlayerValid(player) then return false end
    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
    if not bodyEffects then return false end
    local ko = bodyEffects:FindFirstChild("K.O")
    return ko and ko.Value == true
end

function Utils.isPlayerGrabbed(player)
    if not Utils.isPlayerValid(player) then return false end
    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
    if not bodyEffects then return false end
    local grabbed = bodyEffects:FindFirstChild("Grabbed")
    return grabbed and grabbed.Value == true
end

function Utils.isWhitelisted(player)
    if not player then return false end
    return Framework.whitelistedPlayers[player.Name] or Framework.whitelistedPlayers[player.DisplayName] or false
end

function Utils.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function Utils.getClosestPlayer(excludeKnocked)
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and Utils.isPlayerValid(player) and not Utils.isWhitelisted(player) then
            if excludeKnocked and Utils.isPlayerKnocked(player) then continue end
            
            local distance = Utils.getDistance(LocalPlayer.Character.HumanoidRootPart.Position, player.Character.HumanoidRootPart.Position)
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    return closestPlayer
end

function Utils.getClosestKnockedPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and Utils.isPlayerValid(player) and Utils.isPlayerKnocked(player) and not Utils.isWhitelisted(player) then
            local distance = Utils.getDistance(LocalPlayer.Character.HumanoidRootPart.Position, player.Character.HumanoidRootPart.Position)
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    return closestPlayer
end

local WeaponManager = {}

WeaponManager.gunShops = {
    ["[LMG]"] = CFrame.new(-577, 7.9, -716),
    ["[Rifle]"] = CFrame.new(-583, 7.9, -711),
    ["[AUG]"] = CFrame.new(-583, 7.9, -722)
}

function WeaponManager.getEquippedWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and WeaponManager.gunShops[tool.Name] then
            return tool
        end
    end
    return nil
end

function WeaponManager.getWeaponFromBackpack(weaponName)
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool.Name == weaponName then
            return tool
        end
    end
    return nil
end

function WeaponManager.equipWeapon(weaponName)
    local weapon = WeaponManager.getWeaponFromBackpack(weaponName)
    if weapon then
        weapon.Parent = LocalPlayer.Character
        task.wait(0.1)
        return weapon
    end
    return nil
end

function WeaponManager.buyWeapon(weaponName)
    if not WeaponManager.gunShops[weaponName] then return false end
    
    local char = LocalPlayer.Character
    if not Utils.isPlayerValid(LocalPlayer) then return false end
    
    local originalPos = char.HumanoidRootPart.CFrame
    
    char.HumanoidRootPart.CFrame = WeaponManager.gunShops[weaponName]
    task.wait(0.3)
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("Part") and part.Name == "BuyButton" and part:FindFirstChild("SurfaceGui") then
            local gui = part:FindFirstChild("SurfaceGui")
            if gui and gui:FindFirstChild("TextLabel") then
                local label = gui:FindFirstChild("TextLabel")
                if label and string.find(label.Text, weaponName) then
                    char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 0, -2)
                    task.wait(0.1)
                    
                    if part:FindFirstChild("ClickDetector") then
                        fireclickdetector(part.ClickDetector)
                        task.wait(0.3)
                    end
                    break
                end
            end
        end
    end
    
    char.HumanoidRootPart.CFrame = originalPos
    
    return WeaponManager.getWeaponFromBackpack(weaponName) ~= nil
end

function WeaponManager.getWeapon(weaponName)
    local equipped = WeaponManager.getEquippedWeapon()
    if equipped and equipped.Name == weaponName then
        return equipped
    end
    
    local weapon = WeaponManager.equipWeapon(weaponName)
    if weapon then
        return weapon
    end
    
    if WeaponManager.buyWeapon(weaponName) then
        return WeaponManager.equipWeapon(weaponName)
    end
    
    return nil
end

function WeaponManager.reloadWeapon()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
end

local Combat = {}

Combat.settings = {
    autoStompEnabled = false,
    autoGrabEnabled = false,
    grabPosition = nil,
    orbitRadius = 8,
    stompSpeed = 0.3,
    weaponChoice = "[LMG]"
}

function Combat.orbitAroundPlayer(targetPlayer, radius)
    if not Utils.isPlayerValid(targetPlayer) or not Utils.isPlayerValid(LocalPlayer) then return end
    
    local char = LocalPlayer.Character
    local targetPos = targetPlayer.Character.HumanoidRootPart.Position
    
    if not Framework.orbitAngles[targetPlayer.Name] then
        Framework.orbitAngles[targetPlayer.Name] = 0
    end
    
    Framework.orbitAngles[targetPlayer.Name] = Framework.orbitAngles[targetPlayer.Name] + math.rad(10)
    
    local x = math.cos(Framework.orbitAngles[targetPlayer.Name]) * radius
    local z = math.sin(Framework.orbitAngles[targetPlayer.Name]) * radius
    
    local orbitPos = targetPos + Vector3.new(x, 2, z)
    char.HumanoidRootPart.CFrame = CFrame.lookAt(orbitPos, targetPos)
end

function Combat.killPlayer(targetPlayer)
    if not Utils.isPlayerValid(targetPlayer) or not Utils.isPlayerValid(LocalPlayer) then return false end
    
    local weapon = WeaponManager.getWeapon(Combat.settings.weaponChoice)
    if not weapon then return false end
    
    local startTime = tick()
    local timeout = 5
    
    while not Utils.isPlayerKnocked(targetPlayer) and (tick() - startTime) < timeout do
        if not Utils.isPlayerValid(targetPlayer) then break end
        
        Combat.orbitAroundPlayer(targetPlayer, Combat.settings.orbitRadius)
        
        weapon:Activate()
        task.wait(0.1)
        
        if math.random(1, 10) == 1 then
            WeaponManager.reloadWeapon()
            task.wait(0.2)
        end
    end
    
    return Utils.isPlayerKnocked(targetPlayer)
end

function Combat.grabPlayer(targetPlayer)
    if not Utils.isPlayerValid(targetPlayer) or not Utils.isPlayerValid(LocalPlayer) then return false end
    if not Utils.isPlayerKnocked(targetPlayer) then return false end
    
    local char = LocalPlayer.Character
    local targetPos = targetPlayer.Character.HumanoidRootPart.Position
    
    char.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 1, 2), targetPos)
    task.wait(0.2)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
    task.wait(0.3)
    
    return Utils.isPlayerGrabbed(targetPlayer)
end

function Combat.transportPlayer(targetPlayer)
    if not Utils.isPlayerValid(targetPlayer) or not Utils.isPlayerValid(LocalPlayer) then return false end
    if not Combat.settings.grabPosition then return false end
    
    local char = LocalPlayer.Character
    local startPos = char.HumanoidRootPart.Position
    local endPos = Combat.settings.grabPosition.Position
    
    local distance = Utils.getDistance(startPos, endPos)
    local steps = math.max(5, math.floor(distance / 10))
    
    for i = 1, steps do
        if not Utils.isPlayerValid(targetPlayer) or not Utils.isPlayerGrabbed(targetPlayer) then break end
        
        local alpha = i / steps
        local lerpPos = startPos:lerp(endPos, alpha)
        
        char.HumanoidRootPart.CFrame = CFrame.new(lerpPos)
        task.wait(0.1)
    end
    
    char.HumanoidRootPart.CFrame = Combat.settings.grabPosition
    return true
end

function Combat.releaseGrab()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
end

function Combat.stompPlayer(targetPlayer)
    if not Utils.isPlayerValid(targetPlayer) or not Utils.isPlayerValid(LocalPlayer) then return false end
    if not Utils.isPlayerKnocked(targetPlayer) then return false end
    
    local char = LocalPlayer.Character
    local targetPos = targetPlayer.Character.HumanoidRootPart.Position
    
    char.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
    
    local stompCount = 0
    while Utils.isPlayerKnocked(targetPlayer) and stompCount < 20 do
        game:GetService("ReplicatedStorage").MainEvent:FireServer("Stomp")
        stompCount = stompCount + 1
        task.wait(Combat.settings.stompSpeed)
    end
    
    return not Utils.isPlayerKnocked(targetPlayer)
end

function Combat.autoStompLoop()
    while Combat.settings.autoStompEnabled do
        local target = Utils.getClosestKnockedPlayer()
        if target then
            Combat.stompPlayer(target)
        end
        task.wait(0.5)
    end
end

function Combat.autoGrabLoop()
    while Combat.settings.autoGrabEnabled do
        local target = Utils.getClosestPlayer(true) -- Exclude knocked players for killing
        if target then
            api:Notify("Targeting " .. target.Name, 1)
            
            -- Kill player if not knocked
            if not Utils.isPlayerKnocked(target) then
                if Combat.killPlayer(target) then
                    api:Notify("Killed " .. target.Name, 2)
                else
                    api:Notify("Failed to kill " .. target.Name, 2)
                    task.wait(2)
                    continue
                end
            end
            
            -- Grab player
            if Combat.grabPlayer(target) then
                api:Notify("Grabbed " .. target.Name, 2)
                
                -- Transport player
                if Combat.transportPlayer(target) then
                    api:Notify("Transported " .. target.Name, 2)
                end
                
                -- Release after 2 seconds
                task.wait(2)
                Combat.releaseGrab()
            else
                api:Notify("Failed to grab " .. target.Name, 2)
            end
        end
        task.wait(1)
    end
end
    
do
    local combatGroup = mainTab:AddLeftGroupbox("Combat")
    
    -- God Block
    local godBlockToggle = combatGroup:AddToggle("god_block", {
        Text = "God Block",
        Default = false,
        Tooltip = "Automatically blocks without animation"
    })
    
    table.insert(Framework.connections, RunService.Heartbeat:Connect(function()
        if godBlockToggle.Value then
            local char = LocalPlayer.Character
            if not char then return end
            
            ReplicatedStorage.MainEvent:FireServer("Block", true)
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    if track.Animation.AnimationId:match("2788354405") then
                        track:Stop()
                    end
                end
            end
            
            local bodyEffects = char:FindFirstChild("BodyEffects")
            if bodyEffects and bodyEffects:FindFirstChild("Block") then
                bodyEffects.Block:Destroy()
            end
        end
    end))
    
    -- Spinbot
    local spinbotToggle = combatGroup:AddToggle("spinbot", {
        Text = "Spinbot",
        Default = false,
        Tooltip = "Spin to avoid bullets"
    })
    
    local spinConnection
    spinbotToggle:OnChanged(function(value)
        if value then
            spinConnection = RunService.Heartbeat:Connect(function()
                if Utils.isPlayerValid(LocalPlayer) then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(20), 0)
                end
            end)
            table.insert(Framework.connections, spinConnection)
        else
            if spinConnection then
                spinConnection:Disconnect()
            end
        end
    end)
    
    combatGroup:AddDivider("Auto Stomp")
    
    -- Auto Stomp Speed
    local stompSpeedSlider = combatGroup:AddSlider("stomp_speed", {
        Text = "Stomp Speed",
        Default = 0.3,
        Min = 0.1,
        Max = 1.0,
        Rounding = 1,
        Suffix = "s",
        Tooltip = "Delay between stomp commands"
    })
    
    stompSpeedSlider:OnChanged(function(value)
        Combat.settings.stompSpeed = value
    end)
    
    -- Auto Stomp Toggle
    local autoStompToggle = combatGroup:AddToggle("auto_stomp", {
        Text = "Auto Stomp",
        Default = false,
        Tooltip = "Automatically stomp knocked players"
    })
    
    autoStompToggle:OnChanged(function(value)
        Combat.settings.autoStompEnabled = value
        if value then
            task.spawn(Combat.autoStompLoop)
            api:Notify("Auto Stomp: ON", 2)
        else
            api:Notify("Auto Stomp: OFF", 2)
        end
    end)
    
    combatGroup:AddDivider("Auto Grab")
    
    
    local weaponDropdown = combatGroup:AddDropdown("weapon_choice", {
        Text = "Weapon",
        Default = 1,
        Values = {"[LMG]", "[Rifle]", "[AUG]"},
        Tooltip = "Weapon to use for killing"
    })
    
    weaponDropdown:OnChanged(function(value)
        Combat.settings.weaponChoice = value
    end)
    
    
    local orbitSlider = combatGroup:AddSlider("orbit_radius", {
        Text = "Orbit Radius",
        Default = 8,
        Min = 4,
        Max = 15,
        Rounding = 0,
        Suffix = " studs",
        Tooltip = "Distance to orbit around target"
    })
    
    orbitSlider:OnChanged(function(value)
        Combat.settings.orbitRadius = value
    end)
    
    -- Auto Grab Toggle
    local autoGrabToggle = combatGroup:AddToggle("auto_grab", {
        Text = "Auto Grab",
        Default = false,
        Tooltip = "Kill players and grab them to your position"
    })
    
    autoGrabToggle:OnChanged(function(value)
        Combat.settings.autoGrabEnabled = value
        if value then
            if not Combat.settings.grabPosition then
                Combat.settings.grabPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
            end
            task.spawn(Combat.autoGrabLoop)
            api:Notify("Auto Grab: ON", 2)
        else
            api:Notify("Auto Grab: OFF", 2)
        end
    end)
    
    
    combatGroup:AddButton("Set Grab Position", function()
        if Utils.isPlayerValid(LocalPlayer) then
            Combat.settings.grabPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
            api:Notify("Grab position set", 2)
        end
    end)
    
    
    combatGroup:AddButton("Test Grab", function()
        local target = Utils.getClosestKnockedPlayer()
        if target then
            if Combat.grabPlayer(target) then
                api:Notify("Grabbed " .. target.Name, 2)
                task.wait(3)
                Combat.releaseGrab()
            else
                api:Notify("Failed to grab " .. target.Name, 2)
            end
        else
            api:Notify("No knocked players nearby", 2)
        end
    end)
end

do
    local playerGroup = mainTab:AddRightGroupbox("Player Management")
    
    playerGroup:AddDivider("Whitelist")
    
    local whitelistInput = playerGroup:AddInput("whitelist_input", {
        Text = "Player Name",
        Default = "",
        Placeholder = "Enter username",
        Finished = true
    })
    
    playerGroup:AddButton("Add to Whitelist", function()
        local playerName = whitelistInput.Value
        if playerName ~= "" then
            Framework.whitelistedPlayers[playerName] = true
            api:Notify("Added " .. playerName .. " to whitelist", 2)
        end
    end)
    
    playerGroup:AddButton("Remove from Whitelist", function()
        local playerName = whitelistInput.Value
        if playerName ~= "" then
            Framework.whitelistedPlayers[playerName] = nil
            api:Notify("Removed " .. playerName .. " from whitelist", 2)
        end
    end)
    
    playerGroup:AddButton("Clear Whitelist", function()
        Framework.whitelistedPlayers = {}
        api:Notify("Whitelist cleared", 2)
    end)
    
    playerGroup:AddDivider("Trash Talk")
    
    local trashTalkPhrases = {
        "ez clap",
        "get good",
        "imagine dying",
        "skill issue",
        "better luck next time",
        "too easy",
        "UE on top",
        "cry about it",
        "mad cuz bad",
        "you got wrecked"
    }
    
    local trashTalkToggle = playerGroup:AddToggle("trash_talk", {
        Text = "Trash Talk (E Key)",
        Default = false,
        Tooltip = "Press E to send random trash talk"
    })
    
    local trashTalkEnabled = false
    trashTalkToggle:OnChanged(function(value)
        trashTalkEnabled = value
    end)
    
    local function sendMessage(message)
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.TextChannels.RBXGeneral:SendAsync(message)
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
        end
    end
    
    table.insert(Framework.connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not trashTalkEnabled then return end
        if input.KeyCode == Enum.KeyCode.E then
            local message = trashTalkPhrases[math.random(#trashTalkPhrases)]
            sendMessage(message)
            api:Notify("Sent: " .. message, 1)
        end
    end))
end


do
    local utilGroup = mainTab:AddLeftGroupbox("Utilities")
    
    
    local cashAuraEnabled = false
    local cashAuraToggle = utilGroup:AddToggle("cash_aura", {
        Text = "Cash Aura",
        Default = false,
        Tooltip = "Automatically collect money drops"
    })
    
    local function cashAuraLoop()
        while cashAuraEnabled do
            if Utils.isPlayerValid(LocalPlayer) then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local dropFolder = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop")
                
                if dropFolder then
                    for _, drop in pairs(dropFolder:GetChildren()) do
                        if drop:IsA("Part") and drop.Name == "MoneyDrop" then
                            local distance = Utils.getDistance(hrp.Position, drop.Position)
                            if distance <= 15 then
                                local clickDetector = drop:FindFirstChildOfClass("ClickDetector")
                                if clickDetector then
                                    fireclickdetector(clickDetector)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end
    
    cashAuraToggle:OnChanged(function(value)
        cashAuraEnabled = value
        if value then
            task.spawn(cashAuraLoop)
        end
    end)
    
    
    local antiAfkToggle = utilGroup:AddToggle("anti_afk", {
        Text = "Anti AFK",
        Default = false,
        Tooltip = "Prevents being kicked for idling"
    })
    
    local antiAfkConnection
    antiAfkToggle:OnChanged(function(value)
        if value then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
            table.insert(Framework.connections, antiAfkConnection)
        else
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
            end
        end
    end)
    
    
    local antiFlingToggle = utilGroup:AddToggle("anti_fling", {
        Text = "Anti Fling",
        Default = false,
        Tooltip = "Prevents being flung by other players"
    })
    
    local originalProperties = {}
    
    local function antiFlingLoop()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        if not originalProperties[part] then
                            originalProperties[part] = {
                                CanCollide = part.CanCollide,
                                Massless = part.Massless
                            }
                        end
                        
                        if antiFlingToggle.Value then
                            part.CanCollide = false
                            part.Massless = true
                            part.Velocity = Vector3.new(0, 0, 0)
                            part.AngularVelocity = Vector3.new(0, 0, 0)
                        else
                            part.CanCollide = originalProperties[part].CanCollide
                            part.Massless = originalProperties[part].Massless
                        end
                    end
                end
            end
        end
    end
    
    table.insert(Framework.connections, RunService.Heartbeat:Connect(antiFlingLoop))
    
    
    local playerLogsToggle = utilGroup:AddToggle("player_logs", {
        Text = "Player Join/Leave Logs",
        Default = false,
        Tooltip = "Show notifications when players join/leave"
    })
    
    local joinConnection, leaveConnection
    playerLogsToggle:OnChanged(function(value)
        if value then
            joinConnection = Players.PlayerAdded:Connect(function(player)
                api:Notify(player.Name .. " joined the game", 2)
            end)
            
            leaveConnection = Players.PlayerRemoving:Connect(function(player)
                api:Notify(player.Name .. " left the game", 2)
            end)
            
            table.insert(Framework.connections, joinConnection)
            table.insert(Framework.connections, leaveConnection)
        else
            if joinConnection then joinConnection:Disconnect() end
            if leaveConnection then leaveConnection:Disconnect() end
        end
    end)
end


do
    local serverGroup = mainTab:AddRightGroupbox("Server")
    
    serverGroup:AddButton("Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    
    serverGroup:AddButton("Copy Server Join Script", function()
        local joinScript = string.format(
            "game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)",
            game.PlaceId, game.JobId
        )
        setclipboard(joinScript)
        api:Notify("Copied join script to clipboard", 2)
    end)
    
    serverGroup:AddButton("Voice Chat Fix", function()
        local success, error = pcall(function()
            game:GetService("VoiceChatService"):JoinVoice()
        end)
        
        if success then
            api:Notify("Voice chat reconnected", 2)
        else
            api:Notify("Voice chat fix failed: " .. tostring(error), 3)
        end
    end)
end


function api.Unload()
    
    Combat.settings.autoStompEnabled = false
    Combat.settings.autoGrabEnabled = false
    
    
    for _, connection in pairs(Framework.connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    
    for _, thread in pairs(Framework.threads) do
        if thread then
            task.cancel(thread)
        end
    end
    
    
    Framework.connections = {}
    Framework.threads = {}
    Framework.activeFeatures = {}
    Framework.whitelistedPlayers = {}
    Framework.lastPositions = {}
    Framework.orbitAngles = {}
    
    api:Notify("Script unloaded successfully", 2)
end


api:Notify("Skepta Lua Loaded", 3)
