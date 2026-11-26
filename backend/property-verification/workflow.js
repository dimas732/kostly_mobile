export function submissionKey(time) {
  return time.seconds.toString(36) + '.' + time.nanoseconds.toString(36);
}

export function decisionFor(callback, property, adminUid) {
  if (!property || !adminUid || property.user_id === adminUid ||
      property.verification_status !== 'pending' || !property.verification_submitted_at ||
      submissionKey(property.verification_submitted_at) !== callback.version) return null;
  return callback.action === 'approve' ? 'verified' : callback.action === 'reject' ? 'rejected' : null;
}

export function parseCallback(data) {
  const match = /^property:(approve|reject):([A-Za-z0-9]{20}):([a-z0-9]+\.[a-z0-9]+)$/.exec(data);
  return match && {action: match[1], id: match[2], version: match[3]};
}
