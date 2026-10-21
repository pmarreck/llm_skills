# Pure codec and limb operations; no I/O or foreign arithmetic.
import Base

type Word64 is Data:
	Word64{hi: U32, lo: U32}

def increment_finish(hi: U32, lo: U32) -> Word64:
	match lo:
		case 0:
			Word64{(hi + 1 : U32), 0}
		case low:
			Word64{hi, low}

def increment(value: Word64) -> Word64:
	match value:
		case Word64{hi, lo}:
			increment_finish(hi, (lo + 1 : U32))

def word_bytes(+word: U32) -> List<U32>:
	[U32.and(word, 255), U32.and(U32.shrn(word, 8n), 255),
		U32.and(U32.shrn(word, 16n), 255), U32.shrn(word, 24n)]

def sum(xs: List<U32>, acc: U32) -> U32:
	match xs:
		case Nil{}:
			acc
		case Con{head, tail}:
			sum(tail, (acc + head : U32))
