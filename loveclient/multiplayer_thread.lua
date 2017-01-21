
-- load namespace
local socket = require("socket")
print("Load sockets")

-- create a TCP socket and bind it to the local host, at any port
local client = socket.tcp()

print("create client")

local result = client:connect("ec2-52-67-178-225.sa-east-1.compute.amazonaws.com", 9000)
print("connecting client", result)

local outboundChannel = love.thread.getChannel("outbound")
local inboundChannel = love.thread.getChannel("inbound")
while true do
    local tosend = outboundChannel:pop()
    if tosend then
        if tosend == "close" then
            break
        else
            print("sending to socket: " .. tosend)
            client:send(tosend .. "\n")
            print("sent!")
        end
    else
        local canRead = socket.select({client}, {}, 0.15)
        if canRead[1] then
            local message = client:receive()
            if message then
                print("we got message", message)
                inboundChannel:push(message)
            end
        end
    end
end

print("closing", client:close())