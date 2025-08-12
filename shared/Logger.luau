local Logger = {}

--Send in format of Title, Data for each log element
function Logger.Log(...)

	local numArgs = select("#", ...)

	for i = 1, numArgs/2 do
		local title = select(i, ...)
		local content = select(i+1, ...)
		print(title..": ", content)
		i+=2
	end
end

return Logger
