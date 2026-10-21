# Scope: length, one carry endpoint, and the empty-fold identity only.
import Base
import ./Model.bend as Model

law word_size:
	for word: U32
	{List.length(&1, U32, Model.word_bytes(word)) == 4n : Nat}

law carry_boundary:
	{Model.increment(Model.Word64{7, 4294967295}) == Model.Word64{8, 0} : Model.Word64}

law empty_fold:
	for acc: U32
	{Model.sum(Nil{}, acc) == acc : U32}
