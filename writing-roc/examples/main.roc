import Label

add : I64, I64 -> I64
add = |a, b| a + b

first_number : List(Str) -> Try(I64, _)
first_number = |strings| {
	first = strings.first()?
	number = I64.from_str(first)?
	Ok(number)
}

first_message = |strings| match first_number(strings) {
	Ok(n) => "number=${n.to_str()}"
	Err(ListWasEmpty) => "empty input"
	Err(BadNumStr) => "invalid number"
}

updated_pair = || {
	person = { name: "Ada", count: 1.I64 }
	updated = { ..person, count: 2 }
	{ name, count } = updated
	(name, count)
}

format_names : List(Str) -> Str
format_names = |names| names.map(|s| s.trim()) |> Str.join_with(", ")

total : I64 -> I64
total = |limit| {
	var $sum = 0
	for n in 1..=limit {
		$sum = $sum + n
	}
	$sum
}

tail_size : List(I64) -> U64
tail_size = |values| match values {
	[] => 0
	[_head, .. as tail] => tail.len()
}

UserId := U64

stringify : a -> Str where [a.to_str : a -> Str]
stringify = |value| value.to_str()

main! = |_args| {
	echo!(Label.new(" Roc quick reference ").to_str())
	Ok({})
}

expect add(2, 3) == 5
expect first_number(["7"]) == Ok(7)
expect first_number([]) == Err(ListWasEmpty)
expect first_number(["wrong"]) == Err(BadNumStr)
expect first_message(["7"]) == "number=7"
expect first_message([]) == "empty input"
expect first_message(["wrong"]) == "invalid number"
expect updated_pair() == ("Ada", 2)
expect format_names([" Ada ", "Grace "]) == "Ada, Grace"
expect total(10) == 55
expect tail_size([]) == 0
expect tail_size([1, 2, 3]) == 2
expect {
	user = UserId.(42)
	UserId.(value) = user
	value == 42
}
expect stringify(42.I64) == "42"
expect Label.new(" example ").to_str() == "example"
