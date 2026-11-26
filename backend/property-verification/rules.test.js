import assert from 'node:assert/strict';
import test from 'node:test';

const host = process.env.FIRESTORE_EMULATOR_HOST;
const project = 'demo-kostly';
const base = 'http://' + host + '/v1/projects/' + project + '/databases/(default)/documents';

function identity(uid) {
  const json = obj => Buffer.from(JSON.stringify(obj)).toString('base64url');
  return json({alg:'none',typ:'JWT'}) + '.' + json({sub: uid,user_id:uid, aud:project,
    iss:'https://securetoken.google.com/'+project, iat:1, exp:4102444800,
    firebase:{sign_in_provider:'password'}}) + '.';
}

test('property rules enforce ownership, publication queries and resubmission', async () => {
  assert.ok(/^127\.0\.0\.1:\d+$|^localhost:\d+$/.test(host), 'Start the local demo emulator first');
  const owner = identity('landlord');
  const seeker = identity('seeker');
  const other = identity('other');
  const text = value => ({stringValue:value});
  const request = (url, token, method='GET', payload) => fetch(url, {
    method, headers:{Authorization:'Bearer '+token, 'Content-Type':'application/json'},
    ...(payload && {body:JSON.stringify(payload)})
  });
  async function expectHttp(response, expected) {
    const res = await response;
    assert.equal(res.status, expected, await res.text());
  }
  for (const [uid,role] of [['landlord','owner'],['seeker','seeker'],['other','owner']]) {
    await expectHttp(request(base+'/users/'+uid, 'owner','PATCH',{fields:{roles:text(role)}}),200);
  }
  const fullName = id => 'projects/'+project+'/databases/(default)/documents/kos/'+id;
  function submit(id, token, uid, status, create) {
    const fields = {user_id:text(uid), verification_status:text(status), verified_at:{nullValue:null}, rejection_reason:text('')};
    const times = ['verification_submitted_at','verification_updated_at'];
    if(create) times.push('created_at');
    const write = {update:{name:fullName(id),fields}, currentDocument:{exists:!create},
      updateTransforms:times.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))};
    if(!create) write.updateMask = {fieldPaths:Object.keys(fields)};
    return request(base+':commit', token,'POST',{writes:[write]});
  }
  const id = 'test' + Date.now();
  const patch = (token, field, value) => request(base+'/kos/'+id+'?updateMask.fieldPaths='+field,token,'PATCH',{fields:{[field]:text(value)}});
  await expectHttp(submit(id, seeker, 'seeker','pending',true),403);
  await expectHttp(submit(id, owner, 'other','pending',true),403);
  await expectHttp(submit(id, owner, 'landlord','verified',true),403);
  await expectHttp(submit(id, owner, 'landlord','pending',true),200);
  await expectHttp(request(base+'/kos/'+id,seeker),403);
  await expectHttp(request(base+'/kos/'+id,owner),200);
  await expectHttp(patch(other,'telegram_delivery_status','queued'),403);
  await expectHttp(patch(owner,'telegram_delivery_status','sent'),403);
  await expectHttp(patch(owner,'telegram_delivery_status','queued'),200);
  await expectHttp(patch('owner','telegram_delivery_status','sending'),200);
  await expectHttp(patch(owner,'telegram_delivery_status','queued'),403);
  await expectHttp(patch('owner','telegram_delivery_status','failed'),200);
  await expectHttp(patch(owner,'telegram_delivery_status','queued'),200);
  await expectHttp(patch(owner,'user_id','other'),403);
  await expectHttp(patch(owner,'verification_status','verified'),403);
  await expectHttp(patch(owner,'verification_status','rejected'),403);
  await expectHttp(patch(other,'name','changed'),403);
  await expectHttp(patch(owner,'name','Kos'),200);
  await expectHttp(submit(id,owner,'landlord','pending',false),403);
  await expectHttp(patch('owner','verification_status','rejected'),200);
  await expectHttp(request(base+'/kos/'+id,seeker),403);
  await expectHttp(submit(id,owner,'landlord','pending',false),200);
  await expectHttp(patch('owner','verification_status','verified'),200);
  await expectHttp(request(base+'/kos/'+id,seeker),200);
  await expectHttp(submit(id,owner,'landlord','pending',false),403);
  await expectHttp(request(base+'/kos/legacy','owner','PATCH',{fields:{user_id:text('landlord')}}),200);
  await expectHttp(request(base+'/kos/legacy',seeker),200);
  function list(token,field,value) {
    return request(base+':runQuery',token,'POST',{structuredQuery:{from:[{collectionId:'kos'}],
      ...(field && {where:{fieldFilter:{field:{fieldPath:field},op:'EQUAL',value:text(value)}}})}});
  }
  await expectHttp(list(seeker),403);
  await expectHttp(list(owner,'user_id','landlord'),200);
  await expectHttp(list(seeker,'verification_status','verified'),200);
});
