import assert from 'node:assert/strict';
import test from 'node:test';
import {decisionFor, parseCallback, submissionKey} from './workflow.js';

const time = {seconds: 1800000000, nanoseconds: 999999000};
const id = 'ABCDEFGHIJKLMNOPQRST';
const property = {user_id: 'owner', verification_status: 'pending', verification_submitted_at: time};
const version = submissionKey(time);
for (const [action, expected] of [['approve','verified'], ['reject','rejected']]) {
  test(action + ' applies once to the matching submission', () => {
    const data = 'property:' + action + ':' + id + ':' + version;
    assert.ok(Buffer.byteLength(data) <= 64);
    const callback = parseCallback(data);
    assert.equal(callback.id, id);
    assert.equal(decisionFor(callback, property, 'admin'), expected);
    for (const status of ['verified','rejected', undefined]) {
      assert.equal(decisionFor(callback, {...property, verification_status:status}, 'admin'), null);
    }
    assert.equal(decisionFor(callback, property, 'owner'), null);
    assert.equal(decisionFor(callback, property, ''), null);
    assert.equal(decisionFor(callback, {...property, verification_submitted_at:{...time, seconds: time.seconds+1}}, 'admin'), null);
  });
}
test('account callbacks use a separate namespace', () => {
  assert.equal(parseCallback('approve_' + id), null);
  assert.equal(parseCallback('reject_' + id), null);
});
