# A single public graph keeps imported constructor identities consistent.
import Base
import ./Model.bend as Model

def word(hi: U32, lo: U32) -> Model.Word64:
	Model.Word64{hi, lo}

def increment(value: Model.Word64) -> Model.Word64:
	Model.increment(value)

def bytes(value: U32) -> List<U32>:
	Model.word_bytes(value)

def example_sum() -> U32:
	Model.sum([1, 2, 3, 4], 0)
