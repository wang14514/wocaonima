-- Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config
local KA_RANGE          = 10          
local TELEPORT_INTERVAL = 0.1         
local EGG_LOOP_DELAY    = 0.3

-- State
local localPlayer = Players.LocalPlayer
local character, root
local canKill = false
local kaLoop = nil
local lastTeleport = 0

--------------------------------------------------------------------
local function getClosestPlayer()
    if not (character and character:FindFirstChild("HumanoidRootPart")) then return nil end
    local myRoot = character.HumanoidRootPart
    local closest = nil
    local minDist = KA_RANGE

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == localPlayer or not plr.Character then continue end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                   or plr.Character:FindFirstChild("Torso")
        if not hrp then continue end

        local dist = (hrp.Position - myRoot.Position).Magnitude
        if dist < minDist then
            minDist = dist
            closest = plr
        end
    end
    return closest
end

--------------------------------------------------------------------
local function startKillAura()
    if kaLoop then kaLoop:Disconnect() end

    kaLoop = RunService.Heartbeat:Connect(function()
        local closest = getClosestPlayer()
        if not closest then return end

        local remote = ReplicatedStorage:FindFirstChild("Kw8")
                    and ReplicatedStorage.Kw8:FindFirstChild("93b2718b-2b2a-4859-b36e-fd4614c7f0c9")
        if remote then
            pcall(function()
                remote:FireServer(closest)
            end)
        end

        -- optional hitbox enlarge
        local hitbox = closest.Character and closest.Character:FindFirstChild("Hitbox")
        if hitbox then hitbox.Size = Vector3.new(15,15,15) end
    end)
end

--------------------------------------------------------------------
local function startKillEggs()
    task.spawn(function()
        while true do
            local eggsFolder = workspace:FindFirstChild("Eggs")
            if not eggsFolder then task.wait(EGG_LOOP_DELAY) continue end

            local myTeam = localPlayer:GetAttribute("TeamId")
            for _, egg in ipairs(eggsFolder:GetChildren()) do
                if egg:GetAttribute("TeamId") == myTeam then continue end
                if egg:GetAttribute("Health") <= 0 then continue end

                local rootPart = egg:FindFirstChild("RootPart")
                if not rootPart then continue end

                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = rootPart.CFrame
                end

                local remote = ReplicatedStorage:FindFirstChild("Kw8")
                            and ReplicatedStorage.Kw8:FindFirstChild("f32c9bc1-cb4b-4616-96ac-bddaefd35e92")
                if remote then
                    pcall(function()
                        remote:FireServer(egg)
                    end)
                end
            end
            task.wait(EGG_LOOP_DELAY)
        end
    end)
end

--------------------------------------------------------------------
local function findClosestEnemy()
    if not (character and character:FindFirstChild("HumanoidRootPart")) then return nil end
    local myRoot = character.HumanoidRootPart
    local myTeam = localPlayer:GetAttribute("TeamId")

    local closestHRP = nil
    local closestDist = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == localPlayer then continue end
        local char = plr.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local theirTeam = plr:GetAttribute("TeamId")
        if myTeam and theirTeam and myTeam == theirTeam then continue end

        local dist = (myRoot.Position - hrp.Position).Magnitude
        if dist < closestDist then
            closestDist = dist
            closestHRP = hrp
        end
    end
    return closestHRP
end

--------------------------------------------------------------------
local function startTeleportLoop()
    RunService.Heartbeat:Connect(function()
        if not canKill then return end

        -- refresh character if respawned
        if not (character and character.Parent) then
            character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
            root = character:FindFirstChild("HumanoidRootPart")
            return
        end
        if not root then return end

        local now = tick()
        if now - lastTeleport < TELEPORT_INTERVAL then return end

        local enemyHRP = findClosestEnemy()
        if not enemyHRP then return end

        root.CFrame = enemyHRP.CFrame * CFrame.new(0, 0, 3)  -- 3 studs behind
        lastTeleport = now
    end)
end

--------------------------------------------------------------------
-- Character handling
local function onCharacterAdded(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart", 5)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then onCharacterAdded(localPlayer.Character) end

--------------------------------------------------------------------
-- START EVERYTHING
startKillAura()
startKillEggs()

task.wait(math.random(15, 20))
canKill = true
startTeleportLoop()

--------------------------------------------------------------------