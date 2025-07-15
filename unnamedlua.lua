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

local extrasTab = api:AddTab("extras")

do
    local creditsGroup = extrasTab:AddLeftGroupbox("credits")
    
    creditsGroup:AddLabel(
        'script by: @daskepta', true
    )
end

do
    local updatesGroup = extrasTab:AddRightGroupbox("update logs")
    
    updatesGroup:AddLabel(
        'update logs:\n' ..
        '[+] fixed trash talk\n' ..
        '[+] teleport to silent aim target\n' ..
        '[+] added fling all feature\n' ..
	'find any bugs? dm me. have any suggestions? @daskepta on discord', true
    )
end

do
    local group = extrasTab:AddLeftGroupbox("server")

    group:AddButton("vc unban", function()
        local success, err = pcall(function()
            game:GetService("VoiceChatService"):joinVoice()
        end)
        api:Notify(success and "reconnected to vc" or ("vc failed: " .. tostring(err)), 2)
    end)

    group:AddButton("rejoin server", function()
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        api:Notify(success and "rejoining server" or ("failed: " .. tostring(err)), 2)
    end)
    
    group:AddButton("copy join link", function()
     local placeId = game.PlaceId  
     local serverId = game.JobId  
    
       local joinScript = string.format("cloneref(game:GetService('TeleportService')):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)", placeId, serverId)
    
    
       setclipboard(joinScript)
    
      api:Notify("copied server join script", 3);
  end)
end

local miscGroup = extrasTab:AddLeftGroupbox("misc")

