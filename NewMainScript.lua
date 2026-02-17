local EXPECTED_REPO_OWNER = "poopparty"
local EXPECTED_REPO_NAME = "poopparty"
local ACCOUNT_SYSTEM_URL = "https://raw.githubusercontent.com/poopparty/whitelistcheck/main/AccountSystem.lua"
local WORKINK_LINK = "https://work.ink/1YyH/aerov4-free-key-system"
local KEY_PAGE_URL = "https://wrealaero.github.io/vape-keys/"

local function getHWID()
    local hwid = nil
    
    if gethwid then
        hwid = gethwid()
    elseif getexecutorname then
        local executor_name = getexecutorname()
        local unique_str = executor_name .. tostring(game:GetService("UserInputService"):GetGamepadState(Enum.UserInputType.Gamepad1))
        
        if syn and syn.crypt and syn.crypt.hash then
            hwid = syn.crypt.hash(unique_str)
        elseif crypt and crypt.hash then
            hwid = crypt.hash(unique_str)
        else
            hwid = game:GetService("HttpService"):GenerateGUID(false)
        end
    end
    
    if not hwid and game:GetService("RbxAnalyticsService") then
        local success, result = pcall(function()
            return game:GetService("RbxAnalyticsService"):GetClientId()
        end)
        if success and result then
            hwid = result
        end
    end
    
    if not hwid then
        hwid = tostring(math.random(100000, 999999)) .. tostring(os.time())
    end
    
    return hwid
end

local function clearSecurityFolder()
    if not isfolder('newvape/security') then
        makefolder('newvape/security')
        return
    end
    
    local files = listfiles('newvape/security')
    for _, file in pairs(files) do
        if isfile(file) then
            delfile(file)
        end
    end
end

local function createValidationFile(username, hwid, accountType)
    if not isfolder('newvape/security') then
        makefolder('newvape/security')
    end
    
    if accountType == "premium" then
        local validationData = {
            username = username,
            hwid = hwid,
            timestamp = os.time(),
            account_type = "premium"
        }
        local encoded = game:GetService("HttpService"):JSONEncode(validationData)
        writefile('newvape/security/validated', encoded)
    else
        local keyData = {
            hwid = hwid,
            expiry = os.time() + (12 * 60 * 60),
            created = os.time()
        }
        local encoded = game:GetService("HttpService"):JSONEncode(keyData)
        writefile('newvape/security/freekey.txt', encoded)
    end
end

local function checkExistingValidation()
    if isfile('newvape/security/validated') then
        local validationContent = readfile('newvape/security/validated')
        local success, validationData = pcall(function()
            return game:GetService("HttpService"):JSONDecode(validationContent)
        end)
        
        if success and validationData and validationData.account_type == "premium" then
            local currentHWID = getHWID()
            if validationData.hwid == currentHWID then
                return true, validationData.username, "premium"
            end
        end
    end
    
    if isfile('newvape/security/freekey.txt') then
        local keyContent = readfile('newvape/security/freekey.txt')
        local success, keyData = pcall(function()
            return game:GetService("HttpService"):JSONDecode(keyContent)
        end)
        
        if success and keyData then
            local currentHWID = getHWID()
            if keyData.hwid == currentHWID then
                local currentTime = os.time()
                if currentTime <= keyData.expiry then
                    return true, "free user", "free"
                end
            end
        end
    end
    
    return false, nil, nil
end

local function fetchAccounts()
    local success, response = pcall(function()
        return game:HttpGet(ACCOUNT_SYSTEM_URL)
    end)

    if success and response then
        local accountsTable = loadstring(response)()
        if accountsTable and accountsTable.Accounts then
            return accountsTable.Accounts
        end
    end
    return nil
end

