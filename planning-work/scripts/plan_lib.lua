-- Shared line classifier and file helpers for the planning-work scripts.
-- A PLAN.md is a closed set of line kinds; everything a checkbox plan may not
-- contain (prose, wrapped continuations, plain bullets, quotes, fences) is a
-- distinct kind so lint, unwrap and retire agree on one grammar.
local M = {}

function M.read_lines(path)
	local f, err = io.open(path, "rb")
	if not f then return nil, err end
	local text = f:read("*a")
	f:close()
	local lines = {}
	for line in (text:gsub("\r\n", "\n")):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
	local tail = text:match("([^\n]+)$")
	if tail then lines[#lines + 1] = tail end
	return lines, text
end

function M.write_lines(path, lines)
	local tmp = path .. ".plan-tmp"
	local f = assert(io.open(tmp, "wb"))
	f:write(table.concat(lines, "\n"), #lines > 0 and "\n" or "")
	f:close()
	assert(os.rename(tmp, path))
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

return M
