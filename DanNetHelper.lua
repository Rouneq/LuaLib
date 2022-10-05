-- DanNetHelper.lua by Rouneq
-- An extention of helpers.lua by SpecialEd
---@type Mq
local mq = require('mq')

---@type Note
local Note = require('lib.Note')

local TLO = mq.TLO
local DanNet = TLO.DanNet

---@class DanNetHelper
DanNetHelper = {}

local function getTimeout(timeout)
    if (timeout == nil or type(timeout) ~= "number") then
        return 1000
    end

    return timeout
end

--- Checks if the given name is a valid peer on the DanNet
---@param name string
---@return boolean
function DanNetHelper.isPeer(name)
    if (TLO.DanNet(name)()) then
        return true
    end

    return false
end

--- Gets the normalized name of a DanNet peer
---@param index integer
---@return string
---@overload fun(name: string): string
function DanNetHelper.peerName(index)
    local name ---@type string

    if (type(index) == "number") then
        name = DanNet.Peers(index)()
    elseif (type(index) == "string") then
        name = TLO.DanNet(index)()
    end

    if (not name) then
---@diagnostic disable-next-line: return-type-mismatch
        return nil
    end

    local pos = name:find('_')

    if (pos) then
        return name:sub(pos + 1)
    end

    return name
end

--- Sets a DanNet variable
---@param setting string
---@param value any
function DanNetHelper.net(setting, value)
    mq.cmdf('/dnet %s %s', setting, value)
end

--- Issue a query to a DanNet peer
---@param peer string The peer to query
---@param query string The query to sent to the peer
---@param timeout? integer The timeout (milliseconds) in case the query does not respond
---@return any
function DanNetHelper.query(peer, query, timeout)
    local previousRecieved = DanNet(peer).Q(query).Received()

    mq.cmdf('/dquery %s -q "%s"', peer, query)
    mq.delay(getTimeout(timeout), function ()
        return DanNet(peer).Q(query).Received() ~= previousRecieved
    end)

    local value = DanNet(peer).Q(query)()

    Note.Debug(string.format('\ayQuerying - mq.TLO.DanNet(%s).Q(%s) = %s', peer, query, value))

    return value
end

--- Registers a peer observation
---@param peer string The peer to register against
---@param query string The query to register
---@param timeout? integer The timeout (milliseconds) in case the query does not respond
---@return any
function DanNetHelper.observe(peer, query, timeout)
    if not DanNet(peer).OSet(query)() then
        local previousRecieved = DanNet(peer).Q(query).Received()

        Note.Debug(string.format('\ayAdding Observer - mq.TLO.DanNet(%s).O(%s)', peer, query))

        mq.cmdf('/dobserve %s -q "%s"', peer, query)
        mq.delay(getTimeout(timeout), function()
            -- Note.Info('peer: %s', peer)
            -- Note.Info('DanNet peer: %s', DanNet(peer))
            -- Note.Info('query: %s', peer)
            -- Note.Info('DanNet query: %s', DanNet(peer).O(query))
            -- Note.Info('DanNet received: %s', DanNet(peer).O(query).Received())
            return DanNet(peer).O(query).Received() ~= previousRecieved
        end)
    end

    local value = DanNet(peer).O(query)()

    Note.Debug(string.format('\ayObserving - mq.TLO.DanNet(%s).O(%s) = %s', peer, query, value))

    return value
end

--- Unregisters a peer observation
---@param peer string
---@param query string
function DanNetHelper.unobserve(peer, query)
    mq.cmdf('/dobserve %s -q "%s" -drop', peer, query)

    Note.Debug(string.format('\ayRemoving Observer - mq.TLO.DanNet(%s).O(%s) = %s', peer, query, DanNet(peer).O(query)()))
end

return DanNetHelper