local function SecurityCheck(loginData)
    if not loginData or type(loginData) ~= "table" then
        game.StarterGui:SetCore("SendNotification", {
            Title = "error",
            Text = "wrong loadstring bitch. dm aero",
            Duration = 3
        })
        return false
    end
    
    local inputUsername = loginData.Username
    local inputPassword = loginData.Password
    
    if not inputUsername or not inputPassword then
        game.StarterGui:SetCore("SendNotification", {
            Title = "error", 
            Text = "missing yo credentials fuck u doing? dm aero",
            Duration = 3
        })
        return false
    end
    
    clearSecurityFolder()
    
    local currentHWID = getHWID()
    
    local accounts = fetchAccounts()
    if not accounts then
        game.StarterGui:SetCore("SendNotification", {
            Title = "error",
            Text = "failed to check if its yo account check your wifi it might be shitty. dm aero",
            Duration = 3
        })
        return false
    end
    
    local accountFound = false
    local correctPassword = false
    local accountActive = false
    local accountHWID = nil
    
    for _, account in pairs(accounts) do
        if account.Username == inputUsername then
            accountFound = true
            if account.Password == inputPassword then
                correctPassword = true
                accountActive = account.IsActive == true
                accountHWID = account.HWID
            end
            break
        end
    end
    
    if not accountFound then
        game.StarterGui:SetCore("SendNotification", {
            Title = "access denied",
            Text = "username not found. dm 5qvx for access",
            Duration = 3
        })
        return false
    end
    
    if not correctPassword then
        game.StarterGui:SetCore("SendNotification", {
            Title = "access denied",
            Text = "wrong password for " .. inputUsername,
            Duration = 3
        })
        return false
    end
    
    if not accountActive then
        game.StarterGui:SetCore("SendNotification", {
            Title = "account inactive",
            Text = "your account is currently inactive",
            Duration = 3
        })
        return false
    end
    
    if not accountHWID or accountHWID == "" or accountHWID == "your-hwid-here" or accountHWID:find("hwid-here") then
        game.StarterGui:SetCore("SendNotification", {
            Title = "no hwid set",
            Text = "your account has no hwid set dm aero to set it up",
            Duration = 10
        })
        return false
    end
    
    if currentHWID ~= accountHWID then
        game.StarterGui:SetCore("SendNotification", {
            Title = "hwid mismatch",
            Text = "this device is not authorized for this account",
            Duration = 5
        })
        return false
    end
    
    createValidationFile(inputUsername, currentHWID, "premium")
    
    return true
end

local function validateKey(inputKey, hwid)
    if not inputKey or inputKey == "" then
        return false, "empty_key"
    end
    
    if not inputKey:find("KEY_") then
        return false, "invalid_format"
    end
    
    local parts = {}
    for part in inputKey:gmatch("[^_]+") do
        table.insert(parts, part)
    end
    
    if #parts ~= 5 then
        return false, "invalid_parts"
    end
    
    local sessionCode = parts[2]
    local keyHwidHash = parts[3]
    local keyTimestamp = tonumber(parts[4])
    local keySignature = parts[5]
    
    if not sessionCode or #sessionCode ~= 8 then
        return false, "invalid_session"
    end
    
    if not keyTimestamp then
        return false, "invalid_timestamp"
    end
    
    local currentTime = os.time()
    local keyAge = currentTime - keyTimestamp
    local maxAge = 12 * 60 * 60
    
    if keyAge > maxAge then
        return false, "expired"
    end
    
    if keyAge < 0 then
        return false, "future_timestamp"
    end
    
    local currentHwidHash = ""
    for i = 1, #hwid do
        currentHwidHash = currentHwidHash .. string.format("%02x", string.byte(hwid, i))
    end
    currentHwidHash = currentHwidHash:sub(1, 10)
    
    if keyHwidHash ~= currentHwidHash then
        return false, "hwid_mismatch"
    end
    
    local expectedSig = ""
    local sigBase = sessionCode .. keyHwidHash .. keyTimestamp .. "VAPE_SECRET_2025"
    for i = 1, #sigBase do
        expectedSig = expectedSig .. string.format("%x", string.byte(sigBase, i) % 16)
    end
    expectedSig = expectedSig:sub(1, 8)
    
    if keySignature ~= expectedSig then
        return false, "invalid_signature"
    end
    
    return true, "valid"
end

local UserInputService = game:GetService("UserInputService")

