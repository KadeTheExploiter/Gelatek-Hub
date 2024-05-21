local mt_rad      = math.rad
local tb_clear    = table.clear
local ts_delay    = task.delay
local ts_wait     = task.wait
local os_clock    = os.clock
local mt_cos      = math.cos
local mt_sin      = math.sin
local mt_random   = math.random
local cf_new      = CFrame.new
local cf_angle    = CFrame.Angles
local cf_zero     = CFrame.identity
local v3_new      = Vector3.new
local v3_zero     = Vector3.zero
local r3_new      = Region3.new
local in_new      = Instance.new

local StarterGui = game:FindFirstChildOfClass("StarterGui")
local UIS = game:FindFirstChildOfClass("UserInputService")
local Tween = game:FindFirstChildOfClass("TweenService")

if not getfenv(0).xyzkade then
	getfenv(0).xyzkade = {}
end

local Global = getfenv(0).xyzkade
getfenv(0).LoadLibrary = function(a)
		local t = {}
		local string = string
		local math = math
		local table = table
		local error = error
		local tonumber = tonumber
		local tostring = tostring
		local type = type
		local setmetatable = setmetatable
		local pairs = pairs
		local ipairs = ipairs
		local assert = assert
		
		local StringBuilder = {
			buffer = {}
		}
		 
		function StringBuilder:New()
			local o = {}
			setmetatable(o, self)
			self.__index = self
			o.buffer = {}
			return o
		end
		 
		function StringBuilder:Append(s)
			self.buffer[#self.buffer+1] = s
		end
		 
		function StringBuilder:ToString()
			return table.concat(self.buffer)
		end
		 
		local JsonWriter = {
			backslashes = {
				['\b'] = "\\b",
				['\t'] = "\\t",
				['\n'] = "\\n",
				['\f'] = "\\f",
				['\r'] = "\\r",
				['"'] = "\\\"",
				['\\'] = "\\\\",
				['/'] = "\\/"
			}
		}
		 
		function JsonWriter:New()
			local o = {}
			o.writer = StringBuilder:New()
			setmetatable(o, self)
			self.__index = self
			return o
		end
		 
		function JsonWriter:Append(s)
			self.writer:Append(s)
		end
		 
		function JsonWriter:ToString()
			return self.writer:ToString()
		end
		 
		function JsonWriter:Write(o)
			local t = type(o)
		
			if t == "nil" then
				self:WriteNil()
			elseif t == "boolean" then
				self:WriteString(o)
			elseif t == "number" then
				self:WriteString(o)
			elseif t == "string" then
				self:ParseString(o)
			elseif t == "table" then
				self:WriteTable(o)
			elseif t == "function" then
				self:WriteFunction(o)
			elseif t == "thread" then
				self:WriteError(o)
			elseif t == "userdata" then
				self:WriteError(o)
			end
		end
		 
		function JsonWriter:WriteNil()
			self:Append("null")
		end
		 
		function JsonWriter:WriteString(o)
			self:Append(tostring(o))
		end
		 
		function JsonWriter:ParseString(s)
			self:Append('"')
		
			self:Append(string.gsub(s, "[%z%c\\\"/]", function(n)
				local c = self.backslashes[n]
		
				if c then return c end
				return string.format("\\u%.4X", string.byte(n))
			end))
		
			self:Append('"')
		end
		 
		function JsonWriter:IsArray(t)
			local count = 0
			local isindex = function(k)
				if type(k) == "number" and k > 0 then
					if math.floor(k) == k then
						return true
					end
				end
		
				return false
			end
		
			for k,v in pairs(t) do
				if not isindex(k) then
					return false, '{', '}'
				else
					count = math.max(count, k)
				end
			end
		
			return true, '[', ']', count
		end
		 
		function JsonWriter:WriteTable(t)
			local ba, st, et, n = self:IsArray(t)
			self:Append(st)
		
			if ba then
				for i = 1, n do
					self:Write(t[i])
		
					if i < n then
						self:Append(',')
					end
				end
			else
				local first = true;
		
				for k, v in pairs(t) do
					if not first then
						self:Append(',')
					end
		
					first = false;
		
					self:ParseString(k)
					self:Append(':')
					self:Write(v)
				end
			end
		
			self:Append(et)
		end
		 
		function JsonWriter:WriteError(o)
			error(string.format("Encoding of %s unsupported", tostring(o)))
		end
		
		function JsonWriter:WriteFunction(o)
			if o == Null then
				self:WriteNil()
			else
				self:WriteError(o)
			end
		end
		 
		local StringReader = {
			s = "",
			i = 0
		}
		 
		function StringReader:New(s)
			local o = {}
			setmetatable(o, self)
			self.__index = self
			o.s = s or o.s
			return o
		end
		 
		function StringReader:Peek()
			local i = self.i + 1
		
			if i <= #self.s then
				return string.sub(self.s, i, i)
			end
		
			return nil
		end
		 
		function StringReader:Next()
			self.i = self.i + 1
		
			if self.i <= #self.s then
				return string.sub(self.s, self.i, self.i)
			end
		
			return nil
		end
		 
		function StringReader:All()
			return self.s
		end
		 
		local JsonReader = {
			escapes = {
				['t'] = '\t',
				['n'] = '\n',
				['f'] = '\f',
				['r'] = '\r',
				['b'] = '\b',
			}
		}
		 
		function JsonReader:New(s)
			local o = {}
			o.reader = StringReader:New(s)
			setmetatable(o, self)
			self.__index = self
			return o;
		end
		 
		function JsonReader:Read()
			self:SkipWhiteSpace()
			local peek = self:Peek()
		
			if peek == nil then
				error(string.format("Nil string: '%s'", self:All()))
			elseif peek == '{' then
				return self:ReadObject()
			elseif peek == '[' then
				return self:ReadArray()
			elseif peek == '"' then
				return self:ReadString()
			elseif string.find(peek, "[%+%-%d]") then
				return self:ReadNumber()
			elseif peek == 't' then
				return self:ReadTrue()
			elseif peek == 'f' then
				return self:ReadFalse()
			elseif peek == 'n' then
				return self:ReadNull()
			elseif peek == '/' then
				self:ReadComment()
				return self:Read()
			else
				return nil
			end
		end
		 
		function JsonReader:ReadTrue()
			self:TestReservedWord{'t', 'r', 'u', 'e'}
			return true
		end
		 
		function JsonReader:ReadFalse()
			self:TestReservedWord{'f', 'a', 'l', 's', 'e'}
			return false
		end
		 
		function JsonReader:ReadNull()
			self:TestReservedWord{'n', 'u', 'l', 'l'}
			return nil
		end
		 
		function JsonReader:TestReservedWord(t)
			for i, v in ipairs(t) do
				if self:Next() ~= v then
					error(string.format("Error reading '%s': %s", table.concat(t), self:All()))
				end
			end
		end
		 
		function JsonReader:ReadNumber()
			local result = self:Next()
			local peek = self:Peek()
		
			while peek ~= nil and string.find(peek, "[%+%-%d%.eE]") do
				result = result .. self:Next()
				peek = self:Peek()
			end
		
			result = tonumber(result)
		
			if result == nil then
				error(string.format("Invalid number: '%s'", result))
			else
				return result
			end
		end
		 
		function JsonReader:ReadString()
			local result = ""
			assert(self:Next() == '"')
		
			while self:Peek() ~= '"' do
				local ch = self:Next()
		
				if ch == '\\' then
					ch = self:Next()
		
					if self.escapes[ch] then
						ch = self.escapes[ch]
					end
				end
		
				result = result .. ch
			end
		
			assert(self:Next() == '"')
		
			local fromunicode = function(m)
				return string.char(tonumber(m, 16))
			end
		
			return string.gsub(result, "u%x%x(%x%x)", fromunicode)
		end
		 
		function JsonReader:ReadComment()
			assert(self:Next() == '/')
			local second = self:Next()
		
			if second == '/' then
				self:ReadSingleLineComment()
			elseif second == '*' then
				self:ReadBlockComment()
			else
				error(string.format("Invalid comment: %s", self:All()))
			end
		end
		 
		function JsonReader:ReadBlockComment()
			local done = false
		
			while not done do
				local ch = self:Next()
		
				if ch == '*' and self:Peek() == '/' then
					done = true
				end
		
				if not done and ch == '/' and self:Peek() == "*" then
					error(string.format("Invalid comment: %s, '/*' illegal.", self:All()))
				end
			end
		
			self:Next()
		end
		 
		function JsonReader:ReadSingleLineComment()
			local ch = self:Next()
		
			while ch ~= '\r' and ch ~= '\n' do
				ch = self:Next()
			end
		end
		 
		function JsonReader:ReadArray()
			local result = {}
			assert(self:Next() == '[')
		
			local done = false
		
			if self:Peek() == ']' then
				done = true;
			end
		
			while not done do
				local item = self:Read()
				result[#result+1] = item
				self:SkipWhiteSpace()
		
				if self:Peek() == ']' then
					done = true
				end
		
				if not done then
					local ch = self:Next()
		
					if ch ~= ',' then
						error(string.format("Invalid array: '%s' due to: '%s'", self:All(), ch))
					end
				end
			end
		
			assert(']' == self:Next())
			return result
		end
		 
		function JsonReader:ReadObject()
			local result = {}
			assert(self:Next() == '{')
		
			local done = false
		
			if self:Peek() == '}' then
				done = true
			end
		
			while not done do
				local key = self:Read()
		
				if type(key) ~= "string" then
					error(string.format("Invalid non-string object key: %s", key))
				end
		
				self:SkipWhiteSpace()
				local ch = self:Next()
		
				if ch ~= ':' then
					error(string.format("Invalid object: '%s' due to: '%s'", self:All(), ch))
				end
		
				self:SkipWhiteSpace()
		
				local val = self:Read()
				result[key] = val
		
				self:SkipWhiteSpace()
		
				if self:Peek() == '}' then
					done = true
				end
		
				if not done then
					ch = self:Next()
		
					if ch ~= ',' then
						error(string.format("Invalid array: '%s' near: '%s'", self:All(), ch))
					end
				end
			end
		
			assert(self:Next() == "}")
			return result
		end
		 
		function JsonReader:SkipWhiteSpace()
			local p = self:Peek()
			while p ~= nil and string.find(p, "[%s/]") do
				if p == '/' then
					self:ReadComment()
				else
					self:Next()
				end
		
				p = self:Peek()
			end
		end
		function JsonReader:Peek()
			return self.reader:Peek()
		end
		function JsonReader:Next()
			return self.reader:Next()
		end
		function JsonReader:All()
			return self.reader:All()
		end
		function Encode(o)
			local writer = JsonWriter:New()
			writer:Write(o)
			return writer:ToString()
		end
		function Decode(s)
			local reader = JsonReader:New(s)
			return reader:Read()
		end
		function Null()
			return Null
		end
		t.DecodeJSON = function(jsonString)
		pcall(function() warn("RbxUtility.DecodeJSON is deprecated, please use Game:GetService('HttpService'):JSONDecode() instead.") end)
		if type(jsonString) == "string" then
			return Decode(jsonString)
		end
		print("RbxUtil.DecodeJSON expects string argument!")
		return nil
		end
		t.EncodeJSON = function(jsonTable)
			pcall(function() warn("RbxUtility.EncodeJSON is deprecated, please use Game:GetService('HttpService'):JSONEncode() instead.") end)
			return Encode(jsonTable)
		end
		t.MakeWedge = function(x, y, z, defaultmaterial)
			return game:GetService("Terrain"):AutoWedgeCell(x, y, z)
		end
		t.SelectTerrainRegion = function(regionToSelect, color, selectEmptyCells, selectionParent)
			local terrain = game:GetService("Workspace"):FindFirstChild("Terrain")
			if not terrain then return end
			assert(regionToSelect)
			assert(color)
			if not type(regionToSelect) == "Region3" then
				error("regionToSelect (first arg), should be of type Region3, but is type", type(regionToSelect))
			end
			if not type(color) == "BrickColor" then
				error("color (second arg), should be of type BrickColor, but is type", type(color))
			end
			local GetCell = terrain.GetCell
			local WorldToCellPreferSolid = terrain.WorldToCellPreferSolid
			local CellCenterToWorld = terrain.CellCenterToWorld
			local emptyMaterial = Enum.CellMaterial.Empty
			local selectionContainer = Instance.new("Model")
			selectionContainer.Name = "SelectionContainer"
			selectionContainer.Archivable = false
			if selectionParent then
				selectionContainer.Parent = selectionParent
			else
				selectionContainer.Parent = game:GetService("Workspace")
			end
			local updateSelection = nil -- function we return to allow user to update selection
			local currentKeepAliveTag = nil -- a tag that determines whether adorns should be destroyed
			local aliveCounter = 0 -- helper for currentKeepAliveTag
			local lastRegion = nil -- used to stop updates that do nothing
			local adornments = {} -- contains all adornments
			local reusableAdorns = {}
			local selectionPart = Instance.new("Part")
			selectionPart.Name = "SelectionPart"
			selectionPart.Transparency = 1
			selectionPart.Anchored = true
			selectionPart.Locked = true
			selectionPart.CanCollide = false
			selectionPart.Size = Vector3.new(4.2, 4.2, 4.2)
			local selectionBox = Instance.new("SelectionBox")
			local function Region3ToRegion3int16(region3)
				local theLowVec = region3.CFrame.p - (region3.Size/2) + Vector3.new(2, 2, 2)
				local lowCell = WorldToCellPreferSolid(terrain,theLowVec)
				local theHighVec = region3.CFrame.p + (region3.Size/2) - Vector3.new(2, 2, 2)
				local highCell = WorldToCellPreferSolid(terrain, theHighVec)
				local highIntVec = Vector3int16.new(highCell.x, highCell.y, highCell.z)
				local lowIntVec = Vector3int16.new(lowCell.x, lowCell.y, lowCell.z)
				return Region3int16.new(lowIntVec, highIntVec)
			end
			function createAdornment(theColor)
				local selectionPartClone = nil
				local selectionBoxClone = nil
				if #reusableAdorns > 0 then
					selectionPartClone = reusableAdorns[1]["part"]
					selectionBoxClone = reusableAdorns[1]["box"]
					table.remove(reusableAdorns,1)
					 
					selectionBoxClone.Visible = true
				else
					selectionPartClone = selectionPart:Clone()
					selectionPartClone.Archivable = false
					 
					selectionBoxClone = selectionBox:Clone()
					selectionBoxClone.Archivable = false
					 
					selectionBoxClone.Adornee = selectionPartClone
					selectionBoxClone.Parent = selectionContainer
					 
					selectionBoxClone.Adornee = selectionPartClone
					 
					selectionBoxClone.Parent = selectionContainer
				end
				if theColor then
					selectionBoxClone.Color = theColor
				end
				return selectionPartClone, selectionBoxClone
			end
			function cleanUpAdornments()
				for cellPos, adornTable in pairs(adornments) do
					if adornTable.KeepAlive ~= currentKeepAliveTag then -- old news, we should get rid of this
						adornTable.SelectionBox.Visible = false
						table.insert(reusableAdorns, {part = adornTable.SelectionPart, box = adornTable.SelectionBox})
						adornments[cellPos] = nil
					end
				end
			end
			function incrementAliveCounter()
				aliveCounter = aliveCounter + 1
				if aliveCounter > 1000000 then
					aliveCounter = 0
				end
				return aliveCounter
			end
			function adornFullCellsInRegion(region, color)
				local regionBegin = region.CFrame.p - (region.Size/2) + Vector3.new(2, 2, 2)
				local regionEnd = region.CFrame.p + (region.Size/2) - Vector3.new(2, 2, 2)
				local cellPosBegin = WorldToCellPreferSolid(terrain, regionBegin)
				local cellPosEnd = WorldToCellPreferSolid(terrain, regionEnd)
				currentKeepAliveTag = incrementAliveCounter()
				for y = cellPosBegin.y, cellPosEnd.y do
					for z = cellPosBegin.z, cellPosEnd.z do
						for x = cellPosBegin.x, cellPosEnd.x do
							local cellMaterial = GetCell(terrain, x, y, z)
							if cellMaterial ~= emptyMaterial then
								local cframePos = CellCenterToWorld(terrain, x, y, z)
								local cellPos = Vector3int16.new(x,y,z)
								local updated = false
								for cellPosAdorn, adornTable in pairs(adornments) do
									if cellPosAdorn == cellPos then
										adornTable.KeepAlive = currentKeepAliveTag
									if color then
										adornTable.SelectionBox.Color = color
									end
									updated = true
									break
								end
							end
							if not updated then
								local selectionPart, selectionBox = createAdornment(color)
								selectionPart.Size = Vector3.new(4, 4, 4)
								selectionPart.CFrame = CFrame.new(cframePos)
								local adornTable = {SelectionPart = selectionPart, SelectionBox = selectionBox, KeepAlive = currentKeepAliveTag}
								adornments[cellPos] = adornTable
							end
						end
					end
				end
			end
		cleanUpAdornments()
		end
		lastRegion = regionToSelect
		if selectEmptyCells then
			local selectionPart, selectionBox = createAdornment(color)
			selectionPart.Size = regionToSelect.Size
			selectionPart.CFrame = regionToSelect.CFrame
			adornments.SelectionPart = selectionPart
			adornments.SelectionBox = selectionBox
			updateSelection = function (newRegion, color)
				if newRegion and newRegion ~= lastRegion then
					lastRegion = newRegion
					selectionPart.Size = newRegion.Size
					selectionPart.CFrame = newRegion.CFrame
				end
		
				if color then
					selectionBox.Color = color
				end
			end
		else
			adornFullCellsInRegion(regionToSelect, color)
			updateSelection = function (newRegion, color)
				if newRegion and newRegion ~= lastRegion then
					lastRegion = newRegion
					adornFullCellsInRegion(newRegion, color)
				end
			end
		end
		local destroyFunc = function()
			updateSelection = nil
			if selectionContainer then selectionContainer:Destroy() end
				adornments = nil
			end
			return updateSelection, destroyFunc
		end
		function t.CreateSignal()
			local this = {}
			local mBindableEvent = Instance.new('BindableEvent')
			local mAllCns = {}
			function this:connect(func)
				if self ~= this then error("connect must be called with `:`, not `.`", 2) end
				if type(func) ~= 'function' then
					error("Argument #1 of connect must be a function, got a "..type(func), 2)
				end
				local cn = mBindableEvent.Event:Connect(func)
				mAllCns[cn] = true
				local pubCn = {}
				function pubCn:disconnect()
					cn:Disconnect()
					mAllCns[cn] = nil
				end
				pubCn.Disconnect = pubCn.disconnect
				return pubCn
			end
			function this:disconnect()
				if self ~= this then error("disconnect must be called with `:`, not `.`", 2) end
				for cn, _ in pairs(mAllCns) do
					cn:Disconnect()
					mAllCns[cn] = nil
				end
			end
			function this:wait()
				if self ~= this then error("wait must be called with `:`, not `.`", 2) end
				return mBindableEvent.Event:Wait()
			end
			function this:fire(...)
				if self ~= this then error("fire must be called with `:`, not `.`", 2) end
				mBindableEvent:Fire(...)
			end
			this.Connect = this.connect
			this.Disconnect = this.disconnect
			this.Wait = this.wait
			this.Fire = this.fire
			return this
		end
		local function Create_PrivImpl(objectType)
			if type(objectType) ~= 'string' then
				error("Argument of Create must be a string", 2)
			end
			return function(dat)
				dat = dat or {}
				local obj = Instance.new(objectType)
				local parent = nil
				local ctor = nil
				for k, v in pairs(dat) do
					if type(k) == 'string' then
						if k == 'Parent' then
							parent = v
						else
							obj[k] = v
						end
					elseif type(k) == 'number' then
						if type(v) ~= 'userdata' then
							error("Bad entry in Create body: Numeric keys must be paired with children, got a: "..type(v), 2)
						end
						v.Parent = obj
					elseif type(k) == 'table' and k.__eventname then
						if type(v) ~= 'function' then
							error("Bad entry in Create body: Key `[Create.E\'"..k.__eventname.."\']` must have a function value\
								got: "..tostring(v), 2)
						end
						obj[k.__eventname]:connect(v)
					elseif k == t.Create then
						if type(v) ~= 'function' then
							error("Bad entry in Create body: Key `[Create]` should be paired with a constructor function, \
								got: "..tostring(v), 2)
						elseif ctor then
							error("Bad entry in Create body: Only one constructor function is allowed", 2)
						end
		
						ctor = v
					else
						error("Bad entry ("..tostring(k).." => "..tostring(v)..") in Create body", 2)
					end
				end
				if ctor then
					ctor(obj)
				end
		
				if parent then
					obj.Parent = parent
				end
				return obj
			end
		end
		t.Create = setmetatable({}, {__call = function(tb, ...) return Create_PrivImpl(...) end})
		t.Create.E = function(eventName)
			return {__eventname = eventName}
		end
		t.Help =
		function(funcNameOrFunc)
		if funcNameOrFunc == "DecodeJSON" or funcNameOrFunc == t.DecodeJSON then
		return "Function DecodeJSON. "
		end
		if funcNameOrFunc == "EncodeJSON" or funcNameOrFunc == t.EncodeJSON then
		return "Function EncodeJSON. "
		end
		if funcNameOrFunc == "MakeWedge" or funcNameOrFunc == t.MakeWedge then
		return "Function MakeWedge. " 
		end
		if funcNameOrFunc == "SelectTerrainRegion" or funcNameOrFunc == t.SelectTerrainRegion then
		return "Function SelectTerrainRegion. " 
		end
		if funcNameOrFunc == "CreateSignal" or funcNameOrFunc == t.CreateSignal then
		return "Function CreateSignal. "
		end
		if funcNameOrFunc == "Signal:connect" then
		return "Method Signal:connect. "
		end
		if funcNameOrFunc == "Signal:wait" then
		return "Method Signal:wait. "
		end
		if funcNameOrFunc == "Signal:fire" then
		return "Method Signal:fire. "
		end
		if funcNameOrFunc == "Signal:disconnect" then
		return "Method Signal:disconnect. "
		end
		if funcNameOrFunc == "Create" then
		return "Function Create. "
		end
		end
		return t
end		

Global.MessageBox = function(message)
	StarterGui:SetCore("SendNotification", {
		Title = message[1],
		Text = message[2],
		Duration = message[3],
	})
end

Global.GelatekRig = nil
Global.ScriptRunning = false
Global.rbx_signals    =  {} -- roblox signals stored in table for easy removal       
Global.Kades_Stuff = {
	-- Reanim Settings...

	DedPoint = false,
	NCollide = false,
	Flinging = false,
	FastLoad = false,
	Limbs = {    -- hats used for limbs replacement for the rig  (default hats below)
		["Right Arm"] = { -- Right Arm
			name = "RARM",
			texture = "rbxassetid://14255544465",
			mesh = "rbxassetid://14255522247",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Right Arm

		["Left Arm"] = { -- Left Arm
			name = "LARM",
			texture = "rbxassetid://14255544465", 
			mesh = "rbxassetid://14255522247",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Left Arm

		["Right Leg"] = { -- Right Leg
			name = "Accessory (RARM)",
			texture = "rbxassetid://17374768001", 
			mesh = "rbxassetid://17374767929",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Right Leg

		["Left Leg"] = { -- Left Leg
			name = "Accessory (LARM)",
			texture = "rbxassetid://17374768001", 
			mesh = "rbxassetid://17374767929",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Left Leg

		["Torso"] = { -- Torso
			name = "MeshPartAccessory",
			texture = "rbxassetid://13415110780", 
			mesh = "rbxassetid://13421774668",
			offset = cf_zero
		}, -- Torso
	}
}


local BaseTweenInf = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local InstanceNew = Instance.new
local UDim2New = UDim2.new
local Color3RGB = Color3.fromRGB
local AlignTextL = Enum.TextXAlignment.Left
local AnchorCentre = Vector2.new(0.5,0.5)
local Gotham = Enum.Font.Gotham
local PureBlack = Color3RGB(0,0,0)
local PureWhite = Color3RGB(255,255,255)
local FalseButton = Color3RGB(204, 107, 107)
local TrueButton = Color3RGB(120, 204, 107)
local Library = {}

Global.Reanimation = function()
	--[[ Kade's Reanimate | @xyzkade | https://discord.gg/g2Txp9VRAJvc/ | V: 1.0.1 ]] --
	local global      = getfenv(0).xyzkade
	local config      = global.Kades_Stuff
	global.Rig        = nil

	local no_collisions = config.NCollide  -- basically noclip for the fakerig
	local flinging      = config.Flinging -- uses your real char as a fling, will delay slightly autorespawning
	local tpless        = config.FastLoad  -- wont tp your character. resets instantly. might be unstable.
	local deathpoint    = config.DedPoint   -- tps you back to the same place when you stopped the reanimate
	local limbs         = config.limbs or {       -- hats used for limbs replacement for the rig  (default hats below)
		["Right Arm"] = { -- Right Arm
			name = "RARM",
			texture = "rbxassetid://14255544465",
			mesh = "rbxassetid://14255522247",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Right Arm
	
		["Left Arm"] = { -- Left Arm
			name = "LARM",
			texture = "rbxassetid://14255544465",
			mesh = "rbxassetid://14255522247",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Left Arm

		["Right Leg"] = { -- Right Leg
			name = "Accessory (RARM)",
			texture = "rbxassetid://17374768001",
			mesh = "rbxassetid://17374767929",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Right Leg

		["Left Leg"] = { -- Left Leg
			name = "Accessory (LARM)",
			texture = "rbxassetid://17374768001",
			mesh = "rbxassetid://17374767929",
			offset = cf_angle(0, 0, mt_rad(90))
		}, -- Left Leg

		["Torso"] = { -- Torso
			name = "MeshPartAccessory",
			texture = "rbxassetid://13415110780",
			mesh = "rbxassetid://13421774668",
			offset = cf_zero
		}, -- Torso
	}

	local enum_keycode   = Enum.KeyCode
	local enum_humstate  = Enum.HumanoidStateType
	local enum_userinput = Enum.UserInputType

	local move_part     = in_new("Part")
	local is_mouse_down = false

	local wasd          = {"w", "a", "s", "d"}
	local keys_list     = {w = enum_keycode.W, a = enum_keycode.A, s = enum_keycode.S, d = enum_keycode.D, space = enum_keycode.Space}
	local key_values    = {w = {0, 1e4}, a = {1e4,0}, s = {0,-1e4}, d = {-1e4,0}}
	local key_pressed   = {w = false, a = false, s = false, d = false, space = false}

	local state_dead    = enum_humstate.Dead
	local state_getup   = enum_humstate.GettingUp
	local state_landed  = enum_humstate.Landed

	local clonereference       = cloneref or function(x) return x end -- security
	local return_network_owner = isnetworkowner or function(part) return part.ReceiveAge == 0 end -- get parts owner

	-- :: Begin

	-- ; Script Variables
	local respawning     =  false -- checks if player is about to respawn
	local radiuscheck    =  v3_new(12, 12, 12) -- radius to keep real rig's away from players 
	local no_sleep_cf    =  cf_zero -- makes parts always in move so they will never sleep.
	local high_vel       =  v3_new(16384,16384,16384) -- flinging velocity
	local sin_value      =  0  -- random value, needed for dynamical velocity                                               {event, event, ...}
	local hats           =  {} -- Hats that need for the rig to work, such as extra limb accessory.                                    {handle, part1, cframe}
	local reset_bind     =  in_new("BindableEvent") -- bindable event for disabling the script.
	local mousebutton1   =  enum_userinput.MouseButton1

	-- ; Datamodel Variables

	local workspace  = clonereference(game:FindFirstChildOfClass("Workspace"))
	local players    = clonereference(game:FindFirstChildOfClass("Players"))
	local runservice = clonereference(game:FindFirstChildOfClass("RunService"))
	local startgui   = clonereference(game:FindFirstChildOfClass("StarterGui"))
	local inputserv  = clonereference(game:FindFirstChildOfClass("UserInputService"))

	global.rbx_signals[#global.rbx_signals+1] = inputserv.InputBegan:Connect(function(input, out_of_focus)
		for i, v in next, keys_list do
			if not out_of_focus and input.KeyCode == v then
				key_pressed[i] = true
			end
		end

		if input.UserInputType == mousebutton1 then
			is_mouse_down = true
		end
	end)

	global.rbx_signals[#global.rbx_signals+1] = inputserv.InputEnded:Connect(function(input) -- not needed
		for i, v in next, keys_list do
			if input.KeyCode == v then
				key_pressed[i] = false
			end
		end

		if input.UserInputType == mousebutton1 then
			is_mouse_down = false
		end
	end)

	-- ; Starting Functions

	local function disable_localscripts(descendants_table)
		for i=1,#descendants_table do
			local localscript = descendants_table[i]
	
			if localscript:IsA("LocalScript") then
				localscript.Disabled = true
			end
		end
	end

	local function call_move_part(humanoid, positions)        -- calls moving on a humanoid
		local x, z = positions[1], positions[2]
		move_part.CFrame = move_part.CFrame * cf_new(-x, 0,-z)

		humanoid.WalkToPoint = move_part.Position
	end

	local function ffcoc_and_name(parent, classname, name)     -- findfirstchildofclass with name check
		local list = parent:GetDescendants()
		for i=1,#list do
			local x = list[i]
			
			if x.Name == name and x:IsA(classname) then
				return x
			end
		end

		return nil
	end

	local function wait_for_child_of_class(parent, classname, timeout, name)     -- waitforchildofclass, nothing else to add, 4th arg is name check
		local check        = name and true
		local time         = timeout or 1
		local timed_out    = false
		local return_value = nil

		ts_delay(time, function()
			if not ffcoc_and_name(parent, classname, name) then
				timed_out = true
			end
		end)

		repeat ts_wait() until timed_out or check and ffcoc_and_name(parent, classname, name) or parent:FindFirstChildOfClass(classname)
		return_value = check and ffcoc_and_name(parent, classname, name) or parent:FindFirstChildOfClass(classname)

		return return_value
	end

	local function check_matching_hatdata(handle, v_name, v_mesh_id, v_texture_id) -- checks if provided values match the handle's values.
		local texture_id  = nil
		local mesh_id     = nil
		local name        = nil
		local parent      = handle.Parent

		if handle:IsA("MeshPart") then -- i geniuelly hope the roblox staff fucking dies
			texture_id  = handle.TextureID 
			mesh_id     = handle.MeshId
		elseif handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh") then
			local mesh = handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh")

			texture_id  = mesh.TextureId
			mesh_id     = mesh.MeshId
		end

		name = parent and parent.Name or ""
		if v_name == name and v_mesh_id == mesh_id and v_texture_id == texture_id then
			return true
		end

		return false
	end

	local function find_accessory(descendants_table, name, mesh_id, texture_id)  -- returns a handle if found in the descendant of a model.
		for i = 1,#descendants_table do
			local handle = descendants_table[i]
			if handle.Name == "Handle" and check_matching_hatdata(handle, name, mesh_id, texture_id) then
				return handle
			end
		end
	end

	local function disconnect_all_events(table)                            -- disconnects all the events from the weld
		for _,v in next, table do
			v:Disconnect()
		end
	end

	local function recreate_accessory_and_joints(model, descendants_table) -- Recreates hats to the rig and reconfigures their weld.
		local model_descendants = model:GetDescendants()
		local head = model:WaitForChild("Head")

		for i = 1,#model_descendants do
			local Accessory = model_descendants[i]

			if Accessory:IsA("Accessory") then
				Accessory:Destroy()
			end
		end

		for i = 1,#descendants_table do
			local accessory   = descendants_table[i]

			if accessory:IsA("Accessory") then
				local handle = wait_for_child_of_class(accessory, "BasePart", 1, "Handle")
				local handle_weld = wait_for_child_of_class(handle, "Weld", 1)
				local previous_weld_data = {handle_weld.C0 or cf_zero, handle_weld.C1 or cf_zero, handle_weld.Part1}
				
				handle_weld:Destroy()

				local fake_accessory = accessory:Clone()
				local fake_handle = wait_for_child_of_class(fake_accessory, "BasePart", 1, "Handle")

				local attachment = wait_for_child_of_class(fake_handle, "Attachment")
				local weld = in_new("Weld")

				if (not previous_weld_data[3]) or (previous_weld_data[3] and previous_weld_data[3].Name ~= "Head") then
					if attachment then
						weld.C0    = attachment.CFrame
						weld.C1    = model:FindFirstChild(tostring(attachment), true).CFrame
						weld.Part1 = model:FindFirstChild(tostring(attachment), true).Parent
					else
						weld.Part1 = head
						weld.C1    = cf_new(0, head.Size.Y / 2, 0) * fake_accessory.AttachmentPoint:Inverse()
					end
				elseif previous_weld_data[3] and previous_weld_data[3].Name == "Head" then
					weld.C0    = previous_weld_data[1]
					weld.C1    = previous_weld_data[2]
					weld.Part1 = head
				end

				fake_handle.Transparency = 1
				fake_handle.CFrame = weld.Part1.CFrame * weld.C1 * weld.C0:Inverse()

				weld.Name     = "AccessoryWeld"
				weld.Part0    = fake_handle
				weld.Parent   = fake_handle

				fake_accessory.Parent = model
			end
		end
	end

	local function write_hats_to_table(descendants_table, fake_descendants_table, fake_model)       -- adds hats for alignment, and tweaks them ( hats )
		for i = 1,#descendants_table do
			local handle = descendants_table[i]

			if handle.Name == "Handle" then
				handle.Massless = false

				local texture_id  = nil
				local mesh_id     = nil --mesh.MeshId

				if handle:IsA("MeshPart") then
					texture_id  = handle.TextureID --or mesh.TextureId
					mesh_id     = handle.MeshId
				elseif handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh") then
					local mesh = handle:FindFirstChildOfClass("Mesh") or handle:FindFirstChildOfClass("SpecialMesh")
			
					texture_id  = mesh.TextureId
					mesh_id     = mesh.MeshId
				end
			

				local fake_handle = find_accessory(fake_descendants_table, handle.Parent.Name, mesh_id, texture_id)

				for name, values in next, limbs do
					local found_part = fake_model:WaitForChild(name)
					local found_part_name = found_part.Name

					if fake_model:FindFirstChild(name) and check_matching_hatdata(handle, values.name, values.mesh, values.texture) then
						hats[#hats+1] = {handle, fake_model:FindFirstChild(found_part_name), values.offset}
						if fake_handle then
							fake_handle:Destroy()
						end
					end
				end

				
				if fake_handle then
					hats[#hats+1] = {handle, fake_handle}
				end
			end
		end
	end

	local function cframe_link_parts(part0, part1, offset)                  -- connects part0 to part1
		if part0 and part0.Parent and part1 and part1.Parent then
			local part0_mass               = part1.Mass * 5
			part0.AssemblyLinearVelocity   = v3_new(part1.AssemblyLinearVelocity.X * part0_mass, sin_value, part1.AssemblyLinearVelocity.Z * part0_mass)
			part0.AssemblyAngularVelocity  = part1.AssemblyAngularVelocity

			if return_network_owner(part0) then
				part0.CFrame = part1.CFrame * offset
			end
		end
	end

	local function are_players_near(cframe)                                 -- checks if players are near the tp location.
		local position = cframe.Position
		local radius = radiuscheck / 2

		local check_region = r3_new(position - radius, position + radius)
		local parts_in_way = workspace:FindPartsInRegion3(check_region, nil, math.huge)

		for i=1,#parts_in_way do
			local model = parts_in_way[i].Parent

			if model:IsA("Model") and model.PrimaryPart ~= nil then
				return true
			end
		end

		return false
	end

	-- ; Variables

	local pre_sim     = runservice.PreSimulation
	local post_sim    = runservice.PostSimulation
	local is_mobile   = inputserv.TouchEnabled
	local camera      = workspace.CurrentCamera
	local destroy_h   = workspace.FallenPartsDestroyHeight
	local spawnpoint  = wait_for_child_of_class(workspace, "SpawnLocation", 1)

	local player      = players.LocalPlayer
	local mouse       = player:GetMouse()
	local character   = player.Character
	local descendants = character:GetDescendants()

	-- ; Character Variables

	local hrp        = wait_for_child_of_class(character, "BasePart", 5, "HumanoidRootPart")
	local humanoid   = wait_for_child_of_class(character, "Humanoid", 5)

	if not humanoid and hrp then
		return nil -- No Humanoid and HumanoidRootPart
	end

	-- ; Rig

	local return_cf  = spawnpoint and spawnpoint.CFrame * cf_new(0,20,0) or hrp.CFrame
	local rig_hrp, rig_hum, rig_descendants

	local rig = in_new("Model"); do -- Scoping to make it look nice.
		rig_hum  = in_new("Humanoid")
		local hum_desc = in_new("HumanoidDescription")
		local animator = in_new("Animator")

		local function makejoint(name, part0, part1, c0, c1)
			local joint  = in_new("Motor6D")

			joint.Name   = name
			joint.Part0  = part0
			joint.Part1  = part1
			joint.C0     = c0
			joint.C1     = c1

			joint.Parent = part0

			return joint
		end
		
		local function makeattachment(name, cframe, parent)
			local attachment  = in_new("Attachment")

			attachment.Name   = name
			attachment.CFrame = cframe

			attachment.Parent = parent
		end

		local head      = in_new("Part")
		local torso     = in_new("Part")
		local right_arm = in_new("Part")

		head.Size       = v3_new(2,1,1)
		torso.Size      = v3_new(2,2,1)
		right_arm.Size  = v3_new(1,2,1)

		head.Transparency      = 1
		torso.Transparency     = 1
		right_arm.Transparency = 1

		rig_hrp  = torso:Clone()
		rig_hrp.CanCollide = false

		local left_arm  = right_arm:Clone()
		local right_leg = right_arm:Clone()
		local left_leg  = right_arm:Clone()

		rig_hrp.Name   = "HumanoidRootPart"
		torso.Name     = "Torso"
		head.Name      = "Head"
		right_arm.Name = "Right Arm"
		left_arm.Name  = "Left Arm"
		right_leg.Name = "Right Leg"
		left_leg.Name  = "Left Leg"

		animator.Parent  = rig_hum
		hum_desc.Parent  = rig_hum

		rig_hum.Parent   = rig
		rig_hrp.Parent   = rig
		head.Parent      = rig
		torso.Parent     = rig
		right_arm.Parent = rig
		left_arm.Parent  = rig
		right_leg.Parent = rig
		left_leg.Parent  = rig
		rig_hum.Parent   = rig

		local nk = makejoint('Neck',           torso,    head,       cf_new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),    cf_new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
		local rj = makejoint('RootJoint',      rig_hrp,  torso,      cf_new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),    cf_new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))
		local rs = makejoint('Right Shoulder', torso,    right_arm,  cf_new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),  cf_new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
		local ls = makejoint('Left Shoulder',  torso,    left_arm,   cf_new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),  cf_new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
		local rh = makejoint('Right Hip',      torso,    right_leg,  cf_new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),   cf_new(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))
		local lh = makejoint('Left Hip',       torso,    left_leg,   cf_new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),   cf_new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

		makeattachment("HairAttachment",          cf_new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      head)
		makeattachment("HatAttachment",           cf_new(0, 0.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      head)
		makeattachment("FaceFrontAttachment",     cf_new(0, 0, -0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1),     head)
		makeattachment("RootAttachment",          cf_new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),     rig_hrp)
		makeattachment("LeftShoulderAttachment",  cf_new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),    left_arm)
		makeattachment("LeftGripAttachment",      cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),   left_arm)
		makeattachment("RightShoulderAttachment", cf_new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),   right_arm)
		makeattachment("RightGripAttachment",     cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),  right_arm)
		makeattachment("LeftFootAttachment",      cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),   left_leg)	
		makeattachment("RightFootAttachment",     cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),  right_leg)
		makeattachment("NeckAttachment",          cf_new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),       torso)
		makeattachment("BodyFrontAttachment",     cf_new(0, 0, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),    torso)
		makeattachment("BodyBackAttachment",      cf_new(0, 0, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),     torso)
		makeattachment("LeftCollarAttachment",    cf_new(-1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      torso)
		makeattachment("RightCollarAttachment",   cf_new(1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),       torso)
		makeattachment("WaistFrontAttachment",    cf_new(0, -1, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),   torso)
		makeattachment("WaistCenterAttachment",   cf_new(0, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),      torso)
		makeattachment("WaistBackAttachment",     cf_new(0, -1, 0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),    torso)
		
		recreate_accessory_and_joints(rig, descendants)

		-- Clientsided parts

		move_part.Transparency = 1
		move_part.CanCollide   = false
		move_part.Parent       = rig
		
		rig_descendants = rig:GetDescendants()
		rig_hrp.CFrame  = hrp.CFrame * cf_new(0, 0, 2)
		rig.Name        = "FakeRig"
		rig.Parent      = workspace
	end

	-- :: Functions

	local is_flinging   = false
	local targets_fling = {}
	global.send_the_fling = function(model)
		if flinging and not is_flinging and model and hrp and hrp:IsDescendantOf(workspace) then
			local p_part = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildOfClass("Part")
			local huma = wait_for_child_of_class(model, "Humanoid", 2, "Humanoid")
			targets_fling[#targets_fling+1]={p_part, huma}
			repeat ts_wait() until respawning
		
			is_flinging = true
			for _,x in next, targets_fling do
				local move_dir  = x[2].MoveDirection
				local walkspeed = x[2].WalkSpeed/6
				for i=0,35 do
					hrp.AssemblyLinearVelocity = high_vel
					hrp.AssemblyAngularVelocity = v3_zero
					hrp.CFrame = x[1].CFrame * cf_new(x[1].AssemblyLinearVelocity/walkspeed)
					
					ts_wait()
				end
			end

			ts_wait()
			
			hrp.AssemblyAngularVelocity = v3_zero
			hrp.AssemblyLinearVelocity = v3_zero
			hrp.CFrame = rig_hrp.CFrame
			
			ts_wait(0.15)

			is_flinging = false
			tb_clear(targets_fling)
		end
	end

	local function set_camera_target()  -- Fixes cameras.
		local old_cam_cf = camera.CFrame
		camera.CameraSubject = rig_hum
		camera:GetPropertyChangedSignal("CFrame"):Once(function()
			camera.CFrame = old_cam_cf
		end)
	end

	local function characteradded_event() -- Automatically respawns the player.
		respawning = true
		local old_cam_cf = camera.CFrame
		camera.CameraSubject = rig_hum

		camera:GetPropertyChangedSignal("CFrame"):Wait()
		camera.CFrame = old_cam_cf

		character  = player.Character
		hrp        = wait_for_child_of_class(character, "BasePart", 5, "HumanoidRootPart")
		humanoid   = wait_for_child_of_class(character, "Humanoid")

		set_camera_target()

		local tp_offset = rig_hrp.CFrame * cf_new(mt_random(-26, 26), 0.25, mt_random(-26, 26))
		
		while are_players_near(tp_offset) do
			tp_offset = rig_hrp.CFrame * cf_new(mt_random(-26, 26), 0, mt_random(-26, 26))
			ts_wait()
		end
		
		if is_flinging then
			repeat ts_wait() until is_flinging == false
		end

		hrp.CFrame = tp_offset
		
		if not tpless then
			ts_wait(0.26)
		end
		
		respawning = false
		descendants = character:GetDescendants()
		disable_localscripts(descendants)

		tb_clear(hats)
		recreate_accessory_and_joints(rig, descendants)

		rig_descendants = rig:GetDescendants()

		humanoid:ChangeState(state_dead)
		character:BreakJoints()

		write_hats_to_table(descendants, rig_descendants, rig)
	end

	local function postsimulation_event() -- Hat System.
		player.MaximumSimulationRadius = 32768
		player.SimulationRadius        = 32768

		for _, data in next, hats do
			local handle = data[1]
			local part1  = data[2]
			local offset = data[3] or cf_zero
			
			cframe_link_parts(handle, part1, offset * no_sleep_cf)
		end

		for _, part in next, descendants do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
			end
		end
	end

	local function presimulation_event() -- Movement temporary.
		if no_collisions then
			for i=1,#rig_descendants do
				local part = rig_descendants[i]
				
				if part and part.Parent and part:IsA("BasePart") then
					part.CanCollide = false
					part.CanTouch   = false
					part.CanQuery   = false
				end
			end
		end

		no_sleep_cf = cf_new(0.01 * mt_sin(os_clock()*16), 0, 0.01 * mt_cos(os_clock()*16))
		sin_value = 40 - 3 * mt_sin(os_clock()*10)
	end

	local function disable_script(forced_deathpoint) -- Disables the script.
		local rigcf = rig_hrp.CFrame

		disconnect_all_events(global.rbx_signals)

		rig:Destroy()
		reset_bind:Destroy()

		player.Character = character
		camera.CameraSubject = humanoid
		global.GelatekRig = nil
		global.ScriptRunning = false

		startgui:SetCore("ResetButtonCallback", true)
		camera:GetPropertyChangedSignal("CFrame"):Wait()
		camera.CameraSubject = player.Character

		if forced_deathpoint or deathpoint then
			player.CharacterAdded:Wait()
			ts_wait()

			hrp        = wait_for_child_of_class(player.Character, "BasePart", 5, "HumanoidRootPart")
			hrp.CFrame = rigcf
		end
	end

	local function move_rig_humanoid()  -- Makes the rig move.
		local look_vector = camera.CFrame.lookVector

		for _, key in next, wasd do
			if key_pressed[key] then
				call_move_part(rig_hum, key_values[key])
			end
		end

		move_part.Position = rig_hrp.Position
		move_part.CFrame = cf_new(move_part.Position, v3_new(look_vector.X * 9999, look_vector.Y, look_vector.Z * 9999))

		if key_pressed["space"] then rig_hum.Jump = true end

		local movement_keys_pressed = key_pressed["w"] or key_pressed["a"] or key_pressed["s"] or key_pressed["d"]
		if not movement_keys_pressed then
			rig_hum.WalkToPoint = rig_hrp.Position
		end

		if is_mobile then -- temporary solution.
			rig_hum.Jump = humanoid.Jump
			rig_hum:Move(humanoid.MoveDirection, false)
		end
	end

	-- :: Finishing

	-- Binding Functions To Signals

	humanoid:ChangeState(state_dead)
	character:BreakJoints()

	global.rbx_signals[#global.rbx_signals+1] = player.CharacterAdded:Connect(characteradded_event)
	global.rbx_signals[#global.rbx_signals+1] = reset_bind.Event:Connect(disable_script)
	global.rbx_signals[#global.rbx_signals+1] = rig:GetPropertyChangedSignal("Parent"):Once(disable_script)
	global.rbx_signals[#global.rbx_signals+1] = rig_hrp:GetPropertyChangedSignal("Parent"):Once(disable_script)
	global.rbx_signals[#global.rbx_signals+1] = camera:GetPropertyChangedSignal("CameraSubject"):Connect(set_camera_target)
	global.rbx_signals[#global.rbx_signals+1] = pre_sim:Connect(presimulation_event)
	global.rbx_signals[#global.rbx_signals+1] = post_sim:Connect(postsimulation_event)
	global.rbx_signals[#global.rbx_signals+1] = post_sim:Connect(move_rig_humanoid)

	startgui:SetCore("ResetButtonCallback", reset_bind)

	-- Starting.

	set_camera_target()
	write_hats_to_table(descendants, rig_descendants, rig)

	rig_hum:ChangeState(state_getup)
	rig_hum:ChangeState(state_landed)
	global.GelatekRig = rig
	return {rig, disable_script}
end

Global.CreateFrame = function()
	local KadesScreenGui = InstanceNew("ScreenGui")
	local GelatekHub = InstanceNew("Frame")
	local UICorner = InstanceNew("UICorner")
	local Decoration = InstanceNew("Folder")
	local MainTitle = InstanceNew("TextLabel")
	local Kade = InstanceNew("TextLabel")
	local KadeSize = InstanceNew("UITextSizeConstraint")
	local LineDecor = InstanceNew("Frame")
	local CloseButton = InstanceNew("ImageButton")
	local Shadow = InstanceNew("ImageLabel")
	local TopBar = InstanceNew("Folder")
	local Reanimate = InstanceNew("TextButton")
	local ReanimateCorner = InstanceNew("UICorner")
	local Flinging = InstanceNew("TextButton")
	local FastLoad = InstanceNew("TextButton")
	local Noclip = InstanceNew("TextButton")
	local Deadpoint = InstanceNew("TextButton")
	local Scripts = InstanceNew("ScrollingFrame")
	local ScriptsGrid = InstanceNew("UIGridLayout")
	local BottomBar = InstanceNew("Frame")
	local BottomCorner = InstanceNew("UICorner")
	local StopScript = InstanceNew("TextButton")
	local SeperatorBottom = InstanceNew("TextButton")
	local AnimIdPlayer = InstanceNew("TextBox")
	local silly_car = InstanceNew("TextLabel")
	local SettingButtons = {Deadpoint, Noclip, Flinging, FastLoad}
	
	KadesScreenGui.Name = "KadesScreenGui"
	KadesScreenGui.Parent = game.CoreGui
	GelatekHub.Name = "Gelatek Hub"
	GelatekHub.Parent = KadesScreenGui
	GelatekHub.AnchorPoint = AnchorCentre
	GelatekHub.BackgroundColor3 = Color3RGB(45, 45, 45)
	GelatekHub.BorderColor3 =  PureBlack
	GelatekHub.BorderSizePixel = 0
	GelatekHub.Position = UDim2New(0.549342155, 0, 0.527777791, 0)
	GelatekHub.Size = UDim2New(0, 448, 0, 303)

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = GelatekHub

	Decoration.Name = "Decoration"
	Decoration.Parent = GelatekHub

	MainTitle.Name = "MainTitle"
	MainTitle.Parent = Decoration
	MainTitle.BackgroundColor3 =PureWhite
	MainTitle.BackgroundTransparency = 1.000
	MainTitle.BorderColor3 =  PureBlack
	MainTitle.BorderSizePixel = 0
	MainTitle.Position = UDim2New(0, 7, 0, 0)
	MainTitle.Size = UDim2New(0.209821433, 0, 0.0858085826, 0)
	MainTitle.Font = Gotham
	MainTitle.Text = "Gelatek Hub"
	MainTitle.TextColor3 = Color3RGB(182, 255, 155)
	MainTitle.TextSize = 12.000
	MainTitle.TextXAlignment = AlignTextL

	Kade.Name = "Kade"
	Kade.Parent = MainTitle
	Kade.BackgroundColor3 =PureWhite
	Kade.BackgroundTransparency = 1.000
	Kade.BorderColor3 = PureBlack
	Kade.BorderSizePixel = 0
	Kade.Position = UDim2New(1.88297868, 0, 0, 0)
	Kade.Size = UDim2New(0.765957475, 0, 1, 0)
	Kade.Font = Gotham
	Kade.Text = "@xyzkade"
	Kade.TextColor3 = Color3RGB(204, 204, 204)
	Kade.TextScaled = true
	Kade.TextSize = 12.000
	Kade.TextTransparency = 0.500
	Kade.TextWrapped = true

	KadeSize.Name = "KadeSize"
	KadeSize.Parent = Kade
	KadeSize.MaxTextSize = 12

	LineDecor.Name = "LineDecor"
	LineDecor.Parent = Decoration
	LineDecor.BackgroundColor3 = Color3RGB(53, 53, 53)
	LineDecor.BorderColor3 =  PureBlack
	LineDecor.BorderSizePixel = 0
	LineDecor.Position = UDim2New(0, 0, 0.0885713771, 0)
	LineDecor.Size = UDim2New(0, 447, 0, 1)

	CloseButton.Name = "CloseButton"
	CloseButton.Parent = Decoration
	CloseButton.BackgroundColor3 =PureWhite
	CloseButton.BackgroundTransparency = 1.000
	CloseButton.BorderColor3 =  PureBlack
	CloseButton.BorderSizePixel = 0
	CloseButton.Position = UDim2New(0.949999988, 0, 0.0189999994, 0)
	CloseButton.Size = UDim2New(0, 14, 0, 14)
	CloseButton.Image = "rbxasset://textures/StudioSharedUI/close.png"
	CloseButton.ImageTransparency = 0.200
	CloseButton.MouseButton1Click:Once(function()
		KadesScreenGui:Destroy()
	end)
	Shadow.Name = "Shadow"
	Shadow.Parent = Decoration
	Shadow.AnchorPoint = AnchorCentre
	Shadow.BackgroundColor3 = PureWhite
	Shadow.BackgroundTransparency = 1.000
	Shadow.BorderColor3 =  PureBlack
	Shadow.BorderSizePixel = 0
	Shadow.Position = UDim2New(0.49953723, 0, 0.49995926, 0)
	Shadow.Size = UDim2New(1.10842884, 0, 1.10823059, 0)
	Shadow.ZIndex = -2
	Shadow.Image = "rbxassetid://5554236805"
	Shadow.ImageColor3 =  PureBlack

	TopBar.Name = "TopBar"
	TopBar.Parent = GelatekHub

	Reanimate.Name = "Reanimate"
	Reanimate.Parent = TopBar
	Reanimate.BackgroundColor3 = Color3RGB(54, 54, 54)
	Reanimate.BorderColor3 =  PureBlack
	Reanimate.BorderSizePixel = 0
	Reanimate.Position = UDim2New(0.0170000624, 0, 0.114709534, 0)
	Reanimate.Size = UDim2New(0, 77, 0, 21)
	Reanimate.Font = Gotham
	Reanimate.Text = "Reanimate"
	Reanimate.TextColor3 = Color3RGB(204, 201, 201)
	Reanimate.TextSize = 12.000

	ReanimateCorner.CornerRadius = UDim.new(0, 4)
	ReanimateCorner.Name = "ReanimateCorner"
	ReanimateCorner.Parent = Reanimate

	Flinging.Name = "Flinging"
	Flinging.Parent = TopBar
	Flinging.BackgroundTransparency = 1.000
	Flinging.BorderColor3 =  PureBlack
	Flinging.BorderSizePixel = 0
	Flinging.Position = UDim2New(0.867346108, 0, 0.114709534, 0)
	Flinging.Size = UDim2New(0, 51, 0, 21)
	Flinging.Font = Gotham
	Flinging.Text = "Flinging"
	Flinging.TextColor3 = Color3RGB(204, 107, 107)
	Flinging.TextSize = 12.000

	FastLoad.Name = "FastLoad"
	FastLoad.Parent = TopBar
	FastLoad.BackgroundTransparency = 1.000
	FastLoad.BorderColor3 =  PureBlack
	FastLoad.BorderSizePixel = 0
	FastLoad.Position = UDim2New(0.481185645, 0, 0.114709534, 0)
	FastLoad.Size = UDim2New(0, 90, 0, 21)
	FastLoad.Font = Gotham
	FastLoad.Text = " Fast Loading"
	FastLoad.TextColor3 = Color3RGB(204, 107, 107)
	FastLoad.TextSize = 12.000

	Noclip.Name = "Noclip"
	Noclip.Parent = TopBar
	Noclip.BackgroundTransparency = 1.000
	Noclip.BorderColor3 =  PureBlack
	Noclip.BorderSizePixel = 0
	Noclip.Position = UDim2New(0.682079017, 0, 0.114709534, 0)
	Noclip.Size = UDim2New(0, 82, 0, 21)
	Noclip.Font = Gotham
	Noclip.Text = "No Collisions"
	Noclip.TextColor3 = Color3RGB(204, 107, 107)
	Noclip.TextSize = 12.000

	Deadpoint.Name = "Deadpoint"
	Deadpoint.Parent = TopBar
	Deadpoint.BackgroundTransparency = 1.000
	Deadpoint.BorderColor3 =  PureBlack
	Deadpoint.BorderSizePixel = 0
	Deadpoint.Position = UDim2New(0.22895363, 0, 0.114709534, 0)
	Deadpoint.Size = UDim2New(0, 113, 0, 21)
	Deadpoint.Font = Gotham
	Deadpoint.Text = "Deadpoint Return"
	Deadpoint.TextColor3 = Color3RGB(204, 107, 107)
	Deadpoint.TextSize = 12.000

	Scripts.Name = "Scripts"
	Scripts.Parent = GelatekHub
	Scripts.Active = true
	Scripts.BackgroundColor3 =PureWhite
	Scripts.BackgroundTransparency = 1.000
	Scripts.BorderColor3 =  PureBlack
	Scripts.BorderSizePixel = 0
	Scripts.Position = UDim2New(0.0170000624, 0, 0.213719338, 0)
	Scripts.Size = UDim2New(0, 431, 0, 215)
	Scripts.ScrollBarImageTransparency = 1
	Scripts.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scripts.CanvasSize = UDim2New(0,0,0,0)
	Scripts.ScrollBarThickness = 1
	
	local AddScript = function(Name, CreditsText, Callback)
		local ScriptButton = InstanceNew("TextButton")
		local ScriptCorner = InstanceNew("UICorner")
		local Title = InstanceNew("TextLabel")
		local Credits = InstanceNew("TextLabel")
		
		ScriptButton.Name = Name
		ScriptButton.Parent = Scripts
		ScriptButton.BackgroundColor3 = Color3RGB(54, 54, 54)
		ScriptButton.BorderColor3 =  PureBlack
		ScriptButton.BorderSizePixel = 0
		ScriptButton.Position = UDim2New(0.00221624179, 0, 0, 0)
		ScriptButton.Size = UDim2New(0, 429, 0, 30)
		ScriptButton.Font = Enum.Font.SourceSans
		ScriptButton.Text = " "
		ScriptButton.TextColor3 = PureBlack
		ScriptButton.TextSize = 14.000

		ScriptCorner.CornerRadius = UDim.new(0, 2)
		ScriptCorner.Name = "ScriptCorner"
		ScriptCorner.Parent = ScriptButton
		
		Title.Name = "Title"
		Title.Parent = ScriptButton
		Title.BackgroundColor3 = Color3RGB(54, 54, 54)
		Title.BackgroundTransparency = 1.000
		Title.BorderColor3 =  PureBlack
		Title.BorderSizePixel = 0
		Title.Position = UDim2New(0.0186057873, 0, 0, 0)
		Title.Size = UDim2New(0.583615541, 0, 1, 0)
		Title.Font = Gotham
		Title.Text = Name
		Title.TextColor3 = Color3RGB(204, 204, 204)
		Title.TextSize = 12.000
		Title.TextXAlignment = AlignTextL

		Credits.Name = "Credits"
		Credits.Parent = ScriptButton
		Credits.BackgroundColor3 = Color3RGB(54, 54, 54)
		Credits.BackgroundTransparency = 1.000
		Credits.BorderColor3 =  PureBlack
		Credits.BorderSizePixel = 0
		Credits.Position = UDim2New(0.41152373, 0, 0, 0)
		Credits.Size = UDim2New(0.560532093, 0, 1, 0)
		Credits.Font = Gotham
		Credits.Text = "\\\\ "..CreditsText
		Credits.TextColor3 = Color3RGB(117, 117, 117)
		Credits.TextSize = 12.000
		Credits.TextXAlignment = Enum.TextXAlignment.Right
		
		ScriptButton.MouseButton1Down:Connect(Callback)
	end

	ScriptsGrid.Name = "ScriptsGrid"
	ScriptsGrid.Parent = Scripts
	ScriptsGrid.SortOrder = Enum.SortOrder.LayoutOrder
	ScriptsGrid.CellSize = UDim2New(0, 430, 0, 30)

	BottomBar.Name = "BottomBar"
	BottomBar.Parent = GelatekHub
	BottomBar.BackgroundColor3 = Color3RGB(77, 118, 97)
	BottomBar.BackgroundTransparency = 0.500
	BottomBar.BorderColor3 =  PureBlack
	BottomBar.BorderSizePixel = 0
	BottomBar.Position = UDim2New(0, 0, 0.927392721, 0)
	BottomBar.Size = UDim2New(0.99999994, 0, -0.00330033014, 23)

	BottomCorner.CornerRadius = UDim.new(0, 2)
	BottomCorner.Name = "BottomCorner"
	BottomCorner.Parent = BottomBar

	StopScript.Name = "StopScript"
	StopScript.Parent = BottomBar
	StopScript.BackgroundColor3 = Color3RGB(54, 54, 54)
	StopScript.BackgroundTransparency = 1.000
	StopScript.BorderColor3 =  PureBlack
	StopScript.BorderSizePixel = 0
	StopScript.Position = UDim2New(1.36239194e-07, 0, 0, 0)
	StopScript.Size = UDim2New(0, 84, 0, 21)
	StopScript.Font = Gotham
	StopScript.Text = "Stop Script"
	StopScript.TextColor3 = Color3RGB(204, 201, 201)
	StopScript.TextSize = 12.000

	SeperatorBottom.Name = "SeperatorBottom"
	SeperatorBottom.Parent = BottomBar
	SeperatorBottom.BackgroundColor3 = Color3RGB(54, 54, 54)
	SeperatorBottom.BackgroundTransparency = 1.000
	SeperatorBottom.BorderColor3 =  PureBlack
	SeperatorBottom.BorderSizePixel = 0
	SeperatorBottom.Position = UDim2New(0.187500149, 0, 0, 0)
	SeperatorBottom.Size = UDim2New(0, 0, 0, 21)
	SeperatorBottom.Font = Gotham
	SeperatorBottom.Text = "|"
	SeperatorBottom.TextColor3 = Color3RGB(204, 201, 201)
	SeperatorBottom.TextSize = 12.000

	AnimIdPlayer.Name = "AnimIdPlayer"
	AnimIdPlayer.Parent = BottomBar
	AnimIdPlayer.BackgroundColor3 =  PureBlack
	AnimIdPlayer.BackgroundTransparency = 1.000
	AnimIdPlayer.BorderColor3 =  PureBlack
	AnimIdPlayer.BorderSizePixel = 0
	AnimIdPlayer.Position = UDim2New(0.207588896, 0, 0, 0)
	AnimIdPlayer.Size = UDim2New(0, 267, 0, 21)
	AnimIdPlayer.Font = Gotham
	AnimIdPlayer.PlaceholderText = "-- \\\\ Animation ID Player (R6) | Enter to play."
	AnimIdPlayer.Text = ""
	AnimIdPlayer.TextColor3 = Color3RGB(211, 211, 211)
	AnimIdPlayer.TextSize = 12.000
	AnimIdPlayer.TextXAlignment = AlignTextL

	silly_car.Name = "silly_car"
	silly_car.Parent = BottomBar
	silly_car.BackgroundColor3 =PureWhite
	silly_car.BackgroundTransparency = 1.000
	silly_car.BorderColor3 =  PureBlack
	silly_car.BorderSizePixel = 0
	silly_car.Position = UDim2New(0.950000167, 0, 0, 0)
	silly_car.Size = UDim2New(0, 22, 0, 21)
	silly_car.Font = Gotham
	silly_car.Text = ":3"
	silly_car.TextColor3 = Color3RGB(234, 234, 234)
	silly_car.TextSize = 12.000
	silly_car.TextTransparency = 0.500
	silly_car.TextWrapped = true
	
	local function Drag(Frame)
		local StateEnd = Enum.UserInputState.End
		local MouseMovement = Enum.UserInputType.MouseMovement
		local StateMouseBTN1 = Enum.UserInputType.MouseButton1
		local StateTouch = Enum.UserInputType.Touch
		local dragToggle = nil
		local dragInput = nil
		local dragStart = nil

		local Delta, Position, startPos;

		local function updateInput(input)
			Delta = input.Position - dragStart
			Position = UDim2New(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
			Frame.Position = Position
		end

		Frame.InputBegan:Connect(function(input)
			if (input.UserInputType == StateMouseBTN1 or input.UserInputType == StateTouch) then
				dragToggle = true
				dragStart = input.Position
				startPos = Frame.Position

				input.Changed:Connect(function()
					if (input.UserInputState == StateEnd) then
						dragToggle = false
					end
				end)
			end
		end)

		Frame.InputChanged:Connect(function(input)
			if (input.UserInputType == MouseMovement or input.UserInputType == StateTouch) then
				dragInput = input
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if (input == dragInput and dragToggle) then
				updateInput(input)
			end
		end)
	end

	Drag(GelatekHub)
	
	return {AddScript, AnimIdPlayer, Reanimate, SettingButtons, StopScript}
end