local silentBlockToggle = miscGroup:AddToggle("god_block", {
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

miscGroup:AddToggle("cash_aura_toggle", {
    Text = "cash aura",
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

miscGroup:AddToggle("anti_afk", {
    Text = "anti afk",
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

do
    local group = miscGroup 

    local joinConn, leaveConn = nil, nil

    group:AddToggle("logs_toggle", {
        Text = "actitivty logs",
        Default = false,
        Tooltip = "leave and join logs",
        Callback = function(enabled)
            if enabled then
                group:AddInput("notify_text", {
                    Text = "Notification Text",
                    Default = "{NAME} has {ACTIVITY} the game.",
                    Placeholder = "ex: {NAME}, {ACTIVITY}",
                    Finished = true
                })
                group:AddSlider("notify_duration", {
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

miscGroup:AddToggle("anti_fling", {
    Text = "anti fling",
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

do
    local group = extrasTab:AddLeftGroupbox("troll")

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

    group:AddToggle("jerk_toggle", {
        Text = "jerk tool",
        Default = false,
        Callback = function(state)
            if state then createTool() else removeTool() end
        end
    })

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

group:AddToggle("autotrash_e", { Text = "trash talk", Default = false }):OnChanged(function(v)
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

   group:AddToggle("anti_rpg", {
        Text = "anti rpg",
        Default = true,
    }):OnChanged(function(v)
        framework.antiRpgActive = v
    end)

    local function find_first_child(obj, name)
        return obj and obj:FindFirstChild(name)
    end

    local function GetLauncher()
        return find_first_child(workspace, "Ignored")
           and find_first_child(workspace.Ignored, "Model")
           and find_first_child(workspace.Ignored.Model, "Launcher")
    end

    local function IsLauncherNear()
        local HRP = LocalPlayer.Character and find_first_child(LocalPlayer.Character, "HumanoidRootPart")
        local Launcher = GetLauncher()

        if not HRP or not Launcher then return false end
        return (Launcher.Position - HRP.Position).Magnitude < 20
    end

    local lastPosition = nil
    local isVoided = false
    local voidDebounce = false

    local function VoidCharacter()
        if voidDebounce then return end
        voidDebounce = true
        
        local char = LocalPlayer.Character
        local hrp = char and find_first_child(char, "HumanoidRootPart")
        if not hrp then return end
        
        lastPosition = hrp.CFrame
        hrp.CFrame = CFrame.new(0, -10000, 0) 
        isVoided = true
        
        task.delay(1, function()
            if char and char:FindFirstChild("HumanoidRootPart") and lastPosition then
                char.HumanoidRootPart.CFrame = lastPosition
            end
            isVoided = false
            task.delay(0.5, function()
                voidDebounce = false
            end)
        end)
    end

    table.insert(framework.connections, RunService.Heartbeat:Connect(function()
        if not framework.antiRpgActive then return end

        if IsLauncherNear() and not isVoided then
            VoidCharacter()
        end
    end))
    
    do
    local group = extrasTab:AddLeftGroupbox("troll")

    local gunShops = {
        ["[LMG]"] = CFrame.new(-577, 7.9, -716),
        ["[Rifle]"] = CFrame.new(-583, 7.9, -711),
        ["[AUG]"] = CFrame.new(-583, 7.9, -722)
    }
    
    local whitelistedPlayers = {}
    
    group:AddDivider("Whitelist Management")
    
    group:AddInput("whitelist_input", {
        Text = "Player Name",
        Default = "",
        Placeholder = "Enter username to whitelist",
        Finished = true
    })
    
    group:AddButton("Add to Whitelist", function()
        local playerName = Options.whitelist_input.Value
        if playerName ~= "" and not whitelistedPlayers[playerName] then
            whitelistedPlayers[playerName] = true
            api:Notify("Added " .. playerName .. " to whitelist", 2)
        end
    end)
    
    group:AddButton("Remove from Whitelist", function()
        local playerName = Options.whitelist_input.Value
        if playerName ~= "" and whitelistedPlayers[playerName] then
            whitelistedPlayers[playerName] = nil
            api:Notify("Removed " .. playerName .. " from whitelist", 2)
        end
    end)
    
    group:AddButton("Clear Whitelist", function()
        whitelistedPlayers = {}
        api:Notify("Whitelist cleared", 2)
    end)
    
    group:AddDivider("Auto Stomp Settings")
    
    group:AddDropdown("auto_stomp_weapon", {
        Text = "Weapon Selection",
        Default = 1,
        Values = {"[LMG]", "[Rifle]", "[AUG]"},
        Tooltip = "Select weapon for auto stomp"
    })
    
    group:AddToggle("auto_buy_toggle", {
        Text = "Auto Buy Weapon",
        Default = true,
        Tooltip = "Automatically buys the selected weapon if not owned"
    })
    
    group:AddSlider("auto_stomp_delay", {
        Text = "Delay Between Targets",
        Default = 1.5,
        Min = 0.5,
        Max = 5,
        Rounding = 1,
        Suffix = "s",
        Tooltip = "Time to wait between targeting different players"
    })
    
    group:AddToggle("target_knocked", {
        Text = "Target Knocked Players",
        Default = true,
        Tooltip = "Prioritize stomping already knocked players"
    })
    
    group:AddToggle("use_silent_aim", {
        Text = "Use Silent Aim Target",
        Default = true,
        Tooltip = "Target your silent aim target when available"
    })
    
    group:AddToggle("auto_reload", {
        Text = "Auto Reload",
        Default = true,
        Tooltip = "Automatically reload weapons when needed"
    })
    
    local autoStompActive = false
    local autoStompConnection = nil
    
    local function isWhitelisted(player)
        if not player then return false end
        return whitelistedPlayers[player.Name] or whitelistedPlayers[player.DisplayName] or false
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
    
    local function getWeapon()
        local selectedWeapon = Options.auto_stomp_weapon.Value
        local localPlayer = game:GetService("Players").LocalPlayer
        local char = localPlayer.Character
        if not char then return nil end
        
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == selectedWeapon then
                return tool
            end
        end
        
        for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
            if tool.Name == selectedWeapon then
                tool.Parent = char
                task.wait(0.1)
                return tool
            end
        end
        
        local fallbackWeapons = {"[LMG]", "[Rifle]", "[AUG]"}
        for _, weaponName in ipairs(fallbackWeapons) do
            if weaponName ~= selectedWeapon then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == weaponName then
                        return tool
                    end
                end
                
                for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
                    if tool.Name == weaponName then
                        tool.Parent = char
                        task.wait(0.1)
                        return tool
                    end
                end
            end
        end
        
        if Toggles.auto_buy_toggle.Value then
            if buyWeapon(selectedWeapon) then
                for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
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
        if not weapon or not Toggles.auto_reload.Value then return end
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        task.wait(0.5)
    end
    
    local function isPlayerKnocked(player)
        if not player or not player.Character then return false end
        
        local bodyEffects = player.Character:FindFirstChild("BodyEffects")
        if not bodyEffects or not bodyEffects:FindFirstChild("K.O") then return false end
        
        return bodyEffects["K.O"].Value
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
        if Toggles.use_silent_aim.Value and api.Target.silent and api.Target.silent.player then
            local target = api.Target.silent.player
            if target ~= LocalPlayer and 
               target.Character and 
               target.Character:FindFirstChild("HumanoidRootPart") and
               not isWhitelisted(target) and
               not isPlayerKnocked(target) then
                return target
            end
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and 
               player.Character and 
               player.Character:FindFirstChild("HumanoidRootPart") and
               player.Character:FindFirstChildOfClass("Humanoid") and
               player.Character:FindFirstChildOfClass("Humanoid").Health > 0 and
               not isWhitelisted(player) and
               not isPlayerKnocked(player) then
                return player
            end
        end
        return nil
    end
    
    local function stompPlayer(player)
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local targetHRP = player.Character.HumanoidRootPart
        
        char.HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 2, 0))
        task.wait(0.1)
        
        game:GetService("ReplicatedStorage").MainEvent:FireServer("Stomp")
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        
        task.wait(0.2)
        if isPlayerKnocked(player) then
            char.HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 0, 0))
            game:GetService("ReplicatedStorage").MainEvent:FireServer("Stomp")
            task.wait(0.1)
            
            if isPlayerKnocked(player) then
                char.HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 1, 0))
                game:GetService("ReplicatedStorage").MainEvent:FireServer("Stomp")
            end
        end
        
        task.wait(0.3)
        return not isPlayerKnocked(player) or not player.Character
    end
    
    local function knockAndStompTarget(target)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local originalPosition = char.HumanoidRootPart.CFrame
        local targetHRP = target.Character.HumanoidRootPart
        
        local weapon = getWeapon()
        if not weapon then return false end
        
        local targetPos = targetHRP.Position
        local positions = {
            CFrame.new(targetPos + Vector3.new(0, 0, 4), targetPos),
            CFrame.new(targetPos + Vector3.new(4, 0, 0), targetPos),
            CFrame.new(targetPos + Vector3.new(0, 0, -4), targetPos),
            CFrame.new(targetPos + Vector3.new(-4, 0, 0), targetPos),
            CFrame.new(targetPos + Vector3.new(0, 4, 0))
        }
        
        local knocked = false
        for _, pos in ipairs(positions) do
            if isPlayerKnocked(target) then
                knocked = true
                break
            end
            
            char.HumanoidRootPart.CFrame = pos
            task.wait(0.1)
            
            for i = 1, 5 do
                weapon:Activate()
                task.wait(0.05)
            end
            
            task.wait(0.2)
        end
        
        reloadWeapon(weapon)
        
        task.wait(0.5)
        if isPlayerKnocked(target) then
            stompPlayer(target)
        end
        
        if char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = originalPosition
        end
        
        return false
    end
    
    group:AddToggle("auto_stomp", {
        Text = "Auto Stomp",
        Default = false,
        Tooltip = "Automatically kills and stomps players",
        Callback = function(state)
            autoStompActive = state
            
            if state then
                autoStompShouldStop = false
                
                if autoStompConnection then autoStompConnection:Disconnect() end
                
                autoStompConnection = RunService.RenderStepped:Connect(function()
                    if not autoStompActive then return end
                    
                    task.spawn(function()
                        if autoStompShouldStop then return end
                        
                        local char = LocalPlayer.Character
                        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                        
                        local originalPosition = char.HumanoidRootPart.CFrame
                        
                        if Toggles.target_knocked.Value then
                            local knockedPlayer = findKnockedPlayer()
                            if knockedPlayer then
                                stompPlayer(knockedPlayer)
                                
                                if char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.CFrame = originalPosition
                                end
                                
                                task.wait(Options.auto_stomp_delay.Value)
                                return
                            end
                        end
                        
                        local targetPlayer = findTargetPlayer()
                        if targetPlayer then
                            knockAndStompTarget(targetPlayer)
                        end
                        
                        if autoStompShouldStop then
                            if char:FindFirstChild("HumanoidRootPart") and originalPosition then
                                char.HumanoidRootPart.CFrame = originalPosition
                            end
                            return 
                        end
                    end)
                    
                    task.wait(Options.auto_stomp_delay.Value)
                end)
                
                table.insert(framework.connections, autoStompConnection)
            else
                autoStompShouldStop = true
                
                if autoStompConnection then
                    autoStompConnection:Disconnect()
                    autoStompConnection = nil
                end
                
                task.spawn(function()
                    task.wait(0.5)
                    
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then 
                            hum.Health = 0 
                        end
                    end
                end)
            end
        end
    })
    
    if api.Unload then
        local originalUnload = api.Unload
        api.Unload = function()
            autoStompShouldStop = true
            
            if autoStompConnection then
                autoStompConnection:Disconnect()
                autoStompConnection = nil
            end
            
            originalUnload()
        end
    end
end