local function showKeyUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AeroKeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game.CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 240)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -120)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(138, 43, 226)
    mainStroke.Transparency = 0.7
    mainStroke.Thickness = 1
    mainStroke.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 24)
    title.Position = UDim2.new(0, 20, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = "aerov4"
    title.TextColor3 = Color3.fromRGB(168, 85, 247)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = mainFrame
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 16)
    subtitle.Position = UDim2.new(0, 20, 0, 40)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "free key system"
    subtitle.TextColor3 = Color3.fromRGB(120, 120, 140)
    subtitle.TextSize = 11
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = mainFrame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = mainFrame
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -40, 1, -75)
    contentFrame.Position = UDim2.new(0, 20, 0, 65)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    local inputLabel = Instance.new("TextLabel")
    inputLabel.Size = UDim2.new(1, 0, 0, 16)
    inputLabel.BackgroundTransparency = 1
    inputLabel.Text = "paste ur key"
    inputLabel.TextColor3 = Color3.fromRGB(168, 85, 247)
    inputLabel.TextSize = 11
    inputLabel.Font = Enum.Font.GothamBold
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.Parent = contentFrame
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, 0, 0, 42)
    inputBox.Position = UDim2.new(0, 0, 0, 24)
    inputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    inputBox.PlaceholderText = "KEY_..."
    inputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
    inputBox.Text = ""
    inputBox.TextColor3 = Color3.fromRGB(200, 200, 220)
    inputBox.TextSize = 12
    inputBox.Font = Enum.Font.Code
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = contentFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputBox
    
    local inputPadding = Instance.new("UIPadding")
    inputPadding.PaddingLeft = UDim.new(0, 12)
    inputPadding.PaddingRight = UDim.new(0, 12)
    inputPadding.Parent = inputBox
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(138, 43, 226)
    inputStroke.Transparency = 0.7
    inputStroke.Thickness = 1
    inputStroke.Parent = inputBox
    
    local activateBtn = Instance.new("TextButton")
    activateBtn.Size = UDim2.new(1, 0, 0, 42)
    activateBtn.Position = UDim2.new(0, 0, 0, 76)
    activateBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
    activateBtn.Text = "activate"
    activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    activateBtn.TextSize = 13
    activateBtn.Font = Enum.Font.GothamBold
    activateBtn.Parent = contentFrame
    
    local activateCorner = Instance.new("UICorner")
    activateCorner.CornerRadius = UDim.new(0, 8)
    activateCorner.Parent = activateBtn
    
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(1, 0, 0, 32)
    getKeyBtn.Position = UDim2.new(0, 0, 1, -32)
    getKeyBtn.BackgroundTransparency = 1
    getKeyBtn.Text = "get key"
    getKeyBtn.TextColor3 = Color3.fromRGB(168, 85, 247)
    getKeyBtn.TextSize = 12
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.Parent = contentFrame
    
    local dragging = false
    local dragInput, mousePos, framePos
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            mainFrame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(KEY_PAGE_URL)
        end
    end)
    
    activateBtn.MouseButton1Click:Connect(function()
        local key = inputBox.Text:gsub("^%s*(.-)%s*$", "%1")
        
        if key == "" then
            return
        end
        
        activateBtn.Text = "checking..."
        activateBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        wait(0.3)
        
        local currentHWID = getHWID()
        local valid, reason = validateKey(key, currentHWID)
        
        if valid then
            createValidationFile("free user", currentHWID, "free")
            screenGui:Destroy()
            
            local isfile = isfile or function(file)
                local suc, res = pcall(function()
                    return readfile(file)
                end)
                return suc and res ~= nil and res ~= ''
            end
            
            local delfile = delfile or function(file)
                writefile(file, '')
            end
            
            local function downloadFile(path, func)
                if not isfile(path) then
                    local suc, res = pcall(function()
                        return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
                    end)
                    if not suc or res == '404: Not Found' then
                        error(res)
                    end
                    if path:find('.lua') then
                        res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
                    end
                    writefile(path, res)
                end
                return (func or readfile)(path)
            end
            
            local function wipeFolder(path)
                if not isfolder(path) then return end
                for _, file in listfiles(path) do
                    if file:find('loader') then continue end
                    if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
                        delfile(file)
                    end
                end
            end
            
            local function downloadPremadeProfiles(commit)
                local httpService = game:GetService('HttpService')
                
                if not isfolder('newvape/profiles/premade') then
                    makefolder('newvape/profiles/premade')
                end
                
                local success, response = pcall(function()
                    return game:HttpGet('https://api.github.com/repos/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/contents/profiles/premade?ref='..commit)
                end)
                
                if success and response then
                    local files = httpService:JSONDecode(response)
                    
                    if type(files) == 'table' then
                        for _, file in pairs(files) do
                            if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                                local filePath = 'newvape/profiles/premade/'..file.name
                                
                                if not isfile(filePath) then
                                    if file.download_url then
                                        local downloadSuccess, fileContent = pcall(function()
                                            return game:HttpGet(file.download_url, true)
                                        end)
                                        
                                        if downloadSuccess and fileContent and fileContent ~= '404: Not Found' then
                                            writefile(filePath, fileContent)
                                        end
                                    else
                                        local downloadSuccess, fileContent = pcall(function()
                                            return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..file.name, true)
                                        end)
                                        
                                        if downloadSuccess and fileContent ~= '404: Not Found' then
                                            writefile(filePath, fileContent)
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                    local profiles = {'aero6872274481.txt', 'aero6872265039.txt'}
                    
                    for _, profileName in ipairs(profiles) do
                        local filePath = 'newvape/profiles/premade/'..profileName
                        if not isfile(filePath) then
                            local downloadSuccess, fileContent = pcall(function()
                                return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..profileName, true)
                            end)
                            
                            if downloadSuccess and fileContent ~= '404: Not Found' then
                                writefile(filePath, fileContent)
                            end
                        end
                    end
                end
            end
            
            for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/profiles/premade', 'newvape/assets', 'newvape/libraries', 'newvape/guis', 'newvape/security'} do
                if not isfolder(folder) then
                    makefolder(folder)
                end
            end
            
            if not shared.VapeDeveloper then
                local _, subbed = pcall(function()
                    return game:HttpGet('https://github.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME)
                end)
                local commit = subbed:find('currentOid')
                commit = commit and subbed:sub(commit + 13, commit + 52) or nil
                commit = commit and #commit == 40 and commit or 'main'
                
                local needsUpdate = commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit
                
                if needsUpdate then
                    wipeFolder('newvape')
                    wipeFolder('newvape/games')
                    wipeFolder('newvape/guis')
                    wipeFolder('newvape/libraries')
                end
                
                downloadPremadeProfiles(commit)
                
                writefile('newvape/profiles/commit.txt', commit)
            end
            
            shared.ValidatedUsername = "free user"
            shared.VapeAccountType = "free"
            
            return loadstring(downloadFile('newvape/main.lua'), 'main')()
        else
            activateBtn.Text = "activate"
            activateBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
        end
    end)
