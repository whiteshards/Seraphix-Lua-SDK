local HttpService = game:GetService("HttpService")

local API_BASE_URL = "https://seraphix-api.vercel.app"

local keysystem_id = ""
local script_key = ""

local function formatPrint(message, messageType, silent)
    if silent == nil then silent = false end
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

local function getHWID()
    return gethwid()
end

local function getStatus(silent)
    return makeRequest("GET", "/v1/status", nil, nil, silent)
end

local function verifyKey(silent)
    if keysystem_id == "" then
        formatPrint("keysystem_id is not set! Please set it like: keysystem_id = 'your_id'", "error", silent)
        return {
            success = false,
            error = "NO_KEYSYSTEM_ID",
            message = "keysystem_id is not set"
        }
    end
    
    if script_key == "" then
        formatPrint("script_key is not set! Please set it like: script_key = 'your_key'", "error", silent)
        return {
            success = false,
            error = "NO_KEY",
            message = "script_key is not set"
        }
    end
    
    local hwid = getHWID()
    local endpoint = "/v1/keysystems/keys?id=" .. game:GetService("HttpService"):UrlEncode(keysystem_id)
    local body = {
        key = script_key,
        hwid = hwid
    }
    
    return makeRequest("POST", endpoint, nil, body, silent)
end
return {
    keysystem_id = keysystem_id,
    script_key = script_key,
    getStatus = getStatus,
    verifyKey = verifyKey,
    setBaseUrl = setBaseUrl,
    getBaseUrl = getBaseUrl,
    getHWID = getHWID,
    StatusMessages = {
        KEY_VALID = "Key is valid and HWID bound successfully",
        KEY_INVALID = "The provided key is invalid",
        KEY_EXPIRED = "The key has expired",
        KEY_HWID_LOCKED = "Key is already bound to a different HWID"
    }
}
