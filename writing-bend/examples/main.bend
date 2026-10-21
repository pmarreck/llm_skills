# The I/O edge prints the result of the same pure model the SDK uses.
import Base
import ./Model.bend as Model

def show_result(value: Model.Word64, total: U32) -> IO(Unit):
	match value:
		case Model.Word64{hi, lo}:
			IO.print(U32.show(hi) ++ ":" ++ U32.show(lo) ++ ":" ++ U32.show(total))

def main() -> IO(Unit):
	show_result(Model.increment(Model.Word64{7, 4294967295}), Model.sum([1, 2, 3, 4], 0))
