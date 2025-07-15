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
        '[+]  auto stomp with ragebot\n' ..
        '[+] added whitelist management system\n' ..
        '[+] added weapon selection and auto-buy options\n' ..
        '[+] improved targeting system with silent aim\n' ..
        '[+] fixed trash talk functionality\n' ..
        '[+] added anti-RPG protection\n' ..
        '[+] added fling all feature\n' ..
	'find any bugs? dm me. have any suggestions? @daskepta on discord', true
    )
end


do
    local combatGroup = skeptaTab:AddLeftGroupbox("combat")
    
    
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
        Tooltip = "Rapidly spin your character to dodge bullets"
    })
    
    local spinbotConnection = nil
    
    Toggles.spinbot_toggle:OnChanged(function(value)
        if value then
            
            if spinbotConnection then spinbotConnection:Disconnect() end
            
            spinbotConnection = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    
                    character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(30), 0)
                end
            end)
            
            table.insert(framework.connections, spinbotConnection)
            api:Notify("Spinbot: ON", 2)
        else
            
            if spinbotConnection then
                spinbotConnection:Disconnect()
                spinbotConnection = nil
            end
            api:Notify("Spinbot: OFF", 2)
        end
    end)
    
    -- Auto stomp section
    combatGroup:AddDivider("Auto Stomp")
    
    combatGroup:AddDropdown("auto_stomp_weapon", {
        Text = "Weapon Selection",
        Default = 1,
        Values = {"[LMG]", "[Rifle]", "[AUG]", "Ragebot Only"},
        Tooltip = "Select weapon for auto stomp"
    })
    
    combatGroup:AddToggle("auto_buy_toggle", {
        Text = "Auto Buy Weapon",
        Default = true,
        Tooltip = "Automatically buys the selected weapon if not owned"
    })
    
    combatGroup:AddSlider("stomp_speed", {
        Text = "Stomp Speed",
        Default = 10,
        Min = 1,
        Max = 30,
        Rounding = 0,
        Suffix = "x",
        Tooltip = "How fast to send stomp commands"
    })
    
    combatGroup:AddToggle("target_knocked", {
        Text = "Target Knocked Players",
        Default = true,
        Tooltip = "Prioritize stomping already knocked players"
    })
    
    combatGroup:AddToggle("use_ragebot", {
        Text = "Use Ragebot",
        Default = true,
        Tooltip = "Use ragebot/silent aim for targeting"
    })
    
    combatGroup:AddToggle("use_silent_aim", {
        Text = "Use Silent Aim Target",
        Default = true,
        Tooltip = "Target your silent aim target when available"
    })
    
    combatGroup:AddToggle("auto_reload", {
        Text = "Auto Reload",
        Default = true,
        Tooltip = "Automatically reload weapons when needed"
    })
    
    local autoStompActive = false
    local autoStompConnection = nil
    local autoStompShouldStop = false
    
  
    local function rapidStomp(player)
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local targetHRP = player.Character.HumanoidRootPart
        
       
        char.HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 3, 0))
        
        local stompSpeed = Options.stomp_speed.Value
        local stompCount = 0
        local maxStomps = 50
        local success = false
        
       
        task.spawn(function()
            while stompCount < maxStomps and isPlayerKnocked(player) and autoStompActive do
                game:GetService("ReplicatedStorage").MainEvent:FireServer("Stomp")
                stompCount = stompCount + 1
                task.wait(0.03 / stompSpeed) 
            end
            
            
            success = not isPlayerKnocked(player) or not player.Character
        end)
        
   
        local startTime = os.clock()
        while os.clock() - startTime < 2 and isPlayerKnocked(player) and autoStompActive do
            task.wait(0.1)
        end
        
        return success
    end
    
   
    local function useRagebotOnTarget(target)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        
        local startTime = os.clock()
        local timeout = 5
        
        
        while not isPlayerKnocked(target) and os.clock() - startTime < timeout and autoStompActive do
            task.wait(0.1)
        end
        
        return isPlayerKnocked(target)
    end
    
  
    local function advancedKnockAndStomp(target)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        
        local originalPosition = char.HumanoidRootPart.CFrame
        
        
        local knocked = false
        
       
        if Toggles.use_ragebot.Value then
            knocked = useRagebotOnTarget(target)
        else
       
            local weapon = getWeapon()
            if not weapon then return false end
            
            if weapon ~= true then 
                local targetHRP = target.Character.HumanoidRootPart
                local targetPos = targetHRP.Position
                
              
                local positions = {
                    CFrame.new(targetPos + Vector3.new(0, 0, 4), targetPos),
                    CFrame.new(targetPos + Vector3.new(4, 0, 0), targetPos),
                    CFrame.new(targetPos + Vector3.new(0, 0, -4), targetPos),
                    CFrame.new(targetPos + Vector3.new(-4, 0, 0), targetPos),
                    CFrame.new(targetPos + Vector3.new(0, 4, 0))
                }
                
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
                    
                    task.wait(0.1)
                end
                
                reloadWeapon(weapon)
                
               
                task.wait(0.3)
                knocked = isPlayerKnocked(target)
            end
        end
        
    
        if knocked or isPlayerKnocked(target) then
            rapidStomp(target)
        end
        
        
        if char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = originalPosition
        end
        
        return true
    end
    
    combatGroup:AddToggle("auto_stomp", {
        Text = "Auto Stomp",
        Default = false,
        Tooltip = "Automatically kills and stomps players",
        Callback = function(state)
            autoStompActive = state
            
            if state then
                autoStompShouldStop = false
                api:Notify("Ultra-Fast Auto Stomp: ON", 2)
                
                if autoStompConnection then autoStompConnection:Disconnect() end
                
                autoStompConnection = RunService.Heartbeat:Connect(function()
                    if not autoStompActive then return end
                    
                    task.spawn(function()
                        if autoStompShouldStop then return end
                        
                        local char = LocalPlayer.Character
                        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                        
                        local originalPosition = char.HumanoidRootPart.CFrame
                        
                        -- First priority: Check for knocked players if enabled
                        if Toggles.target_knocked.Value then
                            local knockedPlayer = findKnockedPlayer()
                            if knockedPlayer then
                                rapidStomp(knockedPlayer)
                                
                                if char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.CFrame = originalPosition
                                end
                                
                                return
                            end
                        end
                        
                      
                        local targetPlayer = findTargetPlayer()
                        if targetPlayer then
                            advancedKnockAndStomp(targetPlayer)
                        end
                        
                        if autoStompShouldStop then
                            if char:FindFirstChild("HumanoidRootPart") and originalPosition then
                                char.HumanoidRootPart.CFrame = originalPosition
                            end
                            return 
                        end
                    end)
                end)
                
                table.insert(framework.connections, autoStompConnection)
            else
                autoStompShouldStop = true
                api:Notify("Ultra-Fast Auto Stomp: OFF", 2)
                
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
    

    combatGroup:AddToggle("anti_rpg", {
        Text = "Anti RPG",
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
    
    local whitelistedPlayers = {}
    
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
    

    local auraActive = false
    
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
    
    utilGroup:AddToggle("jerk_toggle", {
        Text = "Jerk Tool",
        Default = false,
        Callback = function(state)
            if state then createTool() else removeTool() end
        end
    })
    
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
    
    -- Activity logs
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
        
        api:Notify("Copied server join script", 3);
    end)
end

