// Independent host oracle for the compiled coherent example graph.
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';

const api = (await import(pathToFileURL(process.argv[2]))).default;
const first = api.word(7, 0xffffffff);
const next = api.increment(first);
assert.deepEqual([next.hi, next.lo], [8, 0]);

const wrapped = api.increment(api.word(0xffffffff, 0xffffffff));
assert.deepEqual([wrapped.hi, wrapped.lo], [0, 0]);

let list = api.bytes(0x11223344);
const bytes = [];
while (list.$ === 'Con') {
	bytes.push(list.head);
	assert.ok(bytes.length <= 4, 'encoder exceeded the four-byte contract');
	list = list.tail;
}
assert.equal(list.$, 'Nil');
assert.deepEqual(bytes, [0x44, 0x33, 0x22, 0x11]);
assert.equal(api.example_sum(), 10);
console.log('Bend skill: independent JS codec/carry/wrap/fold checks passed');
