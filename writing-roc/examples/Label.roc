Label :: { text : Str }.{
	new : Str -> Label
	new = |text| { text: normalize(text) }

	to_str : Label -> Str
	to_str = |label| label.text
}

normalize = |text| text.trim()

expect Label.new(" example ").to_str() == "example"
