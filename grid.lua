local Grid = {}

function Grid:new(cellWidth, cellHeight)
	local o = { cellWidth = cellWidth, cellHeight = cellHeight }
	setmetatable(o, self)
	self.__index = self
	return o
end

function Grid:getCellWidth()
	return self.cellWidth
end

function Grid:getCellHeight()
	return self.cellHeight
end

function Grid:getDimensions()
	return self.cellWidth, self.cellHeight
end

function Grid:getHalfCellWidth()
	return self.cellWidth / 2
end

function Grid:getHalfCellHeight()
	return self.cellHeight / 2
end

function Grid:getHalfDimensions()
	return self:getHalfCellWidth(), self:getHalfCellHeight()
end

function Grid:fromWorld(x, y)
	return math.floor((x / self.cellWidth) + 0.5), math.floor((y / self.cellHeight) + 0.5)
end

function Grid:toWorld(cx, cy)
	return cx * self.cellWidth, cy * self.cellHeight
end

return Grid
