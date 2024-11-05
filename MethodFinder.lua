local globalenv = getgenv and getgenv() or _G or shared
local globalcontainer = globalenv.globalcontainer

if not globalcontainer then
	globalcontainer = {}
	globalenv.globalcontainer = globalcontainer
end

local genvs = { _G, shared }
if getgenv then
	table.insert(genvs, getgenv())
end

local calllimit = 0
do
	local function determineCalllimit()
		calllimit = calllimit + 1
		determineCalllimit()
	end
	pcall(determineCalllimit)
end

local function isEmpty(dict)
	for _ in next, dict do
		return
	end
	return true
end

local depth, printresults, hardlimit, query, antioverflow, matchedall
local function recurseEnv(env, envname)
	if globalcontainer == env then
		return
	end
	if antioverflow[env] then
		return
	end
	antioverflow[env] = true

	depth = depth + 1
	for name, val in next, env do
		if matchedall then
			break
		end

		local Type = type(val)

		if Type == "table" then
			if depth < hardlimit then
				recurseEnv(val, name)
			else
			end
		elseif Type == "function" then
			name = string.lower(tostring(name))
			local matched
			for methodname, pattern in next, query do
				if pattern(name, envname) then
					globalcontainer[methodname] = val
					if not matched then
						matched = {}
					end
					table.insert(matched, methodname)
					if printresults then
						print(methodname, name)
					end
				end
			end
			if matched then
				for _, methodname in next, matched do
					query[methodname] = nil
				end
				matchedall = isEmpty(query)
				if matchedall then
					break
				end
			end
		end
	end
	depth = depth - 1
end

local function finder(Query, ForceSearch, CustomCallLimit, PrintResults)
	antioverflow = {}
	query = {}

	do
		local function Find(String, Pattern)
			return string.find(String, Pattern, nil, true)
		end
		for methodname, pattern in next, Query do
			if not globalcontainer[methodname] or ForceSearch then
				if not Find(pattern, "return") then
					pattern = "return " .. pattern
				end
				query[methodname] = loadstring(pattern)
			end
		end
	end

	depth = 0
	printresults = PrintResults
	hardlimit = CustomCallLimit or calllimit

	recurseEnv(genvs)

	hardlimit = nil
	depth = nil
	printresults = nil

	antioverflow = nil
	query = nil
end

return finder, globalcontainer
