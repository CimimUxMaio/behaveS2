--- @class Grid
--- @field protected cellWidth number
--- @field protected cellHeight number
local Grid = {}
Grid.__index = Grid

--- @return Grid
function Grid:new(cellWidth, cellHeight)
	local instance = setmetatable({}, self)
	instance.cellWidth = cellWidth
	instance.cellHeight = cellHeight
	return instance
end

--- @return number
function Grid:getCellWidth()
	return self.cellWidth
end

--- @return number
function Grid:getCellHeight()
	return self.cellHeight
end

--- @return number, number
function Grid:getDimensions()
	return self.cellWidth, self.cellHeight
end

--- @return number
function Grid:getHalfCellWidth()
	return self.cellWidth / 2
end

--- @return number
function Grid:getHalfCellHeight()
	return self.cellHeight / 2
end

--- @return number, number
function Grid:getHalfDimensions()
	return self:getHalfCellWidth(), self:getHalfCellHeight()
end

--- @param x number
--- @param y number
--- @return number, number
function Grid:fromWorld(x, y)
	return math.floor((x / self.cellWidth) + 0.5), math.floor((y / self.cellHeight) + 0.5)
end

--- @param cx number
--- @param cy number
--- @return number, number
function Grid:toWorld(cx, cy)
	return cx * self.cellWidth, cy * self.cellHeight
end

return Grid
