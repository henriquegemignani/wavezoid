package.path = '../src/?.lua;?.txt;' .. package.path
lovecat = require 'lovecat'
-- lovecat = require 'lovecat-data'

function love.conf(t)
    t.version = '0.10.2'
    t.window.display = 2
    t.window.centered = true
end