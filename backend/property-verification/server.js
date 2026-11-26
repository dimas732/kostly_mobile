import {createServer} from 'node:http';
import {timingSafeEqual} from 'node:crypto';
import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore, FieldPath, FieldValue} from 'firebase-admin/firestore';
import {decisionFor, parseCallback} from './workflow.js';

initializeApp();
const db = getFirestore();
const {BOT_TOKEN, ADMIN_CHAT_ID, WEBHOOK_SECRET, ADMIN_UIDS} = process.env;
if (!BOT_TOKEN || !ADMIN_CHAT_ID || !WEBHOOK_SECRET || !ADMIN_UIDS) throw Error('Missing property bot configuration');
const admins = new Map(Object.entries(JSON.parse(ADMIN_UIDS)));
const stamp = FieldValue.serverTimestamp;
const failure = status => Object.assign(new Error('Request failed'), {status});

async function telegram(method, payload) {
  const res = await fetch('https://api.telegram.org/bot' + BOT_TOKEN + '/' + method, {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload), signal: AbortSignal.timeout(15000),
  });
  if (!res.ok || !(await res.json()).ok) throw failure(502);
}

async function webhook(update) {
  const q = update.callback_query;
  if (!q) return;
  const adminUid = admins.get(String(q.from?.id));
  const callback = parseCallback(q.data);
  let message = 'Tindakan tidak tersedia.';
  if (callback && adminUid && String(q.message?.chat?.id) === ADMIN_CHAT_ID) {
    const ref = db.collection('kos').doc(callback.id);
    const result = await db.runTransaction(async tx => {
      const status = decisionFor(callback, (await tx.get(ref)).data(), adminUid);
      if (status) tx.update(ref, {
        verification_status: status, verification_updated_at: stamp(),
        verified_at: status === 'verified' ? stamp() : null, rejection_reason: '',
      });
      return status;
    });
    message = result === 'verified' ? 'Kos disetujui.' : result === 'rejected' ? 'Kos ditolak.' : 'Pengajuan sudah berubah atau tidak dapat diproses.';
  }
  // Expired callback acknowledgements must not replay a completed decision.
  await telegram('answerCallbackQuery', {callback_query_id: q.id, text: message}).catch(() => {});
}

async function legacy(cursor) {
  if (cursor != null && (typeof cursor !== 'string' || !cursor || cursor.includes('/'))) throw failure(400);
  let query = db.collection('kos').select('verification_status').orderBy(FieldPath.documentId()).limit(200);
  if (cursor) query = query.startAfter(cursor);
  const page = await query.get();
  return {ids: page.docs.filter(doc => !Object.hasOwn(doc.data(), 'verification_status')).map(doc => doc.id),
    next: page.size === 200 ? page.docs.at(-1).id : null};
}

export const server = createServer(async (req, res) => {
  try {
    if (req.method !== 'POST') throw failure(405);
    let uid;
    if (req.url === '/webhook') {
      const header = Buffer.from(String(req.headers['x-telegram-bot-api-secret-token'] ?? ''));
      const secret = Buffer.from(WEBHOOK_SECRET);
      if (header.length !== secret.length || !timingSafeEqual(header, secret)) throw failure(403);
    } else {
      if (req.url === '/notify') throw failure(410);
      if (req.url !== '/legacy') throw failure(404);
      const token = /^Bearer (\S+)$/.exec(req.headers.authorization ?? '')?.[1];
      if (!token) throw failure(401);
      uid = (await getAuth().verifyIdToken(token).catch(() => {throw failure(401);})).uid;
    }
    const chunks = [];
    let size = 0;
    for await (const chunk of req) {
      size += chunk.length;
      if (size > 32768) throw failure(413);
      chunks.push(chunk);
    }
    const body = JSON.parse(Buffer.concat(chunks).toString());
    let result = {};
    if (req.url === '/webhook') await webhook(body);
    else result = await legacy(body.cursor);
    res.writeHead(200, {'Content-Type':'application/json'}).end(JSON.stringify(result));
  } catch (error) {
    res.writeHead(error.status ?? (error instanceof SyntaxError ? 400 : 500)).end();
  }
}).listen(Number(process.env.PORT ?? 8080));
