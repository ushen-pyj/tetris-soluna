local SevenBag = {}

local DEFAULT_KINDS = {"I","O","T","S","Z","J","L"}

local function copy_table(t)
	local r = {}
	for i = 1, #t do r[i] = t[i] end
	return r
end

local function shuffle_inplace(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

function SevenBag.new(kinds)
    ---@class SevenBag
	local self = {
		_kinds = kinds and copy_table(kinds) or copy_table(DEFAULT_KINDS),
		_queue = {},
	}

	local function refill()
		local pack = copy_table(self._kinds)
		shuffle_inplace(pack)
		for i = 1, #pack do
			self._queue[#self._queue + 1] = pack[i]
		end
	end

	function self:next()
		if #self._queue == 0 then
			refill()
		end
		local v = self._queue[1]
		table.remove(self._queue, 1)
		return v
	end

	function self:reset()
		self._queue = {}
	end

	return self
end

return SevenBag


