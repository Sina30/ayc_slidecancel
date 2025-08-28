

local SlideStart = false
local slide = false
local lastViewMod
local RotationToDirection = function(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local RayCastGamePlayCamera = function(distance)
    local currentRenderingCam = false
    if not IsGameplayCamRendering() then
        currentRenderingCam = GetRenderingCam()
    end

    local cameraRotation = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
    local cameraCoord = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, b, c, _, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

function AimSlide(slidanimDict, slidanimName, OneaimanimDict, OneaimanimName, TwoaimanimDict, TwoaimanimName, SupportaimanimDict, SupportaimanimName, slidTimeStart, SupportAnimDuration, slidTimeEnd, ped)
    if (IsControlJustPressed(1, 25) or IsDisabledControlJustPressed(1, 25)) then
        if not IsUsingWeaponGroup(-728555052, ped) and not IsUsingWeaponGroup(1548507267, ped) and not IsUsingWeaponGroup(1595662460, ped) and IsEntityPlayingAnim(ped, slidanimDict, slidanimName, 3) then
            if IsUsingWeaponGroup(416676503, ped) or IsUsingWeaponMicroSMG(ped) then
                RequestAnimDict(OneaimanimDict)
                while not HasAnimDictLoaded(OneaimanimDict) do
                    Wait(0)
                end
                TaskPlayAnim(PlayerPedId(), OneaimanimDict, OneaimanimName, 8.0, -8.0, -1, 49, 0.0, false, false, false)
                RemoveAnimDict(OneaimanimDict)
            elseif not IsUsingWeaponGroup(416676503, ped) and not IsUsingWeaponMicroSMG(ped) then
                RequestAnimDict(TwoaimanimDict)
                while not HasAnimDictLoaded(TwoaimanimDict) do
                    Wait(0)
                end
                TaskPlayAnim(PlayerPedId(), TwoaimanimDict, TwoaimanimName, 8.0, -8.0, -1, 50, 0.0, false, false, false)
                RemoveAnimDict(TwoaimanimDict)
            end
        end

    end

    if IsEntityPlayingAnim(ped, OneaimanimDict, OneaimanimName, 3) or IsEntityPlayingAnim(ped, TwoaimanimDict, TwoaimanimName, 3) then
        DisableControlAction(1, 25, true)
        if Config.EnableWeapon then
            SetPedConfigFlag(ped, 78, false)
            ShowHudComponentThisFrame(14)
            if GetFollowPedCamViewMode() ~= 4 and Config.ForceFirstPersonShooting then
                lastViewMod = GetFollowPedCamViewMode()
                SetFollowPedCamViewMode(4)
            end
        end
        -- Simulate the crosshair and shooting logic
        if (IsControlPressed(1, 24) or IsControlJustReleased(1, 24) or IsDisabledControlPressed(1, 24) or IsDisabledControlJustReleased(1, 24)) and Config.EnableWeapon then
            -- local coords, normal = GetWorldCoordFromScreenCoord(0.5, 0.5)
            local hit, coords, entity = RayCastGamePlayCamera(1000.0)
            local weapon = GetCurrentPedWeaponEntityIndex(ped)
            local weaponPos = GetEntityBonePosition_2(weapon, GetEntityBoneIndexByName(weapon, 'gun_muzzle'))
            local handle = StartShapeTestCapsule(weaponPos.x, weaponPos.y, weaponPos.z, coords.x, coords.y, coords.z, 0.2,
                -1, ped, 4)
            local _, _, hitCoords = GetShapeTestResult(handle)
            SetPedShootsAtCoord(ped, hitCoords.x, hitCoords.y, hitCoords.z, true)
        end
    end

    if ((IsControlJustReleased(1, 25) or IsDisabledControlJustReleased(1, 25)) and IsEntityPlayingAnim(ped, slidanimDict, slidanimName, 3)) or (slidTimeStart > slidTimeEnd and IsEntityPlayingAnim(ped, slidanimDict, slidanimName, 3)) then
        if IsEntityPlayingAnim(ped, OneaimanimDict, OneaimanimName, 3) then
            StopAnimTask(ped, OneaimanimDict, OneaimanimName, 3)
        end
        if IsEntityPlayingAnim(ped, TwoaimanimDict, TwoaimanimName, 3) then
            StopAnimTask(ped, TwoaimanimDict, TwoaimanimName, 3)
        end 
        if IsEntityPlayingAnim(ped, slidanimDict, slidanimName, 3) and SupportaimanimDict then
            RequestAnimDict(SupportaimanimDict)
            while not HasAnimDictLoaded(SupportaimanimDict) do
                Wait(0)
            end
            TaskPlayAnim(ped, SupportaimanimDict, SupportaimanimName, 8.0, -4.0, SupportAnimDuration, 48, slidTimeStart, false, false, false)
            RemoveAnimDict(SupportaimanimDict)
        end
        if lastViewMod then
            SetFollowPedCamViewMode(lastViewMod)
            lastViewMod = nil
        end
        SlideStart = false
        slide = false
    end
end

-- Helper Functions
function IsUsingWeaponGroup(groupHash, ped)
    local currentWeaponHash = GetSelectedPedWeapon(ped)
    return GetWeapontypeGroup(currentWeaponHash) == groupHash
end

function IsUsingWeaponMicroSMG(ped)
    local currentWeaponHash = GetSelectedPedWeapon(ped)
    return currentWeaponHash == 324215364 or currentWeaponHash == -1121678507 or currentWeaponHash == -619010992 or currentWeaponHash == 911657153 or currentWeaponHash == 125959754
end

-- Slide functionality
local function handleSlide()
    local ped = PlayerPedId()
    if IsPedOnFoot(ped) and not IsPedSwimming(ped) and not IsEntityOnFire(ped) and not IsPedClimbing(ped) and not IsPedSwimmingUnderWater(ped) and not IsEntityInAir(ped)
        and not IsPedClimbing(ped) and not IsPedFalling(ped) and not IsPedDeadOrDying(ped, true) and GetEntitySpeed(ped) > Config.SpeedLimiter and not GetPedConfigFlag(ped, 253, true)
        and not SlideStart and not IsPedInCover(ped, false) and GetCurrentPedWeaponEntityIndex(ped) ~= 0 then
        if Config.StaminaLimit.enable then
            local playerId= PlayerId()
            local stamina = GetPlayerStamina(playerId)
            if stamina >= Config.StaminaLimit.need then
                stamina = stamina - Config.StaminaLimit.remove
                if stamina < 0 then
                    stamina = 0
                end
                SetPlayerStamina(playerId, stamina)
            else
                return
            end
        end
        ClearPedTasks(ped)

        RequestAnimDict("missheistfbi3b_ig6_v2")
        while not HasAnimDictLoaded("missheistfbi3b_ig6_v2") do
            Wait(0)
        end
        TaskPlayAnim(PlayerPedId(), "missheistfbi3b_ig6_v2", "rubble_slide_franklin", 8.0, -1.0, 1250, 4, 0.0, false, false, false)
        TaskPlayAnim(PlayerPedId(), "missheistfbi3b_ig6_v2", "rubble_slide_michael", 8.0, -1.0, 1250, 48, 0.0, false, false, false)
        RemoveAnimDict("missheistfbi3b_ig6_v2")
    SlideStart = true
        Wait(100)
        return true
    end
end

local function rstop()
    local ped = PlayerPedId()
    local rnd = math.random(1, 9)
    if rnd == 1 then
        RequestAnimDict("move_m@generic")
        while not HasAnimDictLoaded("move_m@generic") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_m@generic", "rstop_quick_r", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 2 then
        RequestAnimDict("move_m@generic")
        while not HasAnimDictLoaded("move_m@generic") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_m@generic", "rstop_quick_l", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 3 then
        RequestAnimDict("move_jump")
        while not HasAnimDictLoaded("move_jump") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_jump", "land_stop_r", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 4 then
        RequestAnimDict("move_jump")
        while not HasAnimDictLoaded("move_jump") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_jump", "land_stop_l", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 5 then
        RequestAnimDict("move_crouch_proto")
        while not HasAnimDictLoaded("move_crouch_proto") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_crouch_proto", "wstop_r_0", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 6 then
        RequestAnimDict("move_ballistic")
        while not HasAnimDictLoaded("move_ballistic") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_ballistic", "rstop_l", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 7 then
        RequestAnimDict("move_ballistic")
        while not HasAnimDictLoaded("move_ballistic") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_ballistic", "rstop_r", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 8 then
        RequestAnimDict("move_action@generic@core")
        while not HasAnimDictLoaded("move_action@generic@core") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_action@generic@core", "rstop_r", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    elseif rnd == 9 then
        RequestAnimDict("move_action@generic@core")
        while not HasAnimDictLoaded("move_action@generic@core") do
            Wait(0)
        end
        TaskPlayAnim(ped, "move_action@generic@core", "rstop_l", 8.0, -2.0, 400, 32, 0.0, false, false, false)
    end
    RemoveAnimDict("move_m@generic")
    RemoveAnimDict("move_jump")
    RemoveAnimDict("move_crouch_proto")
    RemoveAnimDict("move_ballistic")
    RemoveAnimDict("move_action@generic@core")
end

function magnitude(v)
    return math.sqrt(v.x^2 + v.y^2 + v.z^2)
end

function normalize(v)
    local mag = magnitude(v)
    return vector3(v.x / mag, v.y / mag, v.z / mag)
end

-- Handle slide animations and physics
local function slideAnim(slideanimtimer, ped)
    local velocity = GetEntityVelocity(ped)
    local forwardVector = GetEntityForwardVector(ped)
    local speed =  GetEntitySpeed(ped)
    local normalized = normalize(vector3(velocity.x + forwardVector.x, velocity.y + forwardVector.y, velocity.z + forwardVector.z))
    if (not slide and slideanimtimer >= 0.02 and slideanimtimer <= 0.11) then
        slide = true
        local newvec = Config.SlideForce * normalized
        SetEntityProofs(ped, false, false, false, true, false, false, false, false)
        SetEntityVelocity(ped, newvec.x, newvec.y, newvec.z)
        return
    end 

    if (slide and speed < 1.5 and not (IsControlPressed(0, 32) or IsDisabledControlPressed(0, 32))) then
        SetEntityProofs(ped, false, false, false, false, false, false, false, false)
        rstop()
        slide = false
    end
    if (slide and (IsControlPressed(0, 32) or IsDisabledControlPressed(0, 32))) then
        slide = false
    end
end
RegisterKeyMapping('slide', 'Slide', 'keyboard', Config.key)

RegisterCommand('slide', function()
    if handleSlide() then
        MainTick(PlayerPedId())
    end
end, false)

-- Main thread to handle controls
function MainTick(ped)
    while SlideStart and DoesEntityExist(ped) do
        Wait(0)
        -- Process slide animation
        if SlideStart then
            local num = GetEntityAnimCurrentTime(ped, "missheistfbi3b_ig6_v2", "rubble_slide_franklin")
            SetPedRagdollOnCollision(ped, false)

            slideAnim(num, ped)
            AimSlide("missheistfbi3b_ig6_v2", "rubble_slide_franklin", "cover@weapon@core", "idle_turn_stop", "missfbi2", "franklin_sniper_crouch", "missheistfbi3b_ig6_v2", "rubble_slide_michael", num, 1260, 0.23, ped)


            local isFalling = IsPedFalling(ped)
            local isRagdoll = IsPedRagdoll(ped)
            local isInWater = IsEntityInWater(ped)
            local submersionLevel = GetEntitySubmergedLevel(ped)
            local ragdollOnStairs = GetPedConfigFlag(ped, 253, true)
            local vector = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.5, 0.0)
            vector = vector + vector3(0.0, 0.0, 0.3)
            local raycastResult = StartShapeTestCapsule(0.0, 0.0, 0.5, vector.x, vector.y, vector.z, 0.3, 0, PlayerPedId(), 0)
            
            local _, hit = GetShapeTestResult(raycastResult)
            hit = hit ~= 0 and true or false
            if isFalling or isRagdoll or (isInWater and submersionLevel > 0.2) or (slide and hit) or ragdollOnStairs then
                if (isInWater and submersionLevel > 0.2) or (slide and hit) or ragdollOnStairs then
                    slide = false
                    Wait(100)
                    -- SetPedToRagdoll(ped, 2000, 2000, 0, true, true, false)
                end
    
                ClearPedTasks(ped)
                ClearPedSecondaryTask(ped)
                StopAnimTask(ped, "missheistfbi3b_ig6_v2", "rubble_slide_franklin", 1.0)
                StopAnimTask(ped, "missheistfbi3b_ig6_v2", "rubble_slide_michael", 1.0)
                SlideStart = false
            end
        end
    end
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    slide = false
    SlideStart = false
end
