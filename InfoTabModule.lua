local InfoModule = {}

function InforModule:Build(window, Library, userKey)
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local player = Players.LocalPlayer
	local request = (syn and syn.request) or request or http_request or (http and http.request)

	local serverUrl = "https://roblox-keysystem-silk.vercel.app"

	local infoTab = Library:CreateTab("Info", "user")

	local UserBox = InfoTab:AddGroupLeft("User Profile")

	local AvatarFrame = Instance.new("Frame")
	AvatarFrame.Size = UDim2.new(1, 0, 0, 100)
	AvatarFrame.BackgroundTransparency = 1
	AvatarFrame.Parent = UserBox.Container

	local AvatarImage = Instance.new("ImageLabel")
	AvatarImage.Size = UDim2.FromOffset(100, 100)
	AvatarImage.Position = UDim2.fromScale(0.5, 0)
	AvatarImage.BackgroundTransparency = 1

	pcall(function()
		AvatarImage.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	AvatarImage.Parent = AvatarFrame

	Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(0, 8) 
    local stroke = Instance.new("UIStroke", AvatarImage)
    stroke.Color = Library.Scheme.OutlineColor
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    UserBox:Resize()

    UserBox:AddLabel("Username: " .. player.Name)
    UserBox:AddLabel("Display Name: " .. player.DisplayName)
    UserBox:AddDivider()
    UserBox:AddLabel("Your Key: " .. tostring(userKey))

    UserBox:AddButton("Copy Key", function()
        if setclipboard then
            setclipboard(tostring(userKey))
            Library:Notify("Key successfully copied to clipboard!", 3)
        else
            Library:Notify("Your executor does not support copying.", 3)
        end
    end)

    -- ==========================================
    -- RIGHT SIDE: KEY STATISTICS
    -- ==========================================
    local StatsBox = InfoTab:AddRightGroupbox("Key Statistics")

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

                if success and data then
                    TypeLabel:SetText("Key Type: " .. data.type)
                    HwidLabel:SetText("HWIDs Used: " .. tostring(data.hwids_used) .. " / " .. tostring(data.max_hwids))

                    if data.is_expired then
                        StatusLabel:SetText("Status: Expired / Revoked")
                    else
                        StatusLabel:SetText("Status: Active")
                    end

                    if data.type == "Lifetime" then
                        TimeLabel:SetText("Time Remaining: Lifetime")
                    else
                        local currentMs = os.time() * 1000
                        local remainingMs = data.expires_at - currentMs

                        if remainingMs > 0 then
                            local days = math.floor(remainingMs / (1000 * 60 * 60 * 24))
                            local hours = math.floor((remainingMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
                            TimeLabel:SetText(string.format("Time Remaining: %d Days, %d Hours", days, hours))
                        else
                            TimeLabel:SetText("Time Remaining: 0 Days (Expired)")
                        end
                    end
                    StatsBox:Resize()
                else
                    StatusLabel:SetText("Status: Failed to parse server data.")
                end
            else
                StatusLabel:SetText("Status: Invalid Key or Server Offline.")
            end
        end)
    end

    local RefreshButton = StatsBox:AddButton("Refresh Stats", function()
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