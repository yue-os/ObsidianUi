local InfoModule = {}

function InfoModule:Build(window, Library, userKey)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    local request = (syn and syn.request) or request or http_request or (http and http.request)

    -- 🔴 FIX 1: Point to your Express Render Backend, NOT your Vercel Frontend!
    local serverUrl = "https://roblox-keysystem-6xwi.onrender.com"

    local infoTab = window:AddTab("Info", "user")
    local UserBox = infoTab:AddLeftGroupbox("User Profile")

    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Size = UDim2.new(1, 0, 0, 100)
    AvatarFrame.BackgroundTransparency = 1
    AvatarFrame.Parent = UserBox.Container

    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Size = UDim2.fromOffset(100, 100)
    AvatarImage.Position = UDim2.fromScale(0.5, 0)
    AvatarImage.AnchorPoint = Vector2.new(0.5, 0)
    AvatarImage.BackgroundTransparency = 1

    pcall(function()
        AvatarImage.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    AvatarImage.Parent = AvatarFrame

    Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(0, 8) 
    local stroke = Instance.new("UIStroke", AvatarImage)
    stroke.Color = Library.Scheme.OutlineColor
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    task.defer(function()
        UserBox:Resize()
    end)

    UserBox:AddLabel("Username: " .. player.Name)
    UserBox:AddLabel("Display Name: " .. player.DisplayName)
    UserBox:AddDivider()
    UserBox:AddLabel("Your Key: " .. tostring(userKey))

    UserBox:AddButton("Copy Key", function()
        if setclipboard then
            pcall(setclipboard, tostring(userKey))
            Library:Notify("Key successfully copied to clipboard!", 3)
        else
            Library:Notify("Your executor does not support copying.", 3)
        end
    end)

    -- ==========================================
    -- RIGHT SIDE: KEY STATISTICS
    -- ==========================================
    local StatsBox = infoTab:AddRightGroupbox("Key Statistics")

    local TypeLabel = StatsBox:AddLabel("Key Type: Loading...")
    local StatusLabel = StatsBox:AddLabel("Status: Loading...")
    local TimeLabel = StatsBox:AddLabel("Time Remaining: Loading...")
    local HwidLabel = StatsBox:AddLabel("HWIDs Used: Loading...")

    StatsBox:AddDivider()

    local function fetchKeyStats()
        task.spawn(function()
            if not request then
                StatusLabel:SetText("Status: Executor does not support HTTP requests.")
                return
            end

            local response = request({
                Url = serverUrl .. "/api/key-info?key=" .. tostring(userKey),
                Method = "GET"
            })

            if response and response.StatusCode == 200 then
                local success, data = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)

                if success and type(data) == "table" then
                    TypeLabel:SetText("Key Type: " .. tostring(data.type or "Free Key"))
                    
                    local hwidsUsed = data.hwids_used or 0
                    local maxHwids = data.max_hwids or 1
                    HwidLabel:SetText("HWIDs Used: " .. tostring(hwidsUsed) .. " / " .. tostring(maxHwids))

                    if data.is_expired then
                        StatusLabel:SetText("Status: Expired / Revoked")
                    else
                        StatusLabel:SetText("Status: Active")
                    end

                    if data.type == "Lifetime" or tostring(userKey):find("LIFE") then
                        TimeLabel:SetText("Time Remaining: Lifetime (Never Expires)")
                    else
                        -- 🔴 FIX 2: Safely parse ISO Date String or Epoch MS
                        local expireMs = 0
                        if type(data.expires_at) == "number" then
                            expireMs = data.expires_at
                        elseif type(data.expires_at) == "string" then
                            pcall(function()
                                local dt = DateTime.fromIsoDate(data.expires_at)
                                if dt then expireMs = dt.UnixTimestampMillis end
                            end)
                        end

                        local currentMs = os.time() * 1000
                        local remainingMs = expireMs - currentMs

                        if remainingMs > 0 then
                            local days = math.floor(remainingMs / (1000 * 60 * 60 * 24))
                            local hours = math.floor((remainingMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
                            local mins = math.floor((remainingMs % (1000 * 60 * 60)) / (1000 * 60))
                            
                            if days > 0 then
                                TimeLabel:SetText(string.format("Time Remaining: %d Days, %d Hours", days, hours))
                            else
                                TimeLabel:SetText(string.format("Time Remaining: %d Hours, %d Mins", hours, mins))
                            end
                        else
                            TimeLabel:SetText("Time Remaining: Expired")
                        end
                    end
                    
                    task.defer(function()
                        StatsBox:Resize()
                    end)
                else
                    StatusLabel:SetText("Status: Failed to parse server data.")
                end
            else
                StatusLabel:SetText("Status: Invalid Key or Server Offline.")
            end
        end)
    end

    StatsBox:AddButton("Refresh Stats", function()
        Library:Notify("Refreshing statistics...", 2)
        TypeLabel:SetText("Key Type: Loading...")
        StatusLabel:SetText("Status: Loading...")
        TimeLabel:SetText("Time Remaining: Loading...")
        HwidLabel:SetText("HWIDs Used: Loading...")
        fetchKeyStats()
    end)

    fetchKeyStats()
end

return InfoModule