end

local passedArgs = ... or {}

local hasValidation, validatedUsername, accountType = checkExistingValidation()
if hasValidation then
    shared.ValidatedUsername = validatedUsername
    shared.VapeAccountType = accountType
    
    local isfile = isfile or function(file)
        local suc, res = pcall(function()
            return readfile(file)
        end)
        return suc and res ~= nil and res ~= ''
    end
    
    local delfile = delfile or function(file)
        writefile(file, '')
    end
    
    local function downloadFile(path, func)
        if not isfile(path) then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
            end)
            if not suc or res == '404: Not Found' then
                error(res)
            end
            if path:find('.lua') then
                res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
            end
            writefile(path, res)
        end
        return (func or readfile)(path)
    end
    
    local function wipeFolder(path)
        if not isfolder(path) then return end
        for _, file in listfiles(path) do
            if file:find('loader') then continue end
            if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
                delfile(file)
            end
        end
    end
    
    local function downloadPremadeProfiles(commit)
        local httpService = game:GetService('HttpService')
        
        if not isfolder('newvape/profiles/premade') then
            makefolder('newvape/profiles/premade')
        end
        
        local success, response = pcall(function()
            return game:HttpGet('https://api.github.com/repos/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/contents/profiles/premade?ref='..commit)
        end)
        
        if success and response then
            local files = httpService:JSONDecode(response)
            
            if type(files) == 'table' then
                for _, file in pairs(files) do
                    if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                        local filePath = 'newvape/profiles/premade/'..file.name
                        
                        if not isfile(filePath) then
                            if file.download_url then
                                local downloadSuccess, fileContent = pcall(function()
                                    return game:HttpGet(file.download_url, true)
                                end)
                                
                                if downloadSuccess and fileContent and fileContent ~= '404: Not Found' then
                                    writefile(filePath, fileContent)
                                end
                            else
                                local downloadSuccess, fileContent = pcall(function()
                                    return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..file.name, true)
                                end)
                                
                                if downloadSuccess and fileContent ~= '404: Not Found' then
                                    writefile(filePath, fileContent)
                                end
                            end
                        end
                    end
                end
            end
        else
            local profiles = {'aero6872274481.txt', 'aero6872265039.txt'}
            
            for _, profileName in ipairs(profiles) do
                local filePath = 'newvape/profiles/premade/'..profileName
                if not isfile(filePath) then
                    local downloadSuccess, fileContent = pcall(function()
                        return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..profileName, true)
                    end)
                    
                    if downloadSuccess and fileContent ~= '404: Not Found' then
                        writefile(filePath, fileContent)
                    end
                end
            end
        end
    end
    
    for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/profiles/premade', 'newvape/assets', 'newvape/libraries', 'newvape/guis', 'newvape/security'} do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
    
    if not shared.VapeDeveloper then
        local _, subbed = pcall(function()
            return game:HttpGet('https://github.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME)
        end)
        local commit = subbed:find('currentOid')
        commit = commit and subbed:sub(commit + 13, commit + 52) or nil
        commit = commit and #commit == 40 and commit or 'main'
        
        local needsUpdate = commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit
        
        if needsUpdate then
            wipeFolder('newvape')
            wipeFolder('newvape/games')
            wipeFolder('newvape/guis')
            wipeFolder('newvape/libraries')
        end
        
        downloadPremadeProfiles(commit)
        
        writefile('newvape/profiles/commit.txt', commit)
    end
    
    return loadstring(downloadFile('newvape/main.lua'), 'main')()
end

if passedArgs.Username and passedArgs.Password then
    local success = SecurityCheck(passedArgs)
    if not success then
        return
    end
    
    local isfile = isfile or function(file)
        local suc, res = pcall(function()
            return readfile(file)
        end)
        return suc and res ~= nil and res ~= ''
    end
    
    local delfile = delfile or function(file)
        writefile(file, '')
    end
    
    local function downloadFile(path, func)
        if not isfile(path) then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
            end)
            if not suc or res == '404: Not Found' then
                error(res)
            end
            if path:find('.lua') then
                res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
            end
            writefile(path, res)
        end
        return (func or readfile)(path)
    end
    
    local function wipeFolder(path)
        if not isfolder(path) then return end
        for _, file in listfiles(path) do
            if file:find('loader') then continue end
            if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
                delfile(file)
            end
        end
    end
    
    local function downloadPremadeProfiles(commit)
        local httpService = game:GetService('HttpService')
        
        if not isfolder('newvape/profiles/premade') then
            makefolder('newvape/profiles/premade')
        end
        
        local success, response = pcall(function()
            return game:HttpGet('https://api.github.com/repos/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/contents/profiles/premade?ref='..commit)
        end)
        
        if success and response then
            local files = httpService:JSONDecode(response)
            
            if type(files) == 'table' then
                for _, file in pairs(files) do
                    if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                        local filePath = 'newvape/profiles/premade/'..file.name
                        
                        if not isfile(filePath) then
                            if file.download_url then
                                local downloadSuccess, fileContent = pcall(function()
                                    return game:HttpGet(file.download_url, true)
                                end)
                                
                                if downloadSuccess and fileContent and fileContent ~= '404: Not Found' then
                                    writefile(filePath, fileContent)
                                end
                            else
                                local downloadSuccess, fileContent = pcall(function()
                                    return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..file.name, true)
                                end)
                                
                                if downloadSuccess and fileContent ~= '404: Not Found' then
                                    writefile(filePath, fileContent)
                                end
                            end
                        end
                    end
                end
            end
        else
            local profiles = {'aero6872274481.txt', 'aero6872265039.txt'}
            
            for _, profileName in ipairs(profiles) do
                local filePath = 'newvape/profiles/premade/'..profileName
                if not isfile(filePath) then
                    local downloadSuccess, fileContent = pcall(function()
                        return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..profileName, true)
                    end)
                    
                    if downloadSuccess and fileContent ~= '404: Not Found' then
                        writefile(filePath, fileContent)
                    end
                end
            end
        end
    end
    
    for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/profiles/premade', 'newvape/assets', 'newvape/libraries', 'newvape/guis', 'newvape/security'} do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
    
    if not shared.VapeDeveloper then
        local _, subbed = pcall(function()
            return game:HttpGet('https://github.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME)
        end)
        local commit = subbed:find('currentOid')
        commit = commit and subbed:sub(commit + 13, commit + 52) or nil
        commit = commit and #commit == 40 and commit or 'main'
        
        local needsUpdate = commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit
        
        if needsUpdate then
            wipeFolder('newvape')
            wipeFolder('newvape/games')
            wipeFolder('newvape/guis')
            wipeFolder('newvape/libraries')
        end
        
        downloadPremadeProfiles(commit)
        
        writefile('newvape/profiles/commit.txt', commit)
    end
    
    shared.ValidatedUsername = passedArgs.Username
    shared.VapeAccountType = "premium"
    
    return loadstring(downloadFile('newvape/main.lua'), 'main')()
end

if passedArgs.Key then
    local currentHWID = getHWID()
    local valid, reason = validateKey(passedArgs.Key, currentHWID)
    
    if valid then
        createValidationFile("free user", currentHWID, "free")
        shared.ValidatedUsername = "free user"
        shared.VapeAccountType = "free"
        
        local isfile = isfile or function(file)
            local suc, res = pcall(function()
                return readfile(file)
            end)
            return suc and res ~= nil and res ~= ''
        end
        
        local delfile = delfile or function(file)
            writefile(file, '')
        end
        
        local function downloadFile(path, func)
            if not isfile(path) then
                local suc, res = pcall(function()
                    return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
                end)
                if not suc or res == '404: Not Found' then
                    error(res)
                end
                if path:find('.lua') then
                    res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
                end
                writefile(path, res)
            end
            return (func or readfile)(path)
        end
        
        local function wipeFolder(path)
            if not isfolder(path) then return end
            for _, file in listfiles(path) do
                if file:find('loader') then continue end
                if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
                    delfile(file)
                end
            end
        end
        
        local function downloadPremadeProfiles(commit)
            local httpService = game:GetService('HttpService')
            
            if not isfolder('newvape/profiles/premade') then
                makefolder('newvape/profiles/premade')
            end
            
            local success, response = pcall(function()
                return game:HttpGet('https://api.github.com/repos/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/contents/profiles/premade?ref='..commit)
            end)
            
            if success and response then
                local files = httpService:JSONDecode(response)
                
                if type(files) == 'table' then
                    for _, file in pairs(files) do
                        if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                            local filePath = 'newvape/profiles/premade/'..file.name
                            
                            if not isfile(filePath) then
                                if file.download_url then
                                    local downloadSuccess, fileContent = pcall(function()
                                        return game:HttpGet(file.download_url, true)
                                    end)
                                    
                                    if downloadSuccess and fileContent and fileContent ~= '404: Not Found' then
                                        writefile(filePath, fileContent)
                                    end
                                else
                                    local downloadSuccess, fileContent = pcall(function()
                                        return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..file.name, true)
                                    end)
                                    
                                    if downloadSuccess and fileContent ~= '404: Not Found' then
                                        writefile(filePath, fileContent)
                                    end
                                end
                            end
                        end
                    end
                end
            else
                local profiles = {'aero6872274481.txt', 'aero6872265039.txt'}
                
                for _, profileName in ipairs(profiles) do
                    local filePath = 'newvape/profiles/premade/'..profileName
                    if not isfile(filePath) then
                        local downloadSuccess, fileContent = pcall(function()
                            return game:HttpGet('https://raw.githubusercontent.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME..'/'..commit..'/profiles/premade/'..profileName, true)
                        end)
                        
                        if downloadSuccess and fileContent ~= '404: Not Found' then
                            writefile(filePath, fileContent)
                        end
                    end
                end
            end
        end
        
        for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/profiles/premade', 'newvape/assets', 'newvape/libraries', 'newvape/guis', 'newvape/security'} do
            if not isfolder(folder) then
                makefolder(folder)
            end
        end
        
        if not shared.VapeDeveloper then
            local _, subbed = pcall(function()
                return game:HttpGet('https://github.com/'..EXPECTED_REPO_OWNER..'/'..EXPECTED_REPO_NAME)
            end)
            local commit = subbed:find('currentOid')
            commit = commit and subbed:sub(commit + 13, commit + 52) or nil
            commit = commit and #commit == 40 and commit or 'main'
            
            local needsUpdate = commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit
            
            if needsUpdate then
                wipeFolder('newvape')
                wipeFolder('newvape/games')
                wipeFolder('newvape/guis')
                wipeFolder('newvape/libraries')
            end
            
            downloadPremadeProfiles(commit)
            
            writefile('newvape/profiles/commit.txt', commit)
        end
        
        return loadstring(downloadFile('newvape/main.lua'), 'main')()
    else
        return
    end
end

showKeyUI()
return
