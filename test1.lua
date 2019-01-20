function double(a)
	return a * a
end
local i = 1
function thread()
	i = i + 1	
	return i
end
