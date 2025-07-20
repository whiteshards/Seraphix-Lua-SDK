local HttpService = game:GetService("HttpService")

local SeraphixSDK = {}
SeraphixSDK.__index = SeraphixSDK

local API_BASE_URL = "https://seraphix-api.vercel.app"

local function formatPrint(message, messageType, silent)
    if silent then return end
    
    local prefix = ""
    if messageType == "success" then
        prefix = "[SUCCESS] [Seraphix]"
    elseif messageType == "error" then
        prefix = "[ERROR] [Seraphix]"
    elseif messageType == "info" then
        prefix = "[INFO] [Seraphix]"
    elseif messageType == "warning" then
        prefix = "[WARNING] [Seraphix]"
    else
        prefix = "[DEBUG] [Seraphix]"
    end
    
    print(prefix .. " " .. message)
end

local function detectHttpFunction()
    if request then
        return request
    elseif http_request then
        return http_request
    elseif syn and syn.request then
        return syn.request
    elseif HttpService and HttpService.RequestAsync then
        return function(options)
            return HttpService:RequestAsync(options)
        end
    else
        return nil
    end
end

local httpRequest = detectHttpFunction()

local function makeRequest(method, endpoint, headers, body, silent)
    if not httpRequest then
        formatPrint("No HTTP function available! Make sure you're using a compatible executor.", "error", silent)
        return {
            success = false,
            error = "NO_HTTP_FUNCTION",
            message = "No HTTP function available"
        }
    end
    
    local url = API_BASE_URL .. endpoint
    
    local requestOptions = {
        Url = url,
        Method = method,
        Headers = headers or {}
    }
    
    if body then
        if HttpService and HttpService.JSONEncode then
            requestOptions.Body = HttpService:JSONEncode(body)
        else
            requestOptions.Body = game:GetService("HttpService"):JSONEncode(body)
        end
        requestOptions.Headers["Content-Type"] = "application/json"
    end
    
    formatPrint("Making " .. method .. " request to: " .. endpoint, "info", silent)
    
    local success, response = pcall(function()
        return httpRequest(requestOptions)
    end)
    
    if not success then
        formatPrint("Request failed: " .. tostring(response), "error", silent)
        return {
            success = false,
            error = "REQUEST_FAILED",
            message = tostring(response)
        }
    end
    
    local responseData
    if response.Body and response.Body ~= "" then
        local parseSuccess, parsedData = pcall(function()
            if HttpService and HttpService.JSONDecode then
                return HttpService:JSONDecode(response.Body)
            else
                return game:GetService("HttpService"):JSONDecode(response.Body)
            end
        end)
        
        if parseSuccess then
            responseData = parsedData
        else
            responseData = { message = response.Body }
        end
    else
        responseData = {}
    end
    
    local statusCode = response.StatusCode or response.status_code or response.Status or 0
    
    if statusCode >= 200 and statusCode < 300 then
        formatPrint("Request successful: " .. (responseData.message or "No message"), "success", silent)
        return {
            success = true,
            data = responseData,
            statusCode = statusCode,
            executionTime = responseData.executionTime
        }
    else
        formatPrint("Request failed with status " .. statusCode .. ": " .. (responseData.message or responseData.error or "Unknown error"), "error", silent)
        return {
            success = false,
            error = responseData.error or "HTTP_ERROR",
            message = responseData.message or "Request failed",
            statusCode = statusCode,
            executionTime = responseData.executionTime
        }
    end
end

function SeraphixSDK.new(apiToken)
    local self = setmetatable({}, SeraphixSDK)
    self.apiToken = apiToken
    return self
end

function SeraphixSDK:getStatus(silent)
    silent = silent or false
    return makeRequest("GET", "/v1/status", nil, nil, silent)
end

function SeraphixSDK:getMe(silent)
    silent = silent or false
    
    if not self.apiToken then
        formatPrint("API token is required for this endpoint", "error", silent)
        return {
            success = false,
            error = "NO_TOKEN",
            message = "API token is required"
        }
    end
    
    local headers = {
        ["Authorization"] = "Bearer " .. self.apiToken
    }
    
    return makeRequest("GET", "/v1/me", headers, nil, silent)
end

function SeraphixSDK:getKeysystem(keysystemId, silent)
    silent = silent or false
    
    if not self.apiToken then
        formatPrint("API token is required for this endpoint", "error", silent)
        return {
            success = false,
            error = "NO_TOKEN",
            message = "API token is required"
        }
    end
    
    if not keysystemId then
        formatPrint("Keysystem ID is required", "error", silent)
        return {
            success = false,
            error = "NO_KEYSYSTEM_ID",
            message = "Keysystem ID is required"
        }
    end
    
    local headers = {
        ["Authorization"] = "Bearer " .. self.apiToken
    }
    
    local endpoint = "/v1/keysystems?id=" .. HttpService:UrlEncode(keysystemId)
    return makeRequest("GET", endpoint, headers, nil, silent)
end

function SeraphixSDK:verifyKey(keysystemId, key, hwid, silent)
    silent = silent or false
    
    if not keysystemId then
        formatPrint("Keysystem ID is required", "error", silent)
        return {
            success = false,
            error = "NO_KEYSYSTEM_ID",
            message = "Keysystem ID is required"
        }
    end
    
    if not key then
        formatPrint("Key is required", "error", silent)
        return {
            success = false,
            error = "NO_KEY",
            message = "Key is required"
        }
    end
    
    if not hwid then
        formatPrint("HWID is required", "error", silent)
        return {
            success = false,
            error = "NO_HWID",
            message = "HWID is required"
        }
    end
    
    local endpoint = "/v1/keysystems/keys?id=" .. HttpService:UrlEncode(keysystemId)
    local body = {
        key = key,
        hwid = hwid
    }
    
    return makeRequest("POST", endpoint, nil, body, silent)
end

function SeraphixSDK:resetKeyHWID(keysystemId, key, silent)
    silent = silent or false
    
    if not self.apiToken then
        formatPrint("API token is required for this endpoint", "error", silent)
        return {
            success = false,
            error = "NO_TOKEN",
            message = "API token is required"
        }
    end
    
    if not keysystemId then
        formatPrint("Keysystem ID is required", "error", silent)
        return {
            success = false,
            error = "NO_KEYSYSTEM_ID",
            message = "Keysystem ID is required"
        }
    end
    
    if not key then
        formatPrint("Key is required", "error", silent)
        return {
            success = false,
            error = "NO_KEY",
            message = "Key is required"
        }
    end
    
    local headers = {
        ["Authorization"] = "Bearer " .. self.apiToken
    }
    
    local endpoint = "/v1/keysystems/keys/reset?id=" .. HttpService:UrlEncode(keysystemId)
    local body = {
        key = key
    }
    
    return makeRequest("PATCH", endpoint, headers, body, silent)
end

function SeraphixSDK:setBaseUrl(newUrl)
    API_BASE_URL = newUrl
    formatPrint("Base URL updated to: " .. newUrl, "info", false)
end

function SeraphixSDK:getBaseUrl()
    return API_BASE_URL
end

SeraphixSDK.StatusMessages = {
    KEY_VALID = "Key is valid and HWID bound successfully",
    KEY_INVALID = "The provided key is invalid",
    KEY_EXPIRED = "The key has expired",
    KEY_HWID_LOCKED = "Key is already bound to a different HWID"
}

return SeraphixSDK
