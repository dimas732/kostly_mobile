import assert from 'node:assert/strict';
import test from 'node:test';
import {once} from 'node:events';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {deleteApp, getApp} from 'firebase-admin/app';

test('legacy catalogue, retired sender and existing webhook decisions', async t => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(localhost|127\.0\.0\.1):\d+$/);
  Object.assign(process.env, {GCLOUD_PROJECT:'demo-kostly', 
    BOT_TOKEN:'local-test', ADMIN_CHAT_ID:'10', ADMIN_UIDS:'{"20":"admin"}', WEBHOOK_SECRET:'local-secret', PORT:'0'});
  const messages = [];

  const realFetch = globalThis.fetch;
  t.mock.method(globalThis,'fetch', (url, options) => {
    if (String(url).startsWith('https://api.telegram.org/')) {
      if (url.endsWith('/sendMessage')) {

        messages.push(JSON.parse(options.body));
      }
      return Promise.resolve(Response.json({ok:true}));
    }
    return realFetch(url,options);
  });
  const {server} = await import('./server.js');
  if (!server.listening) await once(server,'listening');
  const db = getFirestore();
  t.after(async () => {
    await new Promise(resolve => server.close(resolve));
    await deleteApp(getApp());
  });
  const base = 'http://127.0.0.1:' + server.address().port;
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  assert.match(authHost ?? '', /^(localhost|127\.0\.0\.1):\d+$/);
  const registration = await fetch('http://' + authHost + '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=test', {
    method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({returnSecureToken:true})
  });
  assert.equal(registration.status,200);
  const {idToken:token,localId:uid} = await registration.json();
  async function post(path,body, extra={Authorization:'Bearer '+token}) {
    return fetch(base+'/'+path,{method:'POST',headers:{...extra,'Content-Type':'application/json'},body:JSON.stringify(body)});
  }
  const profile = db.collection('users').doc(uid);
  const account = {name:'Pemilik',roles:'owner',verificationStatus:'verified'};
  await profile.set(account);
  const doc = db.collection('kos').doc();
  const time = Timestamp.now();
  await doc.set({user_id:uid,name:'Properti uji',verification_status:'pending',verification_submitted_at:time});
  const legacy = await db.collection('kos').add({user_id:uid});
  const catalogue = await post('legacy',{});
  assert.equal(catalogue.status,200);
  const ids = (await catalogue.json()).ids;
  assert.ok(ids.includes(legacy.id));
  assert.ok(!ids.includes(doc.id));
  const notify = () => post('notify',{id:doc.id});
  assert.equal((await notify()).status,410);
  assert.equal(messages.length,0);
  const key = 'x-telegram-bot-api-secret-token';
  async function choose(data, from=20, secret='local-secret') {
    return post('webhook',{callback_query:{id:'test',from:{id:from},message:{chat:{id:10}},data}},{[key]:secret});
  }
  const {submissionKey} = await import('./workflow.js');
  const button = (action, time) => 'property:' + action + ':' + doc.id + ':' + submissionKey(time);
  const approve = button('approve',time), reject = button('reject',time);
  assert.equal((await choose(approve,20,'wrong')).status,403);
  await choose(approve,21);
  assert.equal((await doc.get()).get('verification_status'),'pending');
  await choose(reject);
  assert.equal((await doc.get()).get('verification_status'),'rejected');
  assert.equal((await doc.get()).get('verified_at'),null);
  const nextTime = Timestamp.now();
  await doc.update({verification_status:'pending',verification_submitted_at:nextTime});
  await choose(approve);
  assert.equal((await doc.get()).get('verification_status'),'pending');
  await choose(button('approve',nextTime));
  await choose(reject);
  const result = (await doc.get()).data();
  assert.equal(result.verification_status,'verified');
  assert.ok(result.verified_at instanceof Timestamp);
  assert.equal(result.rejection_reason,'');
  assert.deepEqual((await profile.get()).data(),account);
});
