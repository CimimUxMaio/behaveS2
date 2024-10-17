local utils = {}

--- @return string
function utils.uuid()
	local random = math.random
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	local uuid, _ = string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
		return string.format("%x", v)
	end)
	return uuid
end

--- @param x number
--- @param y number
--- @return number
function utils.magnitude(x, y)
	return math.sqrt(x ^ 2 + y ^ 2)
end

--- @param startX number
--- @param startY number
--- @param endX number
--- @param endY number
--- @return number
function utils.distance(startX, startY, endX, endY)
	return utils.magnitude(endX - startX, endY - startY)
end

--- @param x number
--- @param y number
--- @return number, number
function utils.normalize(x, y)
	local dist = utils.magnitude(x, y)
	return x / dist, y / dist
end

--- @param a number
--- @param b number
--- @param t number
--- @return number
function utils.lerp(a, b, t)
	return a + (b - a) * t
end

--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @param t number
--- @return number, number
function utils.lerp2D(x1, y1, x2, y2, t)
	return utils.lerp(x1, x2, t), utils.lerp(y1, y2, t)
end

return utils
