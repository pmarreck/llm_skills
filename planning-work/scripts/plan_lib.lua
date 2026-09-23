-- Shared line classifier, item tree and safe file writes for the
-- planning-work scripts. A PLAN.md is a closed set of line kinds; everything
-- a checkbox plan may not contain (prose, wrapped continuations, plain
-- bullets, quotes, fences) is a distinct kind so lint, unwrap and retire agree
-- on one grammar, and one item tree decides what retire may move and what
-- lint counts.
local ffi = require("ffi")
ffi.cdef [[
int mkstemp(char *template);
long write(int fd, const void *buf, unsigned long count);
int fsync(int fd);
int close(int fd);
int unlink(const char *path);
char *realpath(const char *path, char *resolved);
void free(void *ptr);
char *strerror(int errnum);
]]

local M = {}

function M.read_lines(path)
	local f, err = io.open(path, "rb")
	if not f then return nil, err end
	local text = f:read("*a")
	f:close()
	if not text then return nil, "cannot read " .. path end
	local lines = {}
	for line in (text:gsub("\r\n", "\n")):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
	local tail = text:match("([^\n]+)$")
	if tail then lines[#lines + 1] = tail end
	return lines, text
end

local function errstr()
	return ffi.string(ffi.C.strerror(ffi.errno()))
end

-- Replace path with content atomically: a unique mkstemp file in the same
-- directory, every write and the fsync and close checked, then rename. On
-- any failure the temporary file is removed, path is untouched, and
-- (nil, message) is returned.
function M.write_file(path, content)
	local dir = path:match("^(.*)/[^/]*$") or "."
	local template = ffi.new("char[?]", #dir + 32)
	ffi.copy(template, dir .. "/.plan-tmp.XXXXXX")
	local fd = ffi.C.mkstemp(template)
	if fd < 0 then return nil, "cannot create a temporary file in " .. dir .. ": " .. errstr() end
	local tmp = ffi.string(template)
	local function abort(msg)
		ffi.C.close(fd)
		ffi.C.unlink(tmp)
		return nil, msg
	end
	local off = 0
	while off < #content do
		local n = ffi.C.write(fd, ffi.cast("const char *", content) + off, #content - off)
		if n <= 0 then return abort("cannot write " .. tmp .. ": " .. errstr()) end
		off = off + tonumber(n)
	end
	if ffi.C.fsync(fd) ~= 0 then return abort("cannot sync " .. tmp .. ": " .. errstr()) end
	if ffi.C.close(fd) ~= 0 then
		ffi.C.unlink(tmp)
		return nil, "cannot close " .. tmp .. ": " .. errstr()
	end
	local ok, err = os.rename(tmp, path)
	if not ok then
		ffi.C.unlink(tmp)
		return nil, "cannot replace " .. path .. ": " .. tostring(err)
	end
	return true
end

function M.join_lines(lines)
	return table.concat(lines, "\n") .. (#lines > 0 and "\n" or "")
end

-- Canonical absolute path, following symlinks. For a file that does not exist
-- yet, the directory is resolved and the name appended.
function M.realpath(path)
	local r = ffi.C.realpath(path, nil)
	if r ~= nil then
		local s = ffi.string(r)
		ffi.C.free(r)
		return s
	end
	local dir, name = path:match("^(.*)/([^/]*)$")
	if not dir then dir, name = ".", path end
	if dir == "" then dir = "/" end
	r = ffi.C.realpath(dir, nil)
	if r == nil then return nil end
	local s = ffi.string(r)
	ffi.C.free(r)
	return s .. "/" .. name
end

-- Visual indentation width, tabs counted as 4 columns.
function M.indent_width(line)
	local ws = line:match("^[ \t]*")
	local w = 0
	for c in ws:gmatch(".") do w = w + (c == "\t" and 4 or 1) end
	return w
end

local function list_kind(line)
	local _, box, rest = line:match("^([ \t]*)[-*+] %[([ xX])%](.*)$")
	if box and rest:match("^ +%S") then return box == " " and "open" or "done" end
	if line:match("^[ \t]*[-*+] ") or line:match("^[ \t]*[-*+]$") then return "bullet" end
	if line:match("^[ \t]*%d+[.)] ") then return "bullet" end
	return nil
end

-- Classifies every line of a plan. Returns an array of kinds:
-- heading, preamble, blank, open, done, continuation, bullet, prose, quote, fence.
function M.classify(lines)
	local kinds = {}
	local in_fence, seen_section, prev_listy = false, false, false
	for i, line in ipairs(lines) do
		local kind
		if line:match("^[ \t]*```") or line:match("^[ \t]*~~~") then
			kind, in_fence = "fence", not in_fence
		elseif in_fence then
			kind = "fence"
		elseif line:match("^%s*$") then
			kind = "blank"
		elseif line:match("^#+ ") or line:match("^#+$") then
			kind = "heading"
			if line:match("^##") then seen_section = true end
		else
			kind = list_kind(line)
			if not kind then
				-- Wrapped item text may begin with ">" (e.g. ">2% of blocks"), so an
				-- indented line after list content is a continuation, not a quote.
				if prev_listy and line:match("^[ \t]") then
					kind = "continuation"
				elseif line:match("^[ \t]*>") then
					kind = "quote"
				elseif not seen_section then
					kind = "preamble"
				else
					kind = "prose"
				end
			end
		end
		kinds[i] = kind
		if kind ~= "blank" then
			prev_listy = (kind == "open" or kind == "done" or kind == "bullet" or kind == "continuation")
		else
			prev_listy = false
		end
	end
	return kinds
end

-- Checkbox items as a tree. Each item spans its line plus every following
-- line indented deeper than it, including blank lines that sit between such
-- lines, so a subtree is never split at a blank separator.
function M.items(lines, kinds)
	local items, section, stack = {}, nil, {}
	for n, line in ipairs(lines) do
		local k = kinds[n]
		if k == "heading" then
			section = line:gsub("^#+%s*", "")
			stack = {}
		elseif k == "open" or k == "done" then
			local w = M.indent_width(line)
			while #stack > 0 and stack[#stack].indent >= w do table.remove(stack) end
			local item = { first = n, last = n, indent = w, done = (k == "done"), section = section,
				parent = stack[#stack], open_below = false }
			items[#items + 1] = item
			stack[#stack + 1] = item
		end
	end
	for _, item in ipairs(items) do
		local n, last = item.first + 1, item.first
		while n <= #lines do
			local k = kinds[n]
			if k == "heading" then break end
			if k == "blank" then
				local m = n + 1
				while m <= #lines and kinds[m] == "blank" do m = m + 1 end
				if m > #lines or kinds[m] == "heading" or M.indent_width(lines[m]) <= item.indent then break end
				n = m
			elseif M.indent_width(lines[n]) > item.indent then
				last = n
				n = n + 1
			else
				break
			end
		end
		item.last = last
		if not item.done then
			local p = item.parent
			while p do p.open_below = true; p = p.parent end
		end
	end
	return items
end

-- The items plan-retire may move, in file order: completed items with no open
-- descendant whose nearest completed-and-unblocked ancestor (if any) is not
-- itself movable (then they travel inside that ancestor). Also returns the
-- number of completed items blocked by an open descendant.
function M.retirable(items)
	local out, blocked = {}, 0
	for _, item in ipairs(items) do
		if item.done then
			if item.open_below then
				blocked = blocked + 1
			else
				local inside = false
				local p = item.parent
				while p do
					if p.done and not p.open_below then inside = true end
					p = p.parent
				end
				if not inside then out[#out + 1] = item end
			end
		end
	end
	return out, blocked
end

return